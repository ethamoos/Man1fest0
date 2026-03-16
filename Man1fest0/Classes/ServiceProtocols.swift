// Service protocols and lightweight conformances for incremental refactor
// Created to provide protocol abstractions for NetBrain / XmlBrain / PolicyBrain

import Foundation
import AEXML

// NetworkServiceProtocol mirrors a small, useful subset of NetBrain's API so callers can
// depend on the protocol instead of the concrete type during migration.
protocol NetworkServiceProtocol: AnyObject {
    var authToken: String { get }

    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String)
    func sendRequestAsXMLAsync(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) async throws
    func sendRequestAsXMLAsyncID(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String, policyID: String) async throws
    func sendRequestAsJson(url: URL, authToken: String, resourceType: ResourceType, httpMethod: String, parameters: String)
}

// XmlServiceProtocol exposes a compact surface of XmlBrain useful to callers that
// need XML parsing/building and policy XML fetch helpers.
protocol XmlServiceProtocol: AnyObject {
    func readXMLDataFromString(_ xmlContent: String)
    func readXMLDataFromStringXmlBrain(_ xmlContent: String)

    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String)

    func getPolicyAsXMLaSync(server: String, policyID: Int, authToken: String) async throws -> String
    func getPolicyAsXML(server: String, policyID: Int, authToken: String)
    func getPolicyAsXMLAwait(server: String, authToken: String, policyID: String) async throws
}

// PolicyServiceProtocol is a minimal protocol allowing views or other services to
// depend on a policy-oriented interface implemented by PolicyBrain during migration.
protocol PolicyServiceProtocol: AnyObject {
    func readXMLDataFromString(_ xmlContent: String)
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String)
    func postNewPolicy(server: String, authToken: String, xml: String)
}

// MARK: - Conform existing types to the protocols (no behaviour changes)
// These empty extensions declare conformance; methods already exist on the types
// so no additional forwarding is necessary. This enables incremental refactors
// where callers can be updated to use the protocol types.

extension NetBrain: NetworkServiceProtocol {}
extension XmlBrain: XmlServiceProtocol {}
extension PolicyBrain: PolicyServiceProtocol {}

// Helper: return auth token using the protocol (keeps call sites simple)
func networkAuthToken(_ net: NetBrain) -> String {
    // Cast to the protocol to illustrate protocol usage; NetBrain already conforms
    let svc = net as NetworkServiceProtocol
    return svc.authToken
}
