import Foundation
import SwiftUI

@MainActor extension NetBrain {
    // Backwards-compatible alias for separation line used by older call sites
    func atSeparationLine() {
        separationLine()
    }

    // Convenience overload: allow callers to omit authToken and use stored token
    func getAllPackages(server: String) async throws {
        try await getAllPackages(server: server, authToken: self.authToken)
    }

    // Generic async delete helper for resources referenced by Views (scripts, groups, etc.)
    func deleteResource(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        guard let base = URL(string: server) else { throw JamfAPIError.badURL }
        let resourcePath = getURLFormat(data: resourceType)
        let url = base.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
        try await requestDeleteAwait(url: url, authToken: authToken, resourceType: resourceType)
    }

    // deleteScript compatibility wrapper used by Views
    func deleteScript(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        try await deleteResource(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }

    // deleteGroup compatibility wrapper
    func deleteGroup(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        try await deleteResource(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }

    // Batch delete for ComputerGroup selection (async, used by some Views)
    func batchDeleteGroup(selection: Set<ComputerGroup>, server: String, authToken: String, resourceType: ResourceType) async throws {
        appendStatus("batchDeleteGroup: deleting \(selection.count) groups")
        for g in selection {
            let id = String(describing: g.id)
            do {
                try await deleteGroup(server: server, resourceType: resourceType, itemID: id, authToken: authToken)
                appendStatus("batchDeleteGroup: deleted group id:\(id)")
            } catch {
                appendStatus("batchDeleteGroup: failed delete id:\(id) error:\(error)")
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        DispatchQueue.main.async { self.appendStatus("batchDeleteGroup: completed") }
    }

    // Update a single computer's name (compat wrapper for older call sites)
    func updateComputerName(server: String, authToken: String, resourceType: ResourceType, computerName: String, computerID: String) {
        Task {
            let jamfURLQuery = server + "/JSSResource/computers/id/" + computerID
            guard let url = URL(string: jamfURLQuery) else { appendStatus("updateComputerName: bad URL: \(jamfURLQuery)"); return }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if !authToken.isEmpty { request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization") }
            else if !self.authToken.isEmpty { request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization") }

            let body: [String: Any] = ["computer": ["general": ["name": computerName]]]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                let (_, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                appendStatus("updateComputerName: updated computer id:\(computerID) status:\(status)")
            } catch {
                appendStatus("updateComputerName: failed id:\(computerID) error:\(error)")
            }
        }
    }

    // Scope helpers - minimal implementations that log actions and return quickly
    func scopeAllComputers(server: String, authToken: String, policyID: String) {
        appendStatus("scopeAllComputers: requested for policy id:\(policyID)")
        Task {
            // In a real implementation we'd craft XML and call sendRequestAsXMLAsyncID
            try? await Task.sleep(nanoseconds: 100_000_000)
            appendStatus("scopeAllComputers: (stub) completed for id:\(policyID)")
        }
    }

    func scopeAllUsers(server: String, authToken: String, policyID: String) {
        appendStatus("scopeAllUsers: requested for policy id:\(policyID)")
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            appendStatus("scopeAllUsers: (stub) completed for id:\(policyID)")
        }
    }

    func clearScope(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        appendStatus("clearScope: requested for policy id:\(policyID)")
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            appendStatus("clearScope: (stub) completed for id:\(policyID)")
        }
    }

    // Batch update category - compatibility wrapper
    func processBatchUpdateCategory(selection: [Int?], server: String, resourceType: ResourceType, authToken: String, newCategoryName: String, newCategoryID: String) {
        appendStatus("processBatchUpdateCategory: starting for \(selection.count) items -> category:\(newCategoryName) id:\(newCategoryID)")
        Task {
            for maybeId in selection {
                guard let id = maybeId else { continue }
                // Call the generic updateCategory wrapper to perform update per-item
                updateCategory(server: server, authToken: authToken, resourceType: resourceType, categoryID: newCategoryID, categoryName: newCategoryName, updatePressed: true, resourceID: String(describing: id))
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async {
                self.appendStatus("processBatchUpdateCategory: completed for \(selection.count) items")
            }
        }
    }

    // Update category wrapper used by multiple Views; performs a simple PUT and logs result.
    func updateCategory(server: String, authToken: String, resourceType: ResourceType, categoryID: String, categoryName: String, updatePressed: Bool, resourceID: String) {
        Task {
            appendStatus("updateCategory: updating resource id:\(resourceID) -> category:\(categoryName) (id:\(categoryID))")
            guard let base = URL(string: server) else { appendStatus("updateCategory: bad server URL"); return }
            let resourcePath = getURLFormat(data: resourceType)
            let url = base.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(resourceID)

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if !authToken.isEmpty { request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization") }
            else if !self.authToken.isEmpty { request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization") }

            // Construct a minimal payload. Different Jamf resources expect different shapes; this is a best-effort stub.
            let payload: [String: Any] = ["category": ["id": categoryID, "name": categoryName]]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
                let (_, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                appendStatus("updateCategory: completed id:\(resourceID) status:\(status)")
            } catch {
                appendStatus("updateCategory: failed id:\(resourceID) error:\(error)")
            }
        }
    }
}
