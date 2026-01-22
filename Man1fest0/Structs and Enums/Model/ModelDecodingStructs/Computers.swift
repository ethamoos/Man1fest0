//
//  Computers.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/08/2024.
//

import Foundation


// MARK: - ComputerGroups



struct Computer: Codable, Identifiable, Hashable {
    var id: Int
    var name: String
        var jamfId: Int?
//    var serial_number: String?
}


// MARK: - ComputerBasic
struct ComputerBasic: Codable {
    let computers: [ComputerBasicRecord]
}

// MARK: - Computer
struct ComputerBasicRecord: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let managed: Bool
    let username, model, department, building: String
    let macAddress, udid, serialNumber, reportDateUTC: String
    let reportDateEpoch: Int

    enum CodingKeys: String, CodingKey {
        case id, name, managed, username, model, department, building
        case macAddress = "mac_address"
        case udid
        case serialNumber = "serial_number"
        case reportDateUTC = "report_date_utc"
        case reportDateEpoch = "report_date_epoch"
    }
}

//struct Computer: Codable, Hashable, Identifiable {
//    var id = UUID()
//    var jamfId: Int?
//    var name: String
//    var udid: String
////    let computer: ComputerDetailed?
//
//
//    enum CodingKeys: String, CodingKey {
//        case jamfId = "id"
//        case name = "name"
//        case udid = "udid"
////        case computer = "computer"
//    }
//}





//struct ComputerDetailed: Codable {
//    var computer: Computer
//}

struct ComputerGroups: Codable, Hashable, Identifiable {
    var id = UUID()
    let jamfId: Int?
    var name: String?
    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
    }
}

//          ################################################################################
//          MARK: - COMPUTERS
struct Computers: Codable {
    struct ComputerResponse: Codable, Identifiable, Hashable {
        var id = UUID()
        var jamfId: Int
        var name: String?
        var username: String?
        var realname: String?
        var serial_number: String
        var mac_address: String
        var alt_mac_address: String?
        var asset_tag: String?
        var ip_address: String?
        var last_reported_ip: String?
//        var location: Location?
        
        enum CodingKeys:String, CodingKey{
            case jamfId = "id"
            case name = "name"
            case username = "username"
            case realname = "realname"
            case serial_number = "serial_number"
            case mac_address = "mac_address"
            case alt_mac_address = "alt_mac_address"
            case asset_tag = "asset_tag"
            case ip_address = "ip_address"
            case last_reported_ip = "last_reported_ip"
//            case location = "location"
        }
    }
    var computersBasic: [ComputerResponse]
}








