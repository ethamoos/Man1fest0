// Lightweight decoding structs for computer detailed API responses used by UI
import Foundation

struct ComputerDetailedResponse: Decodable {
    let computer: ComputerSlim

    enum CodingKeys: String, CodingKey {
        case computer = "computer"
    }
}

struct ComputerSlim: Decodable {
    // Use the "general" container returned by Jamf's computer detail JSON
    let general: General

    struct General: Decodable {
        let id: String
        let name: String?
        let udid: String?
        let serial_number: String?
        let model: String?
        let username: String?
        let department: String?
        let building: String?
        let report_date_utc: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case udid
            case serial_number
            case model
            case username
            case department
            case building
            case report_date_utc
        }

        // Custom decoding to accept id as either String or numeric types
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // id may be a String or a Number in different Jamf versions / endpoints
            if let idString = try? container.decode(String.self, forKey: .id) {
                self.id = idString
            } else if let idInt = try? container.decode(Int.self, forKey: .id) {
                self.id = String(idInt)
            } else if let idDouble = try? container.decode(Double.self, forKey: .id) {
                // If it's a double, remove any .0 trailing when converting
                let intVal = Int(idDouble)
                if Double(intVal) == idDouble {
                    self.id = String(intVal)
                } else {
                    self.id = String(idDouble)
                }
            } else {
                // Fallback: try decoding as String via a loss-tolerant decode
                let raw = try container.decodeIfPresent(String.self, forKey: .id)
                self.id = raw ?? ""
            }

            // Decode the rest of the fields safely
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.udid = try container.decodeIfPresent(String.self, forKey: .udid)
            self.serial_number = try container.decodeIfPresent(String.self, forKey: .serial_number)
            self.model = try container.decodeIfPresent(String.self, forKey: .model)
            self.username = try container.decodeIfPresent(String.self, forKey: .username)
            self.department = try container.decodeIfPresent(String.self, forKey: .department)
            self.building = try container.decodeIfPresent(String.self, forKey: .building)
            self.report_date_utc = try container.decodeIfPresent(String.self, forKey: .report_date_utc)
        }
    }
}
