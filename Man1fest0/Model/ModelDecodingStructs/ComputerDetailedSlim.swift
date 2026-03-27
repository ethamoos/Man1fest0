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
    }
}
