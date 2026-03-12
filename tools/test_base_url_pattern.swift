import Foundation

// Quick local test harness for the RequestSender.BaseURLPattern string building logic
// This doesn't depend on the app code; we replicate the enum logic to test join behavior.

enum BaseURLPatternLocal {
    case jssResource
    case api(version: Int)
    case full(URL)

    func buildURLString(normalizedServer: String, endpoint: String) -> String {
        switch self {
        case .full(let url): return url.absoluteString
        case .jssResource: return join(server: normalizedServer, path: "/JSSResource/", endpoint: endpoint)
        case .api(let version): return join(server: normalizedServer, path: "/api/v\(version)/", endpoint: endpoint)
        }
    }

    private func join(server: String, path: String, endpoint: String) -> String {
        let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmedEndpoint.isEmpty {
            return "\(trimmedServer)/\(trimmedPath)"
        } else {
            return "\(trimmedServer)/\(trimmedPath)/\(trimmedEndpoint)"
        }
    }
}

let server = "https://myserver.jamfcloud.com/"
let endpoints = ["packages", "scripts?page=0&page-size=500", "policies/id/123"]

for ep in endpoints {
    let p1 = BaseURLPatternLocal.jssResource.buildURLString(normalizedServer: server, endpoint: ep)
    let p2 = BaseURLPatternLocal.api(version: 1).buildURLString(normalizedServer: server, endpoint: ep)
    let p3 = BaseURLPatternLocal.full(URL(string: "https://custom.example.com/api/")!).buildURLString(normalizedServer: server, endpoint: ep)
    print("endpoint=\(ep)")
    print("  jssResource -> \(p1)")
    print("  api v1      -> \(p2)")
    print("  full        -> \(p3)")
}
