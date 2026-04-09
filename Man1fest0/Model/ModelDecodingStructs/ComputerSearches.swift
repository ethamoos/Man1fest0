//
//  ComputerSearches.swift
//  Man1fest0
//
//  Created by Amos Deane on 09/04/2026.
//


import Foundation

// MARK: - ComputerSearches
struct ComputerSearches: Codable {
    let advancedComputerSearches: AdvancedComputerSearches
    
    enum CodingKeys: String, CodingKey {
        case advancedComputerSearches = "advanced_computer_searches"
    }
}

// MARK: - AdvancedComputerSearches
struct AdvancedComputerSearches: Codable, Hashable {
    let size: String
    let advancedComputerSearch: [AdvancedComputerSearch]
    
    enum CodingKeys: String, CodingKey {
        case size
        case advancedComputerSearch = "advanced_computer_search"
    }
}

// MARK: - AdvancedComputerSearch
struct AdvancedComputerSearch: Codable, Hashable, Identifiable {
    let id: String
    let name: String
}
