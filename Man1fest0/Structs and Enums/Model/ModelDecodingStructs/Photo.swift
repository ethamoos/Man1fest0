//
//  Photo.swift
//  Man1fest0
//
//  Created by Amos Deane on 03/09/2025.
//

struct Photo: Identifiable, Decodable {
    let id: Int
    let title: String
    let imageUrl: String
    var isSelected: Bool = false
}
