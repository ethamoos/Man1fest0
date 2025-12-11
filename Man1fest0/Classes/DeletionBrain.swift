import Foundation
import SwiftUI
import AEXML

@MainActor
class DeletionBrain: ObservableObject {
    weak var net: NetBrain?

    init(net: NetBrain?) {
        self.net = net
    }

    // Move of selected delete functions from NetBrain (proof-of-concept copies).

    func deleteComputer(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        guard let net = net else { return }
        let resourcePath = getURLFormat(data: resourceType)

        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            net.separationLine()
            print("[DeletionBrain] Running deleteComputer - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            net.requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            net.appendStatus("Connecting to \(url)...")
            print("deleteComputer has finished")
            print("Set processingComplete to true")
            net.processingComplete = true
            print(String(describing: net.processingComplete))
        }
    }

    func deleteConfigProfile(server: String,authToken: String, resourceType: ResourceType, itemID: String) {
        guard let net = net else { return }
        let resourcePath = getURLFormat(data: ResourceType.configProfileDetailedMacOS)

        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            net.separationLine()
            print("[DeletionBrain] Running delete config profile - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            net.requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            net.appendStatus("Connecting to \(url)...")

            print("deleteConfigProfile has finished")
            print("Set processingComplete to true")
            net.processingComplete = true
            print(String(describing: net.processingComplete))
        }
    }

    func deletePackage(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        guard let net = net else { return }
        print("[DeletionBrain] Running deletePackage for item\(itemID)")
        let resourcePath = getURLFormat(data: resourceType)

        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            net.separationLine()
            print("Running delete package function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            print("itemID is set as:\(itemID)")
            net.requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            net.appendStatus("Connecting to \(url)...")
        }
    }

    func deletePolicy(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        guard let net = net else { return }
        let resourcePath = getURLFormat(data: resourceType)
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            net.separationLine()
            print("Running deletePolicy function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            net.requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            print("deletePolicy has finished for:\(itemID)")
            print("Set processingComplete to true")
            net.processingComplete = true
            print(String(describing: net.processingComplete))
        }
    }

    func deleteScript(server: String,resourceType: ResourceType, itemID: String, authToken: String) async throws {
        guard let net = net else { return }
        let resourcePath = getURLFormat(data: resourceType)

        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            net.separationLine()
            print("Running delete script function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")

            do {
                try await net.requestDeleteXML(url: url, authToken: authToken, resourceType: resourceType)
            } catch {
                throw JamfAPIError.badURL
            }

            print("deleteScript has finished")
        }
    }
}
