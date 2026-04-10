// AdvancedComputerSearchDetailed.swift
// Minimal decoding structs for a detailed advanced computer search response.

import Foundation

struct AdvancedComputerSearchDetailedResponse: Decodable {
    let advancedComputerSearch: AdvancedComputerSearchDetailed

    enum CodingKeys: String, CodingKey {
        case advancedComputerSearch = "advanced_computer_search"
    }
}

struct AdvancedComputerSearchDetailed: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    // Jamf servers may include a 'criteria' field with search definition; keep optional
    let criteria: String?

    enum CodingKeys: String, CodingKey {
        case id, name, criteria
    }
}
