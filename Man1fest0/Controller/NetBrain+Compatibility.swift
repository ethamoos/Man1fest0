import Foundation

@MainActor
extension NetBrain {
    /// Backwards-compatible alias: some views call `updateComputerLocationUsername`.
    /// This thin wrapper delegates to the existing `updateComputerUsername` implementation.
    func updateComputerLocationUsername(server: String, authToken: String, resourceType: ResourceType, computerID: String, newUsername: String) {
        updateComputerUsername(server: server, authToken: authToken, resourceType: resourceType, computerID: computerID, newUsername: newUsername)
    }
}
