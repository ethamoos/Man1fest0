//
//  ComputerHistory.swift
//  Man1fest0
//
//  Created by Amos Deane on 27/04/2026.
//


import Foundation

// MARK: - ComputerHistoryResponse
struct ComputerHistoryResponse: Decodable {
    let computerHistory: ComputerHistory

    enum CodingKeys: String, CodingKey {
        case computerHistory = "computer_history"
        case computerHistoryAlt = "computerHistory"
        case computer = "computer"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let val = try? container.decode(ComputerHistory.self, forKey: .computerHistory) {
            computerHistory = val
        } else if let val = try? container.decode(ComputerHistory.self, forKey: .computerHistoryAlt) {
            computerHistory = val
        } else if let val = try? container.decode(ComputerHistory.self, forKey: .computer) {
            computerHistory = val
        } else {
            // attempt to decode top-level as ComputerHistory
            let singleValue = try decoder.singleValueContainer()
            computerHistory = try singleValue.decode(ComputerHistory.self)
        }
    }
}

// MARK: - ComputerHistory
struct ComputerHistory: Decodable {
    let general: CHGeneral?
    let computerUsageLogs: String?
    let audits: String?
    let policyLogs: PolicyLogs?
    let commands: Commands?
    let userLocation: CHUserLocation?
    let macAppStoreApplications: MACAppStoreApplications?

    enum CodingKeys: String, CodingKey {
        case general
        case computerUsageLogs = "computer_usage_logs"
        case audits
        case policyLogs = "policy_logs"
        case commands
        case userLocation = "user_location"
        case macAppStoreApplications = "mac_app_store_applications"
    }
}

// MARK: - Commands
struct Commands: Decodable {
    let completed: Completed?
    let pending: String?
    let failed: Failed?
}

// MARK: - Completed
struct Completed: Decodable {
    let command: [CommandElement]?
}

// MARK: - CommandElement
struct CommandElement: Decodable {
    let name: String?
    let completed: String?
    let completedEpoch: String?
    let completedUTC: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case name, completed
        case completedEpoch = "completedEpoch"
        case completedUTC = "completedUTC"
        case username
    }
}

// MARK: - Failed
struct Failed: Decodable {
    let command: FailedCommand?
}

// MARK: - FailedCommand
struct FailedCommand: Decodable {
    let name: String?
    let status: String?
    let issued: String?
    let issuedEpoch: String?
    let issuedUTC: String?
    let failed: String?
    let failedEpoch: String?
    let failedUTC: String?
    let username: String?
}

// MARK: - General
struct CHGeneral: Decodable {
    let id: String?
    let name: String?
    let udid: String?
    let serialNumber: String?
    let macAddress: String?

    enum CodingKeys: String, CodingKey {
        case id, name, udid
        case serialNumber = "serialNumber"
        case macAddress = "macAddress"
    }
}

// MARK: - MACAppStoreApplications
struct MACAppStoreApplications: Decodable {
    let installed: Installed?
    let pending: String?
    let failed: String?
}

// MARK: - Installed
struct Installed: Decodable {
    let apps: [CHApp]?
    
    enum CodingKeys: String, CodingKey {
        case apps = "app"
    }
}

// MARK: - CHApp
struct CHApp: Decodable {
    let name: String?
    let version: String?
    let sizeMB: String?

    enum CodingKeys: String, CodingKey {
        case name, version
        case sizeMB = "sizeMB"
    }
}

// MARK: - PolicyLogs
struct PolicyLogs: Decodable {
    let policyLog: [PolicyLog]?
}

// MARK: - PolicyLog
struct PolicyLog: Decodable {
    let policyID: String?
    let policyName: String?
    let username: String?
    let dateCompleted: String?
    let dateCompletedEpoch: String?
    let dateCompletedUTC: String?
    let status: String?
}

// MARK: - UserLocation
struct CHUserLocation: Decodable {
    let location: [CHLocation]?
}

// MARK: - Location
struct CHLocation: Decodable {
    let dateTime: String?
    let dateTimeEpoch: String?
    let dateTimeUTC: String?
    let username: String?
    let fullName: String?
    let emailAddress: String?
    let phoneNumber: String?
    let department: String?
    let building: String?
    let room: String?
    let position: String?
}

