import Foundation
import AEXML

struct XMLNetworking {
    static func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) {
        let xmldata = xml.data(using: .utf8)
        let headers = ["Accept": "application/xml", "Content-Type": "application/xml", "Authorization": "Bearer \(authToken)"]
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = httpMethod
        request.httpBody = xmldata

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                print("Doing processing of XMLNetworking.sendRequestAsXML:\(httpMethod)")
                print("Data is:\(data)")
                print("Response is:\(response)")
            } else {
                print("Error encountered in XMLNetworking.sendRequestAsXML")
                if let err = error { print(err) }
            }
        }
        dataTask.resume()
    }

    static func sendRequestAsXMLAsync(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) async throws {
        let xmldata = xml.data(using: .utf8)
        let headers = ["Accept": "application/xml", "Content-Type": "application/xml", "Authorization": "Bearer \(authToken)"]
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = httpMethod
        request.httpBody = xmldata

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            print("XMLNetworking.sendRequestAsXMLAsync non-200: \(status)")
            throw JamfAPIError.http(status)
        }
    }
}
