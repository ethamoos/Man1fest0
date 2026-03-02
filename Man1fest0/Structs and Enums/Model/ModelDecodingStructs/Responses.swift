import Foundation



// MARK: - ConfigurationProfile
struct ConfigurationProfiles: Codable, Identifiable, Hashable {
    var id = UUID()
    // list of lightweight configuration profile summaries returned by the API
    var configurationProfiles: [ConfigProfileSummary]?
    var computerConfigurations: [ConfigProfileSummary]?
    enum CodingKeys: String, CodingKey {
        case configurationProfiles = "configuration_profiles"
        case computerConfigurations = "os_x_configuration_profiles"
    }
}

// Lightweight summary used in listings
struct ConfigProfileSummary: Codable, Identifiable, Hashable {
    var id = UUID()
    var jamfId: Int?
    var name: String

    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
    }
}


// MARK: - OsXConfigurationProfile
struct OsXConfigurationProfile: Codable, Hashable {
    var os_x_configuration_profile: ConfigurationProfile?
}

struct MobileConfigurationProfile: Codable, Hashable {
    var configuration_profile: ConfigurationProfile?
}

struct ConfigurationProfile: Codable, Hashable {
    var general: ConfigProfileGeneral?
}

// This file was generated from JSON Schema using codebeautify, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome6 = try Welcome6(json)

//import Foundation

// MARK: - osXConfigProfileDetailedResponse
struct OSXConfigProfileDetailedResponse: Codable {
    
    let osxConfigurationProfile: OSXConfigProfileDetailed

    enum CodingKeys: String, CodingKey {
        case osxConfigurationProfile = "os_x_configuration_profile"
    }
}

// MARK: - osXConfigProfileDetailed
struct OSXConfigProfileDetailed: Codable, Hashable {
    let general: ConfigProfileGeneral?
    let scope: ConfigScope?
    let selfService: ConfigSelfService?

    enum CodingKeys: String, CodingKey {
        case general
        case scope
        case selfService = "self_service"
    }
}

// MARK: - General
struct ConfigProfileGeneral: Codable, Hashable {
    let id: Int?
    let name: String?
    let generalDescription: String?
    let site: ConfigCategoryElement?
    let category: ConfigCategoryElement?
    let distributionMethod: String?
    let userRemovable: Bool?
    let level: String?
    let uuid: String?
    let redeployOnUpdate: String?
    let payloads: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case generalDescription = "description"
        case site
        case category
        case distributionMethod = "distribution_method"
        case userRemovable = "user_removable"
        case level
        case uuid
        case redeployOnUpdate = "redeploy_on_update"
        case payloads
    }
}

// MARK: - CategoryElement
struct ConfigCategoryElement: Codable, Hashable {
    let id: Int?
    let name: String?
}

// MARK: - Scope
struct ConfigScope: Codable, Hashable {
    let allComputers: Bool?
    let allJssUsers: Bool?
    let computers: [ConfigCategoryElement]?
    let buildings: [ConfigCategoryElement]?
    let departments: [ConfigCategoryElement]?
    let computerGroups: [ConfigCategoryElement]?
    let jssUsers: [ConfigCategoryElement]?
    let jssUserGroups: [String: ConfigCategoryElement]?
    let limitations: ConfigLimitations?
    let exclusions: ConfigExclusions?

    enum CodingKeys: String, CodingKey {
        case allComputers = "all_computers"
        case allJssUsers = "all_jss_users"
        case computers
        case buildings
        case departments
        case computerGroups = "computer_groups"
        case jssUsers = "jss_users"
        case jssUserGroups = "jss_user_groups"
        case limitations
        case exclusions
    }
}

// MARK: - Exclusions
struct ConfigExclusions: Codable, Hashable {
    let computers: [ConfigCategoryElement]?
    let buildings: [ConfigCategoryElement]?
    let departments: [ConfigCategoryElement]?
    let computerGroups: [ConfigCategoryElement]?
    let users: [ConfigCategoryElement]?
    let userGroups: [ConfigCategoryElement]?
    let networkSegments: [ConfigCategoryElement]?
    let ibeacons: [ConfigCategoryElement]?
    let jssUsers: [ConfigCategoryElement]?
    let jssUserGroups: [ConfigCategoryElement]?

    enum CodingKeys: String, CodingKey {
        case computers
        case buildings
        case departments
        case computerGroups = "computer_groups"
        case users
        case userGroups = "user_groups"
        case networkSegments = "network_segments"
        case ibeacons
        case jssUsers = "jss_users"
        case jssUserGroups = "jss_user_groups"
    }
}

// MARK: - ComputerGroups
struct ConfigComputerGroups: Codable, Hashable {
    let computerGroup: [ConfigCategoryElement]?

    enum CodingKeys: String, CodingKey {
        case computerGroup = "computer_group"
    }
}

// MARK: - Limitations
struct ConfigLimitations: Codable, Hashable {
    let users: [ConfigCategoryElement]?
    let userGroups: [ConfigCategoryElement]?
    let networkSegments: [ConfigCategoryElement]?
    let ibeacons: [ConfigCategoryElement]?

    enum CodingKeys: String, CodingKey {
        case users
        case userGroups = "user_groups"
        case networkSegments = "network_segments"
        case ibeacons
    }
}

// MARK: - SelfService
struct ConfigSelfService: Codable, Hashable {
    let selfServiceDisplayName: String?
    let installButtonText: String?
    let selfServiceDescription: String?
    let forceUsersToViewDescription: Bool?
    let security: ConfigSecurity?
    let selfServiceIcon: ConfigSelfServiceIcon?
    let featureOnMainPage: Bool?
    let selfServiceCategories: [ConfigSelfServiceCategory]?
    let notification: String?
    let notificationSubject: String?
    let notificationMessage: String?

    enum CodingKeys: String, CodingKey {
        case selfServiceDisplayName = "self_service_display_name"
        case installButtonText = "install_button_text"
        case selfServiceDescription = "description"
        case forceUsersToViewDescription = "force_users_to_view_description"
        case security
        case selfServiceIcon = "self_service_icon"
        case featureOnMainPage = "feature_on_main_page"
        case selfServiceCategories = "self_service_categories"
        case notification
        case notificationSubject = "notification_subject"
        case notificationMessage = "notification_message"
    }
}

// A minimal placeholder for the self service icon object (API sometimes returns an object)
struct ConfigSelfServiceIcon: Codable, Hashable {
    // keep flexible / empty – we only need to accept an object or empty object
}

// MARK: - Security
struct ConfigSecurity: Codable, Hashable {
    let removalDisallowed: String?

    enum CodingKeys: String, CodingKey {
        case removalDisallowed = "removal_disallowed"
    }
}

// MARK: - SelfServiceCategoriesCategory
struct ConfigSelfServiceCategory: Codable, Hashable {
    let id: Int?
    let name: String?
    let displayIn: Bool?
    let featureIn: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case displayIn = "display_in"
        case featureIn = "feature_in"
    }
}


// MARK: - DateTimeLimitations
struct DateTimeLimitations: Codable, Hashable, Identifiable {
    let id = UUID()
    let activationDate: String
    let activationDateEpoch: Int
    let activationDateUTC, expirationDate: String
    let expirationDateEpoch: Int
    let expirationDateUTC: String
    //let noExecuteOn:[SelfServiceIcon]
    let noExecuteStart, noExecuteEnd: String
    
    enum CodingKeys: String, CodingKey {
        case activationDate = "activation_date"
        case activationDateEpoch = "activation_date_epoch"
        case activationDateUTC = "activation_date_utc"
        case expirationDate = "expiration_date"
        case expirationDateEpoch = "expiration_date_epoch"
        case expirationDateUTC = "expiration_date_utc"
        // case noExecuteOn = "no_execute_on"
        case noExecuteStart = "no_execute_start"
        case noExecuteEnd = "no_execute_end"
    }
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



// MARK: - Maintenance
struct Maintenance: Codable, Hashable, Identifiable {
    
    var id = UUID()
    let recon, resetName, installAllCachedPackages, heal: Bool?
    let prebindings, permissions, byhost, systemCache: Bool?
    let userCache, verify: Bool?
    
    enum CodingKeys: String, CodingKey {
        case recon = "recon"
        case resetName = "reset_name"
        case installAllCachedPackages = "install_all_cached_packages"
        case heal = "heal"
        case prebindings = "prebindings"
        case permissions = "permissions"
        case byhost = "byhost"
        case systemCache = "system_cache"
        case userCache = "user_cache"
        case verify = "verify"
    }
}






// MARK: - NetworkLimitations
struct NetworkLimitations: Codable, Hashable, Identifiable {
    var id = UUID()
    let minimumNetworkConnection: String
    let anyIPAddress: Bool
    let networkSegments: [GenericItem]?
    
    enum CodingKeys: String, CodingKey {
        case minimumNetworkConnection = "minimum_network_connection"
        case anyIPAddress = "any_ip_address"
        case networkSegments = "network_segments"
    }
}

// MARK: - OverrideDefaultSettings
struct OverrideDefaultSettings: Codable, Hashable, Identifiable {
    var id = UUID()
    // Make all properties optional to tolerate missing keys in the API response
    let targetDrive: String?
    let distributionPoint: String?
    let forceAFPSMB: Bool?
    let sus: String?
    let netbootServer: String?

    enum CodingKeys: String, CodingKey {
        case targetDrive = "target_drive"
        case distributionPoint = "distribution_point"
        case forceAFPSMB = "force_afp_smb"
        case sus = "sus"
        case netbootServer = "netboot_server"
    }
}


struct Packages: Codable, Hashable {
    var packages: [Package]
}

struct PackageDetailedResponse: Codable, Hashable {
    let package: PackageDetailed
}


// MARK: - Package
struct PackageDetailed: Codable, Hashable, Identifiable {
    let id: Int
    let name, category, filename, info: String
    let notes: String
    let priority: Int
    let rebootRequired, fillUserTemplate, fillExistingUsers, allowUninstalled: Bool
    let osRequirements, requiredProcessor, hashType, hashValue: String
    let switchWithPackage, installIfReportedAvailable, reinstallOption: String
    //    let triggeringFiles: TriggeringFiles
    let sendNotification: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, filename, info, notes, priority
        case rebootRequired = "reboot_required"
        case fillUserTemplate = "fill_user_template"
        case fillExistingUsers = "fill_existing_users"
        case allowUninstalled = "allow_uninstalled"
        case osRequirements = "os_requirements"
        case requiredProcessor = "required_processor"
        case hashType = "hash_type"
        case hashValue = "hash_value"
        case switchWithPackage = "switch_with_package"
        case installIfReportedAvailable = "install_if_reported_available"
        case reinstallOption = "reinstall_option"
        //        case triggeringFiles = "triggering_files"
        case sendNotification = "send_notification"
    }
}


// MARK: - TriggeringFiles
struct TriggeringFiles: Codable {
}

// MARK: - SelfServiceIcon
struct SelfServiceIcon: Codable, Hashable  {
    let filename: String?
    let id: Int?
    let uri: String?
}

//MARK: - SCRIPTS
struct Scripts: Codable, Identifiable, Hashable {
    var id = UUID()
    //    var totalCount: Int
    var scripts: [ScriptClassic]
    enum CodingKeys:String, CodingKey{
        //            case totalCount = "totalCount"
        case scripts = "scripts"
    }
}

struct ScriptClassic: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var jamfId: Int
    //    var categoryId: String
    //    var categoryName: String
    //    var info: String
    //    var notes: String
    //    var priority: String
    //    var scriptContents: String
    
    enum  CodingKeys:String, CodingKey{
        case name = "name"
        case jamfId = "id"
        //        case categoryId = "categoryId"
        //        case categoryName = "categoryName"
        //        case info = "info"
        //        case notes = "notes"
        //        case priority = "priority"
        //        case scriptContents = "scriptContents"
    }
}


// MARK: - Welcome
struct computerGroupResponse: Codable {
    
    let computerGroup: ComputerGroup
    
    enum CodingKeys: String, CodingKey {
        case computerGroup = "computer_group"
    }
    
    
    // MARK: - ComputerGroup
    struct ComputerGroup: Codable, Identifiable {
        let id: Int
        let name: String
        let isSmart: Bool
        let site: Site
        let criteria: [Criterion]
        let computers: [Computer]
        
        enum CodingKeys: String, CodingKey {
            case id, name
            case isSmart = "is_smart"
            case site, criteria, computers
        }
    }
    
    // MARK: - Computer
    struct Computer: Codable, Hashable {
        let id: Int
        let name, macAddress, altMACAddress, serialNumber: String
        
        enum CodingKeys: String, CodingKey {
            case id, name
            case macAddress = "mac_address"
            case altMACAddress = "alt_mac_address"
            case serialNumber = "serial_number"
        }
    }
    
    // MARK: - Criterion
    struct Criterion: Codable {
        let name: String
        let priority: Int
        let andOr, searchType, value: String
        let openingParen, closingParen: Bool

        enum CodingKeys: String, CodingKey {
            case name, priority
            case andOr = "and_or"
            case searchType = "search_type"
            case value
            case openingParen = "opening_paren"
            case closingParen = "closing_paren"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.priority = try container.decode(Int.self, forKey: .priority)
            self.andOr = try container.decode(String.self, forKey: .andOr)
            self.searchType = try container.decode(String.self, forKey: .searchType)
            self.value = try container.decode(String.self, forKey: .value)
            self.openingParen = try container.decode(Bool.self, forKey: .openingParen)
            self.closingParen = try container.decode(Bool.self, forKey: .closingParen)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(priority, forKey: .priority)
            try container.encode(andOr, forKey: .andOr)
            try container.encode(searchType, forKey: .searchType)
            try container.encode(value, forKey: .value)
            try container.encode(openingParen, forKey: .openingParen)
            try container.encode(closingParen, forKey: .closingParen)
        }
    }
    
    // MARK: - Site
    struct Site: Codable {
        let id: Int
        let name: String
    }
}
