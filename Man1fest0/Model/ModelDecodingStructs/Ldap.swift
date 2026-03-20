//
//  Ldap.swift
//  Man1fest0
//
//  Created by Amos Deane on 14/08/2024.
//

import Foundation

// MARK: - LDAP
struct LDAPServers: Codable {
    let ldapServers: [LDAPServer]

    enum CodingKeys: String, CodingKey {
        case ldapServers = "ldap_servers"
    }
}

// MARK: - LDAPServer
struct LDAPServer: Codable, Hashable {
    let id: Int
    let name: String
}

// MARK: - Welcome
struct LDAPGroups: Codable {
    let ldapGroups: [LDAPGroup]

    enum CodingKeys: String, CodingKey {
        case ldapGroups = "ldap_groups"
    }
}

// MARK: - LDAPGroup
struct LDAPGroup: Codable, Hashable {
    let uid, groupname: String
}


struct LDAPCombined: Codable, Hashable {
    let uuid, name,distinguishedName, ldapServerId: String
}


// MARK: - LDAPSearchResponse
struct LDAPSearchResponse: Codable {
    let totalCount: Int
//    let ldapCustomGroup: [LDAPCustomGroup]
    let results: [LDAPCustomGroup]
}

// MARK: - LDAPCustomGroup
struct LDAPCustomGroup: Codable, Hashable {
    let uuid: String
    let ldapServerID: Int
    let id, name, distinguishedName: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case ldapServerID = "ldapServerId"
        case id, name, distinguishedName
    }
}
