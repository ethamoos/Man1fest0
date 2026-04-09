 //
//  AdvancedComputerSearch.swift
//  Man1fest0
//
//  Created by Copilot on 09/04/2026.
//

import Foundation

// Matches the API response for advanced computer searches.
// Example XML structure shown in the project:
// <advanced_computer_searches>
//   <size>18</size>
//   <advanced_computer_search>
//     <id>554</id>
//     <name>Macbook Migration</name>
//   </advanced_computer_search>
//   ...
// </advanced_computer_searches>

struct ComputerSearches: Codable {
    let advancedComputerSearches: AdvancedComputerSearchesContainer

    enum CodingKeys: String, CodingKey {
        case advancedComputerSearches = "advanced_computer_searches"
    }
}

struct AdvancedComputerSearchesContainer: Codable {
    let size: Int?
    let advancedComputerSearch: [AdvancedComputerSearch]

    enum CodingKeys: String, CodingKey {
        case size
        case advancedComputerSearch = "advanced_computer_search"
    }
}

struct AdvancedComputerSearch: Codable, Identifiable, Hashable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}
