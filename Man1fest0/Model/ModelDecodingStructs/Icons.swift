//
//  Icons.swift
//  Man1fest0
//
//  Created by Amos Deane on 05/09/2024.
//

import Foundation


//
// MARK: - Icon

struct Icon: Codable, Hashable, Identifiable {
    let id: Int
    let url: String
    let name: String
    
    enum CodingKeys:String, CodingKey{
        case id = "id"
        case url = "url"
        case name = "name"
    }
}

