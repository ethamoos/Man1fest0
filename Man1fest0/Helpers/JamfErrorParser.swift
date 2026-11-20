//
//  JamfErrorParser.swift
//  Man1fest0
//
//  Extracts a human-readable error from Jamf Classic API error responses so the
//  reason for a failed PUT/POST (e.g. HTTP 409 Conflict) can be shown to the user.
//
//  The Classic API typically returns an HTML "Status page" for errors, e.g.:
//    <p ...>Conflict</p>
//    <p ...>Error: Problem with script</p>
//    <p>You can get technical details <a href="...">here</a>...</p>
//

import Foundation

enum JamfErrorParser {

    /// Returns the most relevant error text found in a Jamf error response body.
    static func extractMessage(from body: String) -> String {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return "" }

        // Collect the text content of each <p> element (HTML status page format)
        var paragraphs: [String] = []
        if let regex = try? NSRegularExpression(pattern: "<p[^>]*>(.*?)</p>", options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let ns = trimmedBody as NSString
            for match in regex.matches(in: trimmedBody, range: NSRange(location: 0, length: ns.length)) where match.numberOfRanges > 1 {
                let text = stripTags(ns.substring(with: match.range(at: 1)))
                if text.isEmpty { continue }
                let lower = text.lowercased()
                // Skip the boilerplate footer paragraph
                if lower.contains("technical details") || lower.contains("continue your visit") { continue }
                paragraphs.append(text)
            }
        }

        // Prefer explicit "Error:" lines
        if let errLine = paragraphs.first(where: { $0.lowercased().hasPrefix("error") }) {
            return errLine
        }
        if !paragraphs.isEmpty {
            return paragraphs.joined(separator: " – ")
        }

        // Fallback: strip all tags and truncate
        let plain = stripTags(trimmedBody)
        return plain.count > 300 ? String(plain.prefix(300)) + "…" : plain
    }

    /// Adds a hint for common Classic API conflict messages.
    static func hint(for message: String) -> String? {
        let lower = message.lowercased()
        if lower.contains("problem with script") {
            return "The policy's script list was rejected. Check for duplicate scripts in the policy, or script names that do not exactly match the server (including leading/trailing spaces)."
        }
        if lower.contains("problem with package") {
            return "The policy's package list was rejected. Check for duplicate packages or package names that do not exactly match the server."
        }
        if lower.contains("duplicate name") || lower.contains("name already") {
            return "An object with this name already exists on the server."
        }
        if lower.contains("unable to match") {
            return "An item referenced in the request (e.g. computer, group or category) could not be matched on the server. Check names and IDs."
        }
        if lower.contains("problem with category") {
            return "The category could not be matched on the server."
        }
        return nil
    }

    /// Builds a full user-facing description for a failed request.
    static func describe(statusCode: Int, body: String, context: String? = nil) -> String {
        let reason = HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
        var parts: [String] = []
        if let context = context, !context.isEmpty {
            parts.append("\(context) failed (HTTP \(statusCode) \(reason)).")
        } else {
            parts.append("Request failed (HTTP \(statusCode) \(reason)).")
        }
        let message = extractMessage(from: body)
        if !message.isEmpty {
            parts.append("Server response: \(message)")
            if let hint = hint(for: message) {
                parts.append(hint)
            }
        }
        return parts.joined(separator: "\n\n")
    }

    private static func stripTags(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        out = out.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension NetBrain {
    /// Shows a failed Jamf request to the user via the global alert and the message bar.
    func presentServerError(statusCode: Int, body: String, context: String) {
        let description = JamfErrorParser.describe(statusCode: statusCode, body: body, context: context)
        print("presentServerError: \(description)")
        self.alertTitle = "\(context) failed"
        self.alertMessage = description
        self.showAlert = true
        let short = JamfErrorParser.extractMessage(from: body)
        self.messageStore?.error("\(context) failed (HTTP \(statusCode))" + (short.isEmpty ? "" : ": \(short)"), details: description)
    }
}
