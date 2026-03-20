import Foundation

// Extension providing URL translation helpers for NetBrain
extension NetBrain {
    /// Translate Jamf API-style URLs into Jamf Pro web UI URLs.
    /// Examples:
    /// - https://server/JSSResource//computers/id/18562 -> https://server/computers.html?id=18562&o=r
    /// - https://server/JSSResource/policies/1111 -> https://server/policies.html?id=1111&o=r
    /// - https://server/api/v1/scripts/123 -> https://server/scripts.html?id=123&o=r
    func translateJamfAPIURL(_ urlString: String) -> String? {
        var candidate = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if candidate.isEmpty { return nil }

        // Ensure scheme
        if URL(string: candidate)?.scheme == nil {
            candidate = "https://" + candidate
        }

        guard let url = URL(string: candidate) else { return nil }

        // Normalize path components (remove empty segments caused by double slashes)
        let rawComponents = url.pathComponents
        let components = rawComponents.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }.filter { !$0.isEmpty }
        guard !components.isEmpty else { return nil }

        var resource: String? = nil
        var idValue: String? = nil

        // Case A: /JSSResource/{resource}/id/{id} or /JSSResource/{resource}/{id}
        if components.count >= 2 && components[0].lowercased() == "jssresource" {
            resource = components[1]
            if let idIndex = components.firstIndex(where: { $0.lowercased() == "id" }), components.indices.contains(idIndex + 1) {
                idValue = components[idIndex + 1]
            } else if components.count >= 3 {
                let possible = components[2]
                if Int(possible) != nil { idValue = possible }
            }
        }
        // Case B: /api/v1/{resource}/{id}
        else if components.count >= 3 && components[0].lowercased() == "api" && components[1].lowercased().hasPrefix("v") {
            resource = components[2]
            if components.count >= 4 { idValue = components[3] }
        }
        // Case C: /Resources/{resource}/id/{id}
        else if components.count >= 2 && components[0].lowercased() == "resources" {
            resource = components[1]
            if let idIndex = components.firstIndex(where: { $0.lowercased() == "id" }), components.indices.contains(idIndex + 1) {
                idValue = components[idIndex + 1]
            } else if components.count >= 3 {
                let possible = components[2]
                if Int(possible) != nil { idValue = possible }
            }
        }

        guard let resourceUnwrapped = resource, let idUnwrapped = idValue else { return nil }

        // Build new URL components preserving scheme/host/port and optional auth
        var newComponents = URLComponents()
        newComponents.scheme = url.scheme
        newComponents.host = url.host
        newComponents.port = url.port
        if let user = url.user, !user.isEmpty { newComponents.user = user }
        if let password = url.password, !password.isEmpty { newComponents.password = password }

        newComponents.path = "/\(resourceUnwrapped).html"
        newComponents.queryItems = [
            URLQueryItem(name: "id", value: idUnwrapped),
            URLQueryItem(name: "o", value: "r")
        ]

        return newComponents.url?.absoluteString
    }
}
