import Foundation
import SwiftUI

@MainActor extension NetBrain {
    // Create a building (if not already present in compatibility file)
    func createBuildingIfNeeded(name: String, server: String, authToken: String) {
        // Some views call createBuilding(name:server:authToken:). Provide a thin wrapper.
        createBuilding(name: name, server: server, authToken: authToken)
    }

    // Delete a configuration profile (compat wrapper) - non-throwing variant used by Views
    func deleteConfigProfile(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        appendStatus("deleteConfigProfile (compat2): deleting id:\(itemID)")
        Task {
            do {
                try await deleteResource(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
                appendStatus("deleteConfigProfile (compat2): deleted id:\(itemID)")
            } catch {
                appendStatus("deleteConfigProfile (compat2): failed id:\(itemID) error:\(error)")
            }
        }
    }

    // Batch delete scripts (non-throwing wrapper to satisfy older call sites that expect async but call from Task)
    func batchDeleteScripts(selection: Set<Script>, server: String, authToken: String, resourceType: ResourceType) {
        appendStatus("batchDeleteScripts (compat2): deleting \(selection.count) scripts")
        Task {
            for s in selection {
                let id = String(describing: s.jamfId ?? 0)
                do {
                    try await deleteScript(server: server, resourceType: resourceType, itemID: id, authToken: authToken)
                    appendStatus("batchDeleteScripts: deleted script id:\(id)")
                } catch {
                    appendStatus("batchDeleteScripts: failed delete id:\(id) error:\(error)")
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async { self.appendStatus("batchDeleteScripts: completed") }
        }
    }

    // createNewPolicy compatibility wrapper - lightweight stub to avoid missing symbol errors
    func createNewPolicy(server: String, authToken: String, policyName: String, customTrigger: String, categoryID: String, category: String, departmentID: String, department: String, scriptID: String, scriptName: String, scriptParameter4: String, scriptParameter5: String, scriptParameter6: String, resourceType: ResourceType, notificationName: String, notificationStatus: String) {
        appendStatus("createNewPolicy (compat2): requested for policy \(policyName)")
        // This is a stubbed compatibility method. The real creation flow relies on XmlBrain and specialized XML generation.
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            appendStatus("createNewPolicy (compat2): stub completed for \(policyName)")
        }
    }
}
