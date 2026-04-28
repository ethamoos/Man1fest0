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

    // Allow manual construction when decoding fails so callers can build a
    // best-effort ComputerHistory from loosely parsed JSON.
    init(general: CHGeneral?, computerUsageLogs: [Any]?, audits: [Any]?, policyLogs: PolicyLogs?, commands: Commands?, userLocation: CHUserLocation?, macAppStoreApplications: MACAppStoreApplications?) {
        self.general = general
        self.computerUsageLogs = computerUsageLogs
        self.audits = audits
        self.policyLogs = policyLogs
        self.commands = commands
        self.userLocation = userLocation
        self.macAppStoreApplications = macAppStoreApplications
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

    // Tolerant decoding for completedEpoch: accept Int or String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.completed = try container.decodeIfPresent(String.self, forKey: .completed)

        if let intVal = try? container.decodeIfPresent(Int64.self, forKey: .completedEpoch) {
            self.completedEpoch = intVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .completedEpoch) {
            self.completedEpoch = Int64(intVal)
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .completedEpoch), let parsed = Int64(strVal) {
            self.completedEpoch = parsed
        } else {
            self.completedEpoch = nil
        }

        self.completedUTC = try container.decodeIfPresent(String.self, forKey: .completedUTC)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
    }

    // Memberwise initializer for programmatic construction (used by fallback parser)
    init(name: String?, completed: String?, completedEpoch: Int64?, completedUTC: String?, username: String?) {
        self.name = name
        self.completed = completed
        self.completedEpoch = completedEpoch
        self.completedUTC = completedUTC
        self.username = username
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

    // Tolerant decoding for epoch fields which may be numbers or strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.issued = try container.decodeIfPresent(String.self, forKey: .issued)

        if let intVal = try? container.decodeIfPresent(Int64.self, forKey: .issuedEpoch) {
            self.issuedEpoch = intVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .issuedEpoch) {
            self.issuedEpoch = Int64(intVal)
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .issuedEpoch), let parsed = Int64(strVal) {
            self.issuedEpoch = parsed
        } else {
            self.issuedEpoch = nil
        }

        self.issuedUTC = try container.decodeIfPresent(String.self, forKey: .issuedUTC)
        self.lastPush = try container.decodeIfPresent(String.self, forKey: .lastPush)

        if let intVal = try? container.decodeIfPresent(Int64.self, forKey: .lastPushEpoch) {
            self.lastPushEpoch = intVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .lastPushEpoch) {
            self.lastPushEpoch = Int64(intVal)
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .lastPushEpoch), let parsed = Int64(strVal) {
            self.lastPushEpoch = parsed
        } else {
            self.lastPushEpoch = nil
        }

        self.lastPushUTC = try container.decodeIfPresent(String.self, forKey: .lastPushUTC)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
    }

    // Memberwise initializer for programmatic construction (used by fallback parser)
    init(name: String?, status: String?, issued: String?, issuedEpoch: Int64?, issuedUTC: String?, lastPush: String?, lastPushEpoch: Int64?, lastPushUTC: String?, username: String?) {
        self.name = name
        self.status = status
        self.issued = issued
        self.issuedEpoch = issuedEpoch
        self.issuedUTC = issuedUTC
        self.lastPush = lastPush
        self.lastPushEpoch = lastPushEpoch
        self.lastPushUTC = lastPushUTC
        self.username = username
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

    // Tolerant decoding for dateCompletedEpoch (string or number)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // policy_id may be returned as an Int or a String in different API
        // versions. Try String first, then Int64/Int and convert to String.
        if let str = try? container.decodeIfPresent(String.self, forKey: .policyID) {
            self.policyID = str
        } else if let intVal = try? container.decodeIfPresent(Int64.self, forKey: .policyID) {
            self.policyID = String(intVal)
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .policyID) {
            self.policyID = String(intVal)
        } else {
            self.policyID = nil
        }

        // policy_name and username should usually be strings; be tolerant
        // in case they're missing or unexpectedly typed by decoding as String.
        self.policyName = try? container.decodeIfPresent(String.self, forKey: .policyName)
        self.username = try? container.decodeIfPresent(String.self, forKey: .username)
        self.dateCompleted = try container.decodeIfPresent(String.self, forKey: .dateCompleted)

        if let intVal = try? container.decodeIfPresent(Int64.self, forKey: .dateCompletedEpoch) {
            self.dateCompletedEpoch = intVal
        } else if let intVal = try? container.decodeIfPresent(Int.self, forKey: .dateCompletedEpoch) {
            self.dateCompletedEpoch = Int64(intVal)
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .dateCompletedEpoch), let parsed = Int64(strVal) {
            self.dateCompletedEpoch = parsed
        } else {
            self.dateCompletedEpoch = nil
        }

        self.dateCompletedUTC = try container.decodeIfPresent(String.self, forKey: .dateCompletedUTC)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    // Memberwise initializer for programmatic construction (used by fallback parser)
    init(policyID: String?, policyName: String?, username: String?, dateCompleted: String?, dateCompletedEpoch: Int64?, dateCompletedUTC: String?, status: String?) {
        self.policyID = policyID
        self.policyName = policyName
        self.username = username
        self.dateCompleted = dateCompleted
        self.dateCompletedEpoch = dateCompletedEpoch
        self.dateCompletedUTC = dateCompletedUTC
        self.status = status
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

    // Provide an explicit initializer so callers can construct CHLocation
    // instances when building a best-effort model from JSONDictionary parsing.
    init(dateTime: String?, dateTimeEpoch: Int64?, dateTimeUTC: String?, username: String?, fullName: String?, emailAddress: String?, phoneNumber: String?, department: String?, building: String?, room: String?, position: String?) {
        self.dateTime = dateTime
        self.dateTimeEpoch = dateTimeEpoch
        self.dateTimeUTC = dateTimeUTC
        self.username = username
        self.fullName = fullName
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.department = department
        self.building = building
        self.room = room
        self.position = position
    }
}
