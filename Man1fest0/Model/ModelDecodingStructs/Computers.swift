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
    let lastEnrolledDate: String?  // Optional field for API flexibility

    enum CodingKeys: String, CodingKey {
        case id, name, managed, username, model, department, building
        case macAddress = "mac_address"
        case udid
        case serialNumber = "serial_number"
        case reportDateUTC = "report_date_utc"
        case reportDateEpoch = "report_date_epoch"
        case lastEnrolledDate = "last_enrolled_date"
    }
    
    init(id: Int, name: String, managed: Bool, username: String, model: String,
         department: String, building: String, macAddress: String, udid: String,
         serialNumber: String, reportDateUTC: String, reportDateEpoch: Int, lastEnrolledDate: String? = nil) {
        self.id = id
        self.name = name
        self.managed = managed
        self.username = username
        self.model = model
        self.department = department
        self.building = building
        self.macAddress = macAddress
        self.udid = udid
        self.serialNumber = serialNumber
        self.reportDateUTC = reportDateUTC
        self.reportDateEpoch = reportDateEpoch
        self.lastEnrolledDate = lastEnrolledDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        managed = try container.decode(Bool.self, forKey: .managed)
        username = try container.decode(String.self, forKey: .username)
        model = try container.decode(String.self, forKey: .model)
        department = try container.decode(String.self, forKey: .department)
        building = try container.decode(String.self, forKey: .building)
        macAddress = try container.decode(String.self, forKey: .macAddress)
        udid = try container.decode(String.self, forKey: .udid)
        serialNumber = try container.decode(String.self, forKey: .serialNumber)
        reportDateUTC = try container.decode(String.self, forKey: .reportDateUTC)
        reportDateEpoch = try container.decode(Int.self, forKey: .reportDateEpoch)
        
        // Gracefully handle lastEnrolledDate - try to decode as string, or as date if it comes in different format
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .lastEnrolledDate) {
            lastEnrolledDate = dateString
        } else if let _ = try? container.decodeIfPresent(Int.self, forKey: .lastEnrolledDate) {
            // If server returns it as timestamp, just skip it (optional field)
            lastEnrolledDate = nil
        } else {
            lastEnrolledDate = try? container.decodeIfPresent(String.self, forKey: .lastEnrolledDate)
        }
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








