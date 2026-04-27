//
//  ComputerHistory.swift
//  Man1fest0
//
//  Created by Amos Deane on 27/04/2026.
//


import Foundation

// MARK: - ComputerHistoryResponse
struct ComputerHistoryResponse {
    let computerHistory: ComputerHistory


// MARK: - ComputerHistory
struct ComputerHistory {
    let general: General
    let computerUsageLogs, audits: String
    let policyLogs: PolicyLogs
    let commands: Commands
    let userLocation: UserLocation
    let macAppStoreApplications: MACAppStoreApplications
}

// MARK: - Commands
struct Commands {
    let completed: Completed
    let pending: String
    let failed: Failed
}

// MARK: - Completed
struct Completed {
    let command: [CommandElement]
}

// MARK: - CommandElement
struct CommandElement {
    let name, completed, completedEpoch, completedUTC: String
    let username: Username
}

enum Username {
    case empty
}

// MARK: - Failed
struct Failed {
    let command: FailedCommand
}

// MARK: - FailedCommand
struct FailedCommand {
    let name, status, issued, issuedEpoch: String
    let issuedUTC, failed, failedEpoch, failedUTC: String
    let username: String
}

// MARK: - General
struct General {
    let id, name, udid, serialNumber: String
    let macAddress: String
}

// MARK: - MACAppStoreApplications
struct MACAppStoreApplications {
    let installed: Installed
    let pending, failed: String
}

// MARK: - Installed
struct Installed {
    let app: [App]
}

// MARK: - App
struct App {
    let name, version, sizeMB: String
}

// MARK: - PolicyLogs
struct PolicyLogs {
    let policyLog: [PolicyLog]
}

// MARK: - PolicyLog
struct PolicyLog {
    let policyID, policyName: String
    let username: Username
    let dateCompleted, dateCompletedEpoch, dateCompletedUTC, status: String
}

// MARK: - UserLocation
struct UserLocation {
    let location: [Location]
}

// MARK: - Location
struct Location {
    let dateTime, dateTimeEpoch, dateTimeUTC, username: String
    let fullName, emailAddress, phoneNumber, department: String
    let building, room, position: String
}
    
}
