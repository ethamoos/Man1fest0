//
//  ComputerGroup.swift
//  Man1fest0
//
//  Created by Amos Deane on 04/08/2024.
//

import Foundation




// MARK: - Welcome
struct allComputerGroups: Codable {
    let computerGroups: [ComputerGroup]

    enum CodingKeys: String, CodingKey {
        case computerGroups = "computer_groups"
    }
}

// MARK: - ComputerGroup
struct ComputerGroup: Codable, Hashable {
    let id: Int
    let name: String
    let isSmart: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case isSmart = "is_smart"
    }
}



// MARK: - CompGroupContainer
struct CompGroupContainer: Codable, Hashable {
    let computerGroup: ComputerGroupInstance

    enum CodingKeys: String, CodingKey {
        case computerGroup = "computer_group"
    }
}





// MARK: - ComputerGroupInstance
struct ComputerGroupInstance: Codable, Hashable, Identifiable  {
    let id: Int
    let name: String
    let isSmart: Bool
//    let site: Site
//    let criteria: Criteria
    let computers: ComputerGroupMembers

    enum CodingKeys: String, CodingKey {
        case id, name
        case isSmart = "is_smart"
        case  computers
//        case  site
//        case  criteria
    }
}

// MARK: - ComputerGroupMembers
struct ComputerGroupMembers: Codable, Hashable {
//    let size: Int
    let computer: ComputerMember
//    let computer: String
}

// MARK: - Computer
struct ComputerMember: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
//    let macAddress, altMACAddress, serialNumber: String

    enum CodingKeys: String, CodingKey {
        case id, name
//        case macAddress = "mac_address"
//        case altMACAddress = "alt_mac_address"
//        case serialNumber = "serial_number"
    }
}

// MARK: - Criteria
struct Criteria: Codable {
    let size: Int
}

// MARK: - Site
struct Site: Codable {
    let id: Int
    let name: String
}

