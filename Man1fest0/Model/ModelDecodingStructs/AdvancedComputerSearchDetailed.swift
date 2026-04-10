// AdvancedComputerSearchDetailed.swift
// Minimal decoding structs for a detailed advanced computer search response.

import Foundation

struct AdvancedComputerSearchDetailedResponse: Decodable {
    let advancedComputerSearch: AdvancedComputerSearchDetailed

    enum CodingKeys: String, CodingKey {
        case advancedComputerSearch = "advanced_computer_search"
    }
}

// Lightweight JSON value enum to tolerate varying server shapes for `criteria`.
private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let s = try? container.decode(String.self) {
            self = .string(s)
            return
        }
        if let n = try? container.decode(Double.self) {
            self = .number(n)
            return
        }
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
            return
        }
        if let arr = try? container.decode([JSONValue].self) {
            self = .array(arr)
            return
        }
        if let obj = try? container.decode([String: JSONValue].self) {
            self = .object(obj)
            return
        }
        throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value"))
    }

    // Convert into a human-readable string representation
    func toReadableString(indent: Int = 0) -> String {
        switch self {
        case .string(let s):
            return s
        case .number(let n):
            // show as integer if whole
            if floor(n) == n { return String(format: "%.0f", n) }
            return String(n)
        case .bool(let b):
            return String(b)
        case .null:
            return "null"
        case .array(let arr):
            // flatten array elements, join with newlines
            return arr.map { $0.toReadableString(indent: indent) }.joined(separator: "\n")
        case .object(let dict):
            // Produce a stable, key-sorted key: value listing for objects
            let keys = dict.keys.sorted()
            return keys.map { key in
                let val = dict[key]!
                return "\(key): \(val.toReadableString(indent: indent + 2))"
            }.joined(separator: "\n")
        }
    }
}

struct AdvancedComputerSearchDetailed: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    // Jamf servers may include a 'criteria' field with search definition; keep optional.
    // We decode flexibly and expose a single String for UI.
    let criteria: String?

    enum CodingKeys: String, CodingKey {
        case id, name, criteria
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        // Flexible decode for criteria -> can be a String, an Array, or an Object.
        if let raw = try? container.decode(JSONValue.self, forKey: .criteria) {
            // Convert to readable string
            let s = raw.toReadableString()
            // Trim excessive whitespace/newlines
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            self.criteria = trimmed.isEmpty ? nil : trimmed
        } else {
            self.criteria = nil
        }
    }
}
