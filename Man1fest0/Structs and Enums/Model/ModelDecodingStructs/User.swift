import Foundation

// Models for /JSSResource/users (XML list) and /JSSResource/users/id/<id> (detailed JSON)

// List response: <users> -> { users: [ { id, name } ] }
struct UserListResponse: Codable {
    let users: [UserSimple]
}

struct UserSimple: Codable, Hashable, Identifiable {
    // keep an internal UUID for SwiftUI identity, but expose Jamf id via `jamfId`
    var id = UUID()
    let jamfId: Int?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case jamfId = "id"
        case name = "name"
    }
}

// Detailed user JSON example -> { "user": { ... } }
struct UserDetailResponse: Codable {
    let user: UserDetail
}

struct UserDetail: Codable, Hashable, Identifiable {
    let id: Int
    let name: String?
    let full_name: String?
    let email: String?
    let email_address: String?
    let phone_number: String?
    let position: String?
    let managed_apple_id: String?
    let enable_custom_photo_url: Bool?
    let custom_photo_url: String?
    let ldap_server: LdapServer?
    let extension_attributes: [ExtensionAttribute]?    // was [String]?
    let sites: [SiteRef]?                                // was [String]?
    let links: UserLinks?
    let user_groups: SizeObject?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case full_name = "full_name"
        case email = "email"
        case email_address = "email_address"
        case phone_number = "phone_number"
        case position = "position"
        case managed_apple_id = "managed_apple_id"
        case enable_custom_photo_url = "enable_custom_photo_url"
        case custom_photo_url = "custom_photo_url"
        case ldap_server = "ldap_server"
        case extension_attributes = "extension_attributes"
        case sites = "sites"
        case links = "links"
        case user_groups = "user_groups"
    }

    struct LdapServer: Codable, Hashable {
        let id: Int?
        let name: String?
    }

    // Represent simple id/name references returned for computers, peripherals, etc.
    struct ResourceRef: Codable, Hashable {
        let id: Int?
        let name: String?
    }

    struct ExtensionAttribute: Codable, Hashable {
        // Jamf extension attributes vary; include common fields
        let id: Int?
        let name: String?
        let value: String?
    }

    struct SiteRef: Codable, Hashable {
        let id: Int?
        let name: String?
    }

    struct UserLinks: Codable, Hashable {
        let computers: [ResourceRef]?
        let peripherals: [ResourceRef]?
        let mobile_devices: [ResourceRef]?
        let vpp_assignments: [ResourceRef]?
        let total_vpp_code_count: Int?
    }

    struct SizeObject: Codable, Hashable {
        let size: Int?
    }
}
