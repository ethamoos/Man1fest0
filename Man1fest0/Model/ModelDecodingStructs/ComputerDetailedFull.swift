// Minimal full computer detail decoding structs for UI use
import Foundation

// Matches Jamf's 'computers/id/<id>' JSON which contains a top-level "computer" object
// Also supports v3 API which returns the data at top level without wrapping
struct ComputerDetailedFullResponse: Decodable {
    let computer: ComputerFull
    
    init(from decoder: Decoder) throws {
        // Try to decode with wrapper first (classic API)
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let wrapped = try? container.decode(ComputerFull.self, forKey: .computer) {
            computer = wrapped
        } else {
            // v3 API: decode directly at top level
            computer = try ComputerFull(from: decoder)
        }
    }
    
    // Allow direct initialization from ComputerFull for convenience
    init(computer: ComputerFull) {
        self.computer = computer
    }
    
    enum CodingKeys: String, CodingKey {
        case computer
    }
}

struct ComputerFull: Decodable {
    var general: General?
    let location: Location?
    let hardware: Hardware?
    let security: Security?
    let software: Software?
    let extension_attributes: [ExtensionAttribute]?
    let group_accounts: GroupAccounts?
    let configuration_profiles: ConfigurationProfiles?
    let iphones: IPhones?
    
    enum CodingKeys: String, CodingKey {
        case general
        case location
        case hardware
        case security
        case software
        case extension_attributes
        case extensionAttributes
        case group_accounts = "groups_accounts"
        case groupsAccounts
        case configuration_profiles
        case configurationProfiles
        case iphones
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        general = try? container.decodeIfPresent(General.self, forKey: .general)
        location = try? container.decodeIfPresent(Location.self, forKey: .location)
        hardware = try? container.decodeIfPresent(Hardware.self, forKey: .hardware)
        security = try? container.decodeIfPresent(Security.self, forKey: .security)
        software = try? container.decodeIfPresent(Software.self, forKey: .software)
        
        // Try both extension_attributes and extensionAttributes
        if let attrs = try? container.decodeIfPresent([ExtensionAttribute].self, forKey: .extension_attributes) {
            extension_attributes = attrs
        } else {
            extension_attributes = try? container.decodeIfPresent([ExtensionAttribute].self, forKey: .extensionAttributes)
        }
        
        // Try both groups_accounts and groupsAccounts
        if let grp = try? container.decodeIfPresent(GroupAccounts.self, forKey: .group_accounts) {
            group_accounts = grp
        } else {
            group_accounts = try? container.decodeIfPresent(GroupAccounts.self, forKey: .groupsAccounts)
        }
        
        // Try both configuration_profiles and configurationProfiles
        if let profiles = try? container.decodeIfPresent(ConfigurationProfiles.self, forKey: .configuration_profiles) {
            configuration_profiles = profiles
        } else {
            configuration_profiles = try? container.decodeIfPresent(ConfigurationProfiles.self, forKey: .configurationProfiles)
        }
        
        iphones = try? container.decodeIfPresent(IPhones.self, forKey: .iphones)
    }
    
    struct General: Decodable {
        var id: String
        let name: String?
        let udid: String?
        let serial_number: String?
        let ip_address: String?
        let model: String?
        let username: String?
        let report_date_utc: String?
        let last_enrolled_date: String?
        
        enum CodingKeys: String, CodingKey {
            case id, name, udid
            case serial_number = "serial_number"
            case model, username, ip_address
            case report_date_utc = "report_date_utc"
            case last_enrolled_date = "last_enrolled_date"
        }
        
        // Regular initializer for creating General with a known ID
        init(id: String, name: String? = nil, udid: String? = nil, serial_number: String? = nil, ip_address: String? = nil, model: String? = nil, username: String? = nil, report_date_utc: String? = nil, last_enrolled_date: String? = nil) {
            self.id = id
            self.name = name
            self.udid = udid
            self.serial_number = serial_number
            self.ip_address = ip_address
            self.model = model
            self.username = username
            self.report_date_utc = report_date_utc
            self.last_enrolled_date = last_enrolled_date
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // id can be a number or a string in different Jamf responses
            if let idStr = try? container.decode(String.self, forKey: .id) {
                id = idStr
            } else if let idInt = try? container.decode(Int.self, forKey: .id) {
                id = String(idInt)
            } else if let idDouble = try? container.decode(Double.self, forKey: .id) {
                // If server returns numeric as a float (unlikely), convert sensibly
                id = String(Int(idDouble))
            } else {
                id = ""
            }
            
            name = try? container.decodeIfPresent(String.self, forKey: .name)
            udid = try? container.decodeIfPresent(String.self, forKey: .udid)
            serial_number = try? container.decodeIfPresent(String.self, forKey: .serial_number)
            model = try? container.decodeIfPresent(String.self, forKey: .model)
            username = try? container.decodeIfPresent(String.self, forKey: .username)
            ip_address = try? container.decodeIfPresent(String.self, forKey: .ip_address)
            report_date_utc = try? container.decodeIfPresent(String.self, forKey: .report_date_utc)
            
            // Handle last_enrolled_date flexibly - could be string or other types
            if let dateStr = try? container.decodeIfPresent(String.self, forKey: .last_enrolled_date) {
                last_enrolled_date = dateStr
            } else if let _ = try? container.decodeIfPresent(Int.self, forKey: .last_enrolled_date) {
                // If server returns it as timestamp, convert to ISO string or keep nil
                last_enrolled_date = nil
            } else {
                last_enrolled_date = nil
            }
        }
    }
    
    struct Location: Decodable {
        let username: String?
        let realname: String?
        let real_name: String?
        let email_address: String?
        let position: String?
        let phone: String?
        let phone_number: String?
        let department: String?
        let building: String?
        let room: String?
        
        enum CodingKeys: String, CodingKey {
            case username, realname, real_name, email_address, position, phone, phone_number, department, building, room
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            username = try? container.decodeIfPresent(String.self, forKey: .username)
            realname = try? container.decodeIfPresent(String.self, forKey: .realname)
            real_name = try? container.decodeIfPresent(String.self, forKey: .real_name)
            email_address = try? container.decodeIfPresent(String.self, forKey: .email_address)
            position = try? container.decodeIfPresent(String.self, forKey: .position)
            phone = try? container.decodeIfPresent(String.self, forKey: .phone)
            phone_number = try? container.decodeIfPresent(String.self, forKey: .phone_number)
            department = try? container.decodeIfPresent(String.self, forKey: .department)
            building = try? container.decodeIfPresent(String.self, forKey: .building)
            room = try? container.decodeIfPresent(String.self, forKey: .room)
        }
    }
    
    struct Hardware: Decodable {
        // include only fields we need; others can be added later
        let model: String?
        // diskEncryptionConfiguration is named variously; match expected key(s)
        let diskEncryptionConfiguration: String?
        
        enum CodingKeys: String, CodingKey {
            case model
            case disk_encryption_configuration = "disk_encryption_configuration"
            case diskEncryptionConfiguration = "diskEncryptionConfiguration"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            model = try? container.decodeIfPresent(String.self, forKey: .model)
            // Accept either snake_case or camelCase key name
            diskEncryptionConfiguration = (try? container.decodeIfPresent(String.self, forKey: .disk_encryption_configuration)) ?? (try? container.decodeIfPresent(String.self, forKey: .diskEncryptionConfiguration))
        }
    }
    
    struct Software: Decodable {
        // Many software fields are arrays in the API; accept arrays of String
        let unix_executables: [String]?
        let licensed_software: [String]?
        let installed_by_casper: [String]?
        let installed_by_jamf_pro: [String]?
        let installed_by_installer_swu: [String]?
        let cached_by_casper: [String]?
        let cached_by_jamf_pro: [String]?
        let available_software_updates: [String]?
        let available_updates: [String]?
        let running_services: [String]?
        // applications can be provided either as a top-level array or wrapped; accept both
        let applications: [Applications.Application]?
        // fonts/plugins are arrays in the sample
        let fonts: [String]?
        let plugins: [String]?
        
        struct Applications: Decodable {
            let size: String?
            let application: [Application]?
            
            struct Application: Decodable {
                let name: String?
                let path: String?
                let version: String?
                let bundle_id: String?
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                size = try? container.decodeIfPresent(String.self, forKey: .size)
                // Try to decode application as array or single element
                if let apps = try? container.decodeIfPresent([Application].self, forKey: .application) {
                    application = apps
                } else if let single = try? container.decodeIfPresent(Application.self, forKey: .application) {
                    application = [single]
                } else {
                    application = nil
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case size, application
            }
        }
        
        struct SizeWrapper: Decodable {
            let size: String?
        }
        
        enum CodingKeys: String, CodingKey {
            case unix_executables, licensed_software, installed_by_casper, installed_by_jamf_pro, installed_by_installer_swu, cached_by_casper, cached_by_jamf_pro, available_software_updates, available_updates, running_services, applications, fonts, plugins
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // decode arrays of strings
            unix_executables = try? container.decodeIfPresent([String].self, forKey: .unix_executables)
            licensed_software = try? container.decodeIfPresent([String].self, forKey: .licensed_software)
            installed_by_casper = try? container.decodeIfPresent([String].self, forKey: .installed_by_casper)
            installed_by_jamf_pro = try? container.decodeIfPresent([String].self, forKey: .installed_by_jamf_pro)
            installed_by_installer_swu = try? container.decodeIfPresent([String].self, forKey: .installed_by_installer_swu)
            cached_by_casper = try? container.decodeIfPresent([String].self, forKey: .cached_by_casper)
            cached_by_jamf_pro = try? container.decodeIfPresent([String].self, forKey: .cached_by_jamf_pro)
            available_software_updates = try? container.decodeIfPresent([String].self, forKey: .available_software_updates)
            available_updates = try? container.decodeIfPresent([String].self, forKey: .available_updates)
            running_services = try? container.decodeIfPresent([String].self, forKey: .running_services)

            // applications: accept either an array directly or a wrapped Applications object
            if let appsArray = try? container.decodeIfPresent([Applications.Application].self, forKey: .applications) {
                applications = appsArray
            } else if let wrapped = try? container.decodeIfPresent(Applications.self, forKey: .applications) {
                applications = wrapped.application
            } else {
                applications = nil
            }

            // fonts/plugins may be arrays
            fonts = try? container.decodeIfPresent([String].self, forKey: .fonts)
            plugins = try? container.decodeIfPresent([String].self, forKey: .plugins)
        }
    }
    
    // Simple extension attribute representation used in multiple responses
    struct ExtensionAttribute: Decodable {
        let id: Int?
        let name: String?
        let type: String?
        let multi_value: Bool?
        let value: String?
    }
    
    struct GroupAccounts: Decodable {
        let computer_group_memberships: [String]?
        // local_accounts in API is an array of user objects; accept that directly
        let local_accounts: [LocalUser]?
        let user_inventories: UserInventories?

        struct LocalUser: Decodable {
            let name: String?
            let realname: String?
            let uid: String?
            let home: String?
            let home_size: String?
            let home_size_mb: Int?
            let administrator: Bool?
            let filevault_enabled: Bool?
        }

        struct UserInventories: Decodable {
            let disable_automatic_login: Bool?
        }
    }
    
    struct ConfigurationProfiles: Decodable {
        // API may return either an array of profile objects or an object with metadata.
        let profiles: [Profile]?
        let size: String?

        struct Profile: Decodable {
            let id: Int?
            let name: String?
            let uuid: String?
            let is_removable: Bool?
        }

        init(from decoder: Decoder) throws {
            // First try to decode as an array of Profile objects
            if let single = try? decoder.singleValueContainer(),
               let arr = try? single.decode([Profile].self) {
                profiles = arr
                size = nil
                return
            }

            // Otherwise try to decode as an object with a size field (and possibly items in other formats)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            size = try? container.decodeIfPresent(String.self, forKey: .size)
            // If there is an "items" or similarly-named array it can be decoded here if needed.
            profiles = nil
        }

        enum CodingKeys: String, CodingKey {
            case size
        }
    }
    struct IPhones: Decodable {
        let items: [String]?
        let size: String?

        init(from decoder: Decoder) throws {
            let single = try? decoder.singleValueContainer()
            if let arr = try? single?.decode([String].self) {
                items = arr
                size = nil
                return
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            size = try? container.decodeIfPresent(String.self, forKey: .size)
            items = nil
        }

        enum CodingKeys: String, CodingKey {
            case size
        }
    }
    
    struct Security: Decodable {
        let activationLock: Bool?
        // other possible fields can be added as needed

        enum CodingKeys: String, CodingKey {
            case activation_lock = "activation_lock"
            case activationLock = "activationLock"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            activationLock = (try? container.decodeIfPresent(Bool.self, forKey: .activation_lock)) ?? (try? container.decodeIfPresent(Bool.self, forKey: .activationLock))
        }
    }
}
