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
    let computerUsageLogs: [Any]? // flexible: can be array or object in different API versions
    let audits: [Any]?
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

    // Custom decoding to be tolerant of multiple shapes returned by Jamf for this
    // endpoint (some endpoints return arrays directly, others wrap them). We
    // primarily extract `general` and `userLocation` reliably; other fields are
    // left as flexible arrays when possible.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // general
        self.general = try container.decodeIfPresent(CHGeneral.self, forKey: .general)

        // computer_usage_logs may be an array or an object; try array first
        if let arr = try? container.decodeIfPresent([AnyCodable].self, forKey: .computerUsageLogs) {
            self.computerUsageLogs = arr.map { $0.value }
        } else {
            self.computerUsageLogs = nil
        }

        // audits similarly
        if let arr = try? container.decodeIfPresent([AnyCodable].self, forKey: .audits) {
            self.audits = arr.map { $0.value }
        } else {
            self.audits = nil
        }

        // policy_logs sometimes is an array or an object; attempt to decode PolicyLogs first
        if let pl = try? container.decodeIfPresent(PolicyLogs.self, forKey: .policyLogs) {
            self.policyLogs = pl
        } else if let arr = try? container.decodeIfPresent([PolicyLog].self, forKey: .policyLogs) {
            // server returned an array of policy log objects; wrap into PolicyLogs
            self.policyLogs = PolicyLogs(policyLog: arr)
        } else if let _ = try? container.decodeIfPresent([AnyCodable].self, forKey: .policyLogs) {
            // unknown array form - treat as empty
            self.policyLogs = PolicyLogs(policyLog: [])
        } else {
            self.policyLogs = nil
        }

                // commands - try to decode object or tolerant shapes
                if let cmds = try? container.decodeIfPresent(Commands.self, forKey: .commands) {
                    self.commands = cmds
                } else {
                    self.commands = nil
                }

        // user_location in some responses is an array of location objects directly
        if let locArray = try? container.decodeIfPresent([CHLocation].self, forKey: .userLocation) {
            self.userLocation = CHUserLocation(location: locArray)
        } else if let locObj = try? container.decodeIfPresent(CHUserLocation.self, forKey: .userLocation) {
            self.userLocation = locObj
        } else {
            self.userLocation = nil
        }

        // mac_app_store_applications may be object with installed/pending/failed
        self.macAppStoreApplications = try? container.decodeIfPresent(MACAppStoreApplications.self, forKey: .macAppStoreApplications)
    }
}

// MARK: - Commands
struct Commands: Decodable {
    let completed: [CompletedCommand]?
    let pending: [PendingCommand]?
    let failed: [PendingCommand]?
}

// MARK: - CompletedCommand
struct CompletedCommand: Decodable {
    let name: String?
    let completed: String?
    let completedEpoch: Int64?
    let completedUTC: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case name, completed
        case completedEpoch = "completed_epoch"
        case completedUTC = "completed_utc"
        case username
    }
}

// MARK: - PendingCommand (used for pending and failed arrays)
struct PendingCommand: Decodable {
    let name: String?
    let status: String?
    let issued: String?
    let issuedEpoch: Int64?
    let issuedUTC: String?
    let lastPush: String?
    let lastPushEpoch: Int64?
    let lastPushUTC: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case name, status, issued
        case issuedEpoch = "issued_epoch"
        case issuedUTC = "issued_utc"
        case lastPush = "last_push"
        case lastPushEpoch = "last_push_epoch"
        case lastPushUTC = "last_push_utc"
        case username
    }
}

// MARK: - General
struct CHGeneral: Decodable {
    let id: Int?
    let name: String?
    let udid: String?
    let serialNumber: String?
    let macAddress: String?

    enum CodingKeys: String, CodingKey {
        case id, name, udid
        case serialNumber = "serial_number"
        case macAddress = "mac_address"
    }

    // Convenience: string form of id for UI comparisons
    var idString: String? {
        guard let id = id else { return nil }
        return String(id)
    }
}

// MARK: - MACAppStoreApplications
struct MACAppStoreApplications: Decodable {
    let installed: [CHApp]?
    let pending: [CHApp]?
    let failed: [CHApp]?

    enum CodingKeys: String, CodingKey {
        case installed, pending, failed
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
    let dateCompletedEpoch: Int64?
    let dateCompletedUTC: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case policyID = "policy_id"
        case policyName = "policy_name"
        case username
        case dateCompleted = "date_completed"
        case dateCompletedEpoch = "date_completed_epoch"
        case dateCompletedUTC = "date_completed_utc"
        case status
    }
}

// MARK: - UserLocation
struct CHUserLocation: Decodable {
    let location: [CHLocation]?
}

// MARK: - Location
struct CHLocation: Decodable {
    let dateTime: String?
    let dateTimeEpoch: Int64?
    let dateTimeUTC: String?
    let username: String?
    let fullName: String?
    let emailAddress: String?
    let phoneNumber: String?
    let department: String?
    let building: String?
    let room: String?
    let position: String?

    enum CodingKeys: String, CodingKey {
        case dateTime = "date_time"
        case dateTimeEpoch = "date_time_epoch"
        case dateTimeUTC = "date_time_utc"
        case username
        case fullName = "full_name"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
        case department, building, room, position
    }

    // Tolerant decoding: date_time_epoch can be an integer or a string in different
    // Jamf API versions. Attempt to decode as Int64 first, then as String and
    // convert to Int64 if possible.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateTime = try container.decodeIfPresent(String.self, forKey: .dateTime)

        // Try Int64
        if let intVal = try? container.decodeIfPresent(Int64.self, forKey: .dateTimeEpoch) {
            self.dateTimeEpoch = intVal
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .dateTimeEpoch), let parsed = Int64(strVal) {
            self.dateTimeEpoch = parsed
        } else {
            self.dateTimeEpoch = nil
        }

        self.dateTimeUTC = try container.decodeIfPresent(String.self, forKey: .dateTimeUTC)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        self.emailAddress = try container.decodeIfPresent(String.self, forKey: .emailAddress)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.department = try container.decodeIfPresent(String.self, forKey: .department)
        self.building = try container.decodeIfPresent(String.self, forKey: .building)
        self.room = try container.decodeIfPresent(String.self, forKey: .room)
        self.position = try container.decodeIfPresent(String.self, forKey: .position)
    }
}

