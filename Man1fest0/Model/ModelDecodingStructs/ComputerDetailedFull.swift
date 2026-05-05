// Minimal full computer detail decoding structs for UI use
import Foundation

// Matches Jamf's 'computers/id/<id>' JSON which contains a top-level "computer" object
struct ComputerDetailedFullResponse: Decodable {
    let computer: ComputerFull
}

struct ComputerFull: Decodable {
    let general: General?
    let location: Location?
    let hardware: Hardware?
    let security: Security?
    let software: Software?
    let extension_attributes: ExtensionAttributes?
    let group_accounts: GroupAccounts?
    let configuration_profiles: ConfigurationProfiles?
    let iphones: IPhones?
    // keep extensionAttributes optional in case it's present
    // let extensionAttributes: ExtensionAttributes?
    
    struct General: Decodable {
        let id: String
        let name: String?
        let udid: String?
        let serial_number: String?
        let ip_address: String?
        let model: String?
        let username: String?
        let report_date_utc: String?
        
        enum CodingKeys: String, CodingKey {
            case id, name, udid
            case serial_number = "serial_number"
            case model, username, ip_address
            case report_date_utc = "report_date_utc"
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
    
    struct ExtensionAttributes: Decodable {
        let extension_attribute: [ExtensionAttribute]?

        struct ExtensionAttribute: Decodable {
            let id: String?
            let name: String?
            let type: String?
            let multi_value: Bool?
            let value: String?
        }

        init(from decoder: Decoder) throws {
            // Accept either an array at the top level or an object with key "extension_attribute"
            let container = try decoder.singleValueContainer()
            if let arr = try? container.decode([ExtensionAttribute].self) {
                extension_attribute = arr
                return
            }
            // try object with key
            let obj = try decoder.container(keyedBy: CodingKeys.self)
            extension_attribute = try? obj.decodeIfPresent([ExtensionAttribute].self, forKey: .extension_attribute)
        }

        enum CodingKeys: String, CodingKey {
            case extension_attribute
        }
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
        // API may return an array or an object with size; accept either
        let items: [String]?
        let size: String?

        init(from decoder: Decoder) throws {
            // try array
            let single = try? decoder.singleValueContainer()
            if let arr = try? single?.decode([String].self) {
                items = arr
                size = nil
                return
            }
            // try object with size
            let container = try decoder.container(keyedBy: CodingKeys.self)
            size = try? container.decodeIfPresent(String.self, forKey: .size)
            items = nil
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

    enum CodingKeys: String, CodingKey {
        case general, location, hardware, security, software, extension_attributes, group_accounts = "groups_accounts", configuration_profiles, iphones
    }
}
