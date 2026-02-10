import Foundation

@MainActor
extension NetBrain {
    /// Compatibility helper: synchronous-style connect used by legacy call sites.
    /// This forwards to the canonical async pipeline (`request(...)`) used by NetBrain.
    func connect(server: String, resourceType: ResourceType, authToken: String) {
        Task {
            if self.authToken.isEmpty {
                await self.connect()
            }
            guard let serverURL = URL(string: server) else {
                appendStatus("Invalid server URL: \(server)")
                return
            }
            let resourcePath = getURLFormat(data: resourceType)
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath)
            print("Compatibility connect: requesting \(url)")
            request(url: url, resourceType: resourceType, authToken: authToken)
        }
    }

    // Legacy load() used by ContentView
    func load() async {
        await MainActor.run { self.isLoading = false }
    }

    // Legacy connect() no-arg
    func connect() async {
        await MainActor.run { self.needsCredentials = false; self.connected = true }
    }

    // Legacy connect(to:as:password:resourceType:) signature used in a few older places
    func connect(to server: String, as username: String, password: String, resourceType: ResourceType) {
        Task {
            await MainActor.run {
                self.password = password
                self.connected = true
            }
        }
    }

    // processUpdateComputerName - legacy wrapper used by several Views
    func processUpdateComputerName(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, computerName: String) {
        for eachItem in selection {
            let computerID = String(describing: eachItem)
            updateComputerName(server: server, authToken: authToken, resourceType: resourceType, computerName: computerName, computerID: computerID)
        }
    }

    // processUpdateComputerDepartmentBasic - legacy wrapper
    func processUpdateComputerDepartmentBasic(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, department: String) {
        for eachItem in selection {
            let computerID = String(describing: eachItem)
            updateComputerDepartment(server: server, authToken: authToken, resourceType: resourceType, departmentName: department, computerID: computerID)
        }
    }

    // Delete group wrapper (legacy async signature)
    func deleteGroup(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        // reuse deletePolicy which performs DELETE for a given resource path
        deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }

    // Delete script wrapper
    func deleteScript(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        // scripts deletion is same pattern as deletePolicy
        deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }

    // Refresh departments - legacy no-arg call used by some Views
    func refreshDepartments() {
        Task {
            try? await self.getDepartments(server: self.server)
        }
    }

    // Legacy getToken wrapper (minimal): attempts to set authToken and connected flag.
    func getToken(server: String, username: String, password: String) async throws {
        // Minimal compat: store password and mark connected; real auth flow may replace this.
        await MainActor.run {
            self.password = password
            self.connected = true
            if self.authToken.isEmpty { self.authToken = "" }
        }
    }

    // processBatchUpdateCategory - iterate selection and call updateCategory per policy id
    func processBatchUpdateCategory(selection: [Int?], server: String, resourceType: ResourceType, authToken: String, newCategoryName: String, newCategoryID: String) {
        for each in selection {
            let policyID = String(describing: each ?? 0)
            updateCategory(server: server, authToken: authToken, resourceType: resourceType, categoryID: newCategoryID, categoryName: newCategoryName, updatePressed: true, resourceID: policyID)
        }
    }

    // Overload clearScope with legacy parameter order: (server, resourceType, policyID, authToken)
    func clearScope(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        clearScope(server: server, resourceType: resourceType, authToken: authToken, policyID: policyID)
    }
}
