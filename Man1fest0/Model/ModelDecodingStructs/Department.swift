//
//  Department.swift
//  Man1fest0
//
//  Created by Amos Deane on 17/07/2024.
//

import Foundation
// MARK: - DEPARTMENT

struct Department: Codable, Hashable, Identifiable {
    // Keep a transient UUID for compatibility but provide a stable id for Identifiable
    // We'll implement custom Equatable/Hashable so Picker comparisons use stable fields.
    private var _uuid = UUID()
    var id: String { // stable identifier for SwiftUI (use jamfId if present, else name)
        if let j = jamfId { return String(j) }
        return name
    }
    let jamfId: Int?
    let name: String
    

    // Provide an explicit memberwise initializer so callers that construct
    // a Department with `Department(jamfId:name:)` will compile even when
    // there are other types named `Department` in the project scope.
    init(jamfId: Int? = nil, name: String) {
        self.jamfId = jamfId
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
    }
}

extension Department {
    static func == (lhs: Department, rhs: Department) -> Bool {
        return lhs.jamfId == rhs.jamfId && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(jamfId ?? -1)
        hasher.combine(name)
    }
}
