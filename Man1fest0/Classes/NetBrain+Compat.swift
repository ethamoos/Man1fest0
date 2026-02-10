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
}
