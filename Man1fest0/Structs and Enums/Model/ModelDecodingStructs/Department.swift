//
//  Department.swift
//  Man1fest0
//
//  Created by Amos Deane on 17/07/2024.
//

import Foundation
// MARK: - DEPARTMENT

struct Department: Codable, Hashable, Identifiable {
    var id = UUID()
    let jamfId: Int?
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
    }
}
