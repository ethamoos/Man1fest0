//
//  Building.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/08/2024.
//

import Foundation



// MARK: - Buildings
struct Buildings: Codable {
    let buildings: [Building]
}

// MARK: - Building
struct Building: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
}






//
//struct Buildings: Codable {
//    let size: String
//    let building: [Building]
//}
//
//// MARK: - Building
//struct Building: Codable {
//    let id, name: String
//}




//MARK: - BUILDING

//struct Script: JamfObject, Hashable {

//struct Buildings: Codable {
//    var size: String
//    var buildings: [Building]
//}
//
//struct Building: JamfObject, Hashable {
//    var id: String
//
//    enum CodingKeys: String, Codable, CodingKey {
//        case jamfId = "jamfId"
//        case name = "name"
//        case id = "id"
//    }
//
////    var id = UUID()
//    let jamfId: Int?
//    let name: String?
//    //static var getAllEndpoint = "/api/v1/scripts"
//    static var getAllEndpoint = "/JSSResource/buildings"
//}

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let buildings = try? JSONDecoder().decode(Buildings.self, from: jsonData)
