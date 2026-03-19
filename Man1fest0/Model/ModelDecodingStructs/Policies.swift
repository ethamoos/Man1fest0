//
//  Policies.swift
//  Man1fest0
//
//  Created by Amos Deane on 19/07/2024.
//

import Foundation



// ################# Basic POLICY ####################


// Previously called Policies

// MARK: - Policies


struct PolicyBasic: Codable, Hashable {
    
    let policies: [Policy]

}

struct Policy: Codable, Hashable, Identifiable {
    var id = UUID()
    var jamfId: Int?
    var name: String
    enum CodingKeys:String, CodingKey{
        case jamfId = "id"
        case name = "name"
    }
}

// Previously called PolicyCodable

// ################# START OF DETAILED POLICY ####################

struct PoliciesDetailed: Codable, Hashable {
    let policy: PolicyDetailed }

struct PolicyDetailed: Codable, Hashable, Identifiable {
    
    var id = UUID()
    let general: General?
    //    let serialsByPrestageID: [String: String]
    let scope: Scope?
    let package_configuration: PackageConfiguration?
        let scripts: [PolicyScripts]?
    //    let printers: [PrinterElement]?
    let self_service: SelfService?
    //    let files_processes: FilesProcesses?
    //    let printer:[PrinterClass]?
    let printers: [String]?
    
    enum CodingKeys: String, CodingKey {
        case general = "general"
        case scope = "scope"
        case package_configuration = "package_configuration"
        case scripts = "scripts"
        case self_service = "self_service"
        case printers = "printers"
        //        case printers = "printers"
        //        case files_processes = "files_processes"
        //        case printer
    }
    
    
    // MARK: - Departments
    struct Departments: Codable, Hashable {
        let size: String
        let department: [Department]
    }

    // MARK: - DEPARTMENT
    struct Department: Codable, Hashable, Identifiable {
        
        var id = UUID()
        let jamfId: Int?
        let name: String
        
        enum CodingKeys: String, CodingKey {
            case jamfId = "id"
            case name = "name"
        }
    }
    
    
    // MARK: - Buildings
    struct Buildings: Codable {
        let buildings: [Building]
    }

    // MARK: - Building
    struct Building: Codable, Hashable, Identifiable {
        let id: Int
        let name: String
    }
}

// MARK: - PackageConfiguration
struct PackageConfiguration: Codable, Hashable, Identifiable  {
    var id = UUID()
    let packages: [Package]
    enum CodingKeys: String, CodingKey {
        case packages = "packages"
    }
}

struct Package: Codable, Hashable, Identifiable {
    var id = UUID()
    var jamfId: Int
    var name: String
    var udid: String?
    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
        case udid = "udid"
    }
}

// MARK: - Category
struct Category: Codable, Hashable, Identifiable  {
    let id = UUID()
    var jamfId: Int
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
    }
}

//MARK: - FileProcesses

struct FilesProcesses: Codable, Hashable, Identifiable {
    var id = UUID()
    var run_command:String?
    enum CodingKeys: String, CodingKey {
        case run_command = "run_command"
    }
}

struct General: Codable, Hashable, Identifiable {
    var id = UUID()
    let jamfId: Int?
    let name: String?
    let enabled: Bool?
    let trigger: String?
    let triggerCheckin, triggerEnrollmentComplete, triggerLogin, triggerLogout: Bool?
    let triggerNetworkStateChanged, triggerStartup: Bool?
    let triggerOther: String?
//    let frequency: String?
//    let locationUserOnly: Bool?
//    let targetDrive: String?
//    let offline: Bool?
    let category: Category?
    //    let dateTimeLimitations: DateTimeLimitations?
    //    let networkLimitations: NetworkLimitations?
        let overrideDefaultSettings: OverrideDefaultSettings?
//    let networkRequirements: String?
    //    let site: Category?
    let mac_address: String?
    let ip_address: String?
//    let payloads: String?
    
    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
        case enabled = "enabled"
        case trigger = "trigger"
        case triggerCheckin = "trigger_checkin"
        case triggerEnrollmentComplete = "trigger_enrollment_complete"
        case triggerLogin = "trigger_login"
        case triggerLogout = "trigger_logout"
        case triggerNetworkStateChanged = "trigger_network_state_changed"
        case triggerStartup = "trigger_startup"
        case triggerOther = "trigger_other"
//        case frequency = "frequency"
//        case locationUserOnly = "location_user_only"
//        case targetDrive = "target_drive"
//        case offline = "offline"
        case category = "category"
        //        case dateTimeLimitations = "date_time_limitations"
        //        case networkLimitations = "network_limitations"
                case overrideDefaultSettings = "override_default_settings"
//        case networkRequirements = "network_requirements"
        //        case site = "site"
        case mac_address = "mac_address"
        case ip_address = "ip_address"
//        case payloads = "payloads"
    }
    
    var enabledInt: Int {
        enabled == true ? 1 : 0
    }
    var categoryNameForSort: String { category?.name ?? "" }
    var nameForSort: String { name ?? "" }
    var triggerOtherForSort: String { triggerOther ?? "" }
    var jamfIdForSort: Int { jamfId ?? 0 }
}


//MARK: - PRINTER
struct Printers: Codable, Hashable, Identifiable {
    var id = UUID()
    var any: String?
    var printer: Result?
    struct Result: Codable, Hashable, Identifiable {
        var id = UUID()
        var jamfId: Int?
        var name: String?
        var makeDefault: Bool?
        
        enum CodingKeys: String, CodingKey {
            case jamfId = "id"
            case name = "name"
            case makeDefault = "makeDefault"
        }
    }
}


// MARK: - PolicyScripts
struct PolicyScripts: Codable, Hashable, Identifiable {
    var id = UUID()
    var jamfId: Int?
    var name: String?
    var priority: String?
    var parameter4: String?
    var parameter5: String?
    var parameter6: String?
    var parameter7: String?
    var parameter8: String?
    var parameter9: String?
    var parameter10: String?
    
    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
        case priority = "priority"
        case parameter4 = "parameter4"
        case parameter5 = "parameter5"
        case parameter6 = "parameter6"
        case parameter7 = "parameter7"
        case parameter8 = "parameter8"
        case parameter9 = "parameter9"
        case parameter10 = "parameter10"

    }
}



// MARK: - Reboot
struct Reboot: Codable, Hashable, Identifiable  {
    var id = UUID()
    let message, startupDisk, specifyStartup, noUserLoggedIn: String?
    let userLoggedIn: String?
    let minutesUntilReboot: Int?
    let startRebootTimerImmediately, fileVault2_Reboot: Bool?
    
    enum CodingKeys: String, CodingKey {
        case message = "message"
        case startupDisk = "startup_disk"
        case specifyStartup = "specify_startup"
        case noUserLoggedIn = "no_user_logged_in"
        case userLoggedIn = "user_logged_in"
        case minutesUntilReboot = "minutes_until_reboot"
        case startRebootTimerImmediately = "start_reboot_timer_immediately"
        case fileVault2_Reboot = "file_vault2_reboot"
    }
}

// MARK: - Scope

// Ensure LimitToUsers is defined before Scope so synthesized Codable/Hashable conformances work
struct LimitToUsers: Codable, Hashable, Identifiable  {
    var id = UUID()
    let users: [Users]?
    enum CodingKeys:String, CodingKey {
        case users = "users"
    }
}

struct Scope: Codable, Hashable, Identifiable  {
    var id = UUID()
    let allComputers: Bool?
    //        let all_mobile_devices: Bool?
            let all_jss_users:Bool?
    //        let mobile_device_groups: [ComputerGroups]?
    //        let jss_users:[GenericItem]?
    //        //  let jss_user_groups:[GenericItem]?
                let computers: [Computer]?
    //        let mobile_devices: [GenericItem]?
            let computerGroups: [ComputerGroups]?
            let buildings: [Building]?
            let departments: [Department]?
            let limitToUsers: LimitToUsers?
            let limitations: Limitations?
            let exclusions: Exclusions?

    enum CodingKeys: String, CodingKey {
        case allComputers = "all_computers"
        //            case all_mobile_devices = "all_mobile_devices"
                    case all_jss_users = "all_jss_users"
        //            case mobile_device_groups = "mobile_device_groups"
        //            case jss_users = "jss_users"
        //            //   case jss_user_groups = "jss_user_groups"
        case computers = "computers"
        //            case mobile_devices = "mobile_devices"
                    case computerGroups = "computer_groups"
                    case buildings = "buildings"
                    case departments = "departments"
                    case limitToUsers = "limit_to_users"
                    case limitations = "limitations"
                    case exclusions = "exclusions"
    }
}


struct GenericItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String?
    enum CodingKeys: String, CodingKey {
        case name = "name"
    }
}


// MARK: - Location
struct Location: Codable, Identifiable, Hashable {
    var id = UUID()
    var username, realname, emailAddress: String?
    var position, phone, phoneNumber, department: String?
    var building, room: String?
    
    enum CodingKeys: String, CodingKey {
        case username = "username"
        case realname = "realname"
        case emailAddress = "emailAddress"
        case position = "position"
        case phone = "phone"
        case phoneNumber = "phone_number"
        case department = "department"
        case building = "building"
        case room = "room"
    }
}


//// MARK: - Exclusions
struct Exclusions: Codable, Hashable, Identifiable  {
    var id = UUID()
    let computers, computerGroups, buildings, departments: [GenericItem]?
    let users, userGroups, networkSegments, ibeacons: [GenericItem]?
    let mobile_devices, mobile_device_groups, jss_users, jss_user_groups: [GenericItem]?

    enum CodingKeys: String, CodingKey {
        case computers = "computers"
        case computerGroups = "computer_groups"
        case buildings = "buildings"
        case departments = "departments"
        case users = "users"
        case userGroups = "user_groups"
        case networkSegments = "network_segments"
        case ibeacons = "ibeacons"
        case mobile_devices = "mobile_devices"
        case mobile_device_groups = "mobile_device_groups"
        case jss_users = "jss_users"
        case jss_user_groups = "jss_user_groups"
    }

    // Custom decoder to accept either an array or a single object for keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func decodeArrayOrSingle(_ key: CodingKeys) -> [GenericItem]? {
            if let arr = try? container.decode([GenericItem].self, forKey: key) {
                return arr
            }
            if let single = try? container.decode(GenericItem.self, forKey: key) {
                return [single]
            }
            return nil
        }

        self.computers = decodeArrayOrSingle(.computers)
        self.computerGroups = decodeArrayOrSingle(.computerGroups)
        self.buildings = decodeArrayOrSingle(.buildings)
        self.departments = decodeArrayOrSingle(.departments)
        self.users = decodeArrayOrSingle(.users)
        self.userGroups = decodeArrayOrSingle(.userGroups)
        self.networkSegments = decodeArrayOrSingle(.networkSegments)
        self.ibeacons = decodeArrayOrSingle(.ibeacons)
        self.mobile_devices = decodeArrayOrSingle(.mobile_devices)
        self.mobile_device_groups = decodeArrayOrSingle(.mobile_device_groups)
        self.jss_users = decodeArrayOrSingle(.jss_users)
        self.jss_user_groups = decodeArrayOrSingle(.jss_user_groups)
    }

    // encode straightforwardly as arrays (synthesized behavior)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(computers, forKey: .computers)
        try container.encodeIfPresent(computerGroups, forKey: .computerGroups)
        try container.encodeIfPresent(buildings, forKey: .buildings)
        try container.encodeIfPresent(departments, forKey: .departments)
        try container.encodeIfPresent(users, forKey: .users)
        try container.encodeIfPresent(userGroups, forKey: .userGroups)
        try container.encodeIfPresent(networkSegments, forKey: .networkSegments)
        try container.encodeIfPresent(ibeacons, forKey: .ibeacons)
        try container.encodeIfPresent(mobile_devices, forKey: .mobile_devices)
        try container.encodeIfPresent(mobile_device_groups, forKey: .mobile_device_groups)
        try container.encodeIfPresent(jss_users, forKey: .jss_users)
        try container.encodeIfPresent(jss_user_groups, forKey: .jss_user_groups)
    }
}

// MARK: - Limitations
struct Limitations: Codable, Hashable, Identifiable  {
    var id = UUID()
    let userGroups: [UserGroups]?
    let users: [GenericItem]?
    let network_segments: [GenericItem]?
    let ibeacons: [GenericItem]?
    let jss_users: [GenericItem]?
    let jss_user_groups: [GenericItem]?

    enum CodingKeys:String, CodingKey {
        case userGroups = "user_groups"
        case users = "users"
        case network_segments = "network_segments"
        case ibeacons = "ibeacons"
        case jss_users = "jss_users"
        case jss_user_groups = "jss_user_groups"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func decodeArrayOrSingle(_ key: CodingKeys) -> [GenericItem]? {
            if let arr = try? container.decode([GenericItem].self, forKey: key) {
                return arr
            }
            if let single = try? container.decode(GenericItem.self, forKey: key) {
                return [single]
            }
            return nil
        }

        self.userGroups = try? container.decodeIfPresent([UserGroups].self, forKey: .userGroups)
        self.users = decodeArrayOrSingle(.users)
        self.network_segments = decodeArrayOrSingle(.network_segments)
        self.ibeacons = decodeArrayOrSingle(.ibeacons)
        self.jss_users = decodeArrayOrSingle(.jss_users)
        self.jss_user_groups = decodeArrayOrSingle(.jss_user_groups)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userGroups, forKey: .userGroups)
        try container.encodeIfPresent(users, forKey: .users)
        try container.encodeIfPresent(network_segments, forKey: .network_segments)
        try container.encodeIfPresent(ibeacons, forKey: .ibeacons)
        try container.encodeIfPresent(jss_users, forKey: .jss_users)
        try container.encodeIfPresent(jss_user_groups, forKey: .jss_user_groups)
    }
}


// MARK: - SelfServiceCategory
struct SelfServiceCategory: Codable, Hashable, Identifiable {
    var id = UUID()
    let jamfId: Int?
    let name: String?
    let displayIn, featureIn: Bool?
    
    enum CodingKeys:String, CodingKey {
        case jamfId = "id"
        case name = "name"
        case displayIn = "display_in"
        case featureIn = "feature_in"
    }
}
//    // MARK: - SelfService
struct SelfService: Codable, Hashable, Identifiable  {
    var id = UUID()
    let useForSelfService: Bool?
    let selfServiceDisplayName, installButtonText, reinstallButtonText, selfServiceDescription: String?
    let forceUsersToViewDescription: Bool?
     let selfServiceIcon: SelfServiceIcon?
//    let featureOnMainPage: Bool?
//    let selfServiceCategories: [SelfServiceCategory]?
//    let notification, notificationSubject, notificationMessage: String?
    enum CodingKeys:String, CodingKey {
        case useForSelfService = "use_for_self_service"
        case selfServiceDisplayName = "self_service_display_name"
        case installButtonText = "install_button_text"
        case reinstallButtonText = "reinstall_button_text"
        case selfServiceDescription = "self_service_description"
        case forceUsersToViewDescription = "force_users_to_view_description"
         case selfServiceIcon = "self_service_icon"
//        case featureOnMainPage = "feature_on_main_page"
//        case selfServiceCategories = "self_service_categories"
//        case notification = "notification"
//        case notificationSubject = "notification_subject"
//        case notificationMessage = "notification_message"
    }
    
    //    // MARK: - SelfServiceIcon
        struct SelfServiceIcon: Codable, Hashable  {
            let filename: String?
            let id: Int?
            let uri: String?
        }
}



// MARK: - UserInteraction
struct UserInteraction {
    let messageStart, allowUsersToDefer, allowDeferralUntilUTC, allowDeferralMinutes: String
    let messageFinish: String
}




struct Users: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String?
    enum CodingKeys: String, CodingKey {
        case name = "name"
    }
}

struct UserGroups: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String?
    enum CodingKeys: String, CodingKey {
        case name = "name"
    }
}

// ################# END OF DETAILED POLICY ####################


extension General {
    var enabledForSort: Bool {
        enabled ?? false
    }
}