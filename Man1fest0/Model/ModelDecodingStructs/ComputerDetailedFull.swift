// Minimal full computer detail decoding structs for UI use
import Foundation

// Matches Jamf's 'computers/id/<id>' JSON which contains a top-level "computer" object
struct ComputerDetailedFullResponse: Decodable {
    let computer: ComputerFull
}

struct ComputerFull: Decodable {
    let general: General?
    let hardware: Hardware?
    let security: Security?
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
        let department: String?
        let building: String?
        let report_date_utc: String?

        enum CodingKeys: String, CodingKey {
            case id, name, udid
            case serial_number = "serial_number"
            case model, username, department, building, ip_address
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
            department = try? container.decodeIfPresent(String.self, forKey: .department)
            building = try? container.decodeIfPresent(String.self, forKey: .building)
            report_date_utc = try? container.decodeIfPresent(String.self, forKey: .report_date_utc)
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

    struct Security: Decodable {
        let activationLock: String?
        // other possible fields can be added as needed

        enum CodingKeys: String, CodingKey {
            case activation_lock = "activation_lock"
            case activationLock = "activationLock"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            activationLock = (try? container.decodeIfPresent(String.self, forKey: .activation_lock)) ?? (try? container.decodeIfPresent(String.self, forKey: .activationLock))
        }
    }
}
