
import Foundation



// MARK: - ConfigurationProfile
struct ConfigurationProfiles: Codable, Identifiable, Hashable {
    var id = UUID()
    var configurationProfiles: [ConfigurationProfile]?
    var computerConfigurations: [ConfigurationProfile]?
    enum CodingKeys: String, CodingKey {
        case configurationProfiles = "configuration_profiles"
        case computerConfigurations = "os_x_configuration_profiles"
    }
    
    struct ConfigurationProfile: Codable, Identifiable, Hashable {
        
        var id = UUID()
        var jamfId: Int?
        var name: String

        enum CodingKeys: String, CodingKey {
            case jamfId = "id"
            case name = "name"
        }
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
    var general: General?
//    var scope: Scope?
//    var selfService: SelfService?
//    var payloads: ConfigPayload?
    
    enum CodingKeys: String, CodingKey {
        case general = "general"
//        case scope = "scope"
//        case selfService = "self_service"
//        case payloads = "payloads"
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
    let targetDrive, distributionPoint: String
    let forceAFPSMB: Bool
    let sus, netbootServer: String
    
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
    }
    
    // MARK: - Site
    struct Site: Codable {
        let id: Int
        let name: String
    }
}
