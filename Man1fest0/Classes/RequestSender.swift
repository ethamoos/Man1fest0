import Foundation

// MARK: - RequestSender

final class RequestSender {

    // MARK: Properties

    private let server: String
    private let authToken: String
    private let decoder = JSONDecoder()

    // MARK: Init

    init(server: String, authToken: String) {
        self.server = server
        self.authToken = authToken
    }

    // Ensure the server string includes a scheme. If not, default to https://
    private var normalizedServer: String {
        if server.contains("://") {
            return server.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "https://" + server.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    // MARK: Request

    // Convenience wrapper used by callers that build an APIRequest<Result>
    func resultFor<APIModel: Decodable>(apiRequest: APIRequest<APIModel>) async throws -> APIModel {
        return try await resultFor(endpoint: apiRequest.endpoint, httpMethod: apiRequest.method, as: APIModel.self)
    }

    func resultFor<APIModel: Decodable>(
        endpoint: String,
        httpMethod: HTTPMethod,
        as modelType: APIModel.Type
    ) async throws -> APIModel {
        // make a URL request and configure
        let jamfURLQuery = normalizedServer + "/JSSResource/\(endpoint)"
        guard let url = URL(string: jamfURLQuery) else {
            print("Invalid URL constructed: \(jamfURLQuery)")
            throw NetBrain.NetError.badResponseCode
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.stringValue
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug logs for request
        let maskedTokenInfo = "(present) length=\(authToken.count)"
        print("RequestSender: requesting \(request.httpMethod ?? "") \(url.absoluteString)")
        print("RequestSender: authToken \(maskedTokenInfo)")

        // send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResp = response as? HTTPURLResponse {
            print("Response status code: \(httpResp.statusCode)")
            if httpResp.statusCode != 200 {
                // Try to print server body for debugging
                if let body = String(data: data, encoding: .utf8) {
                    print("Response body (non-200): \n\(body)")
                } else {
                    print("Response body (non-200): <binary data of length \(data.count)>")
                }
                throw NetBrain.NetError.badResponseCode
            }
        } else {
            print("Non-HTTP response received: \(String(describing: response))")
            throw NetBrain.NetError.badResponseCode
        }

        // decode the request result as APIModel
        do {
            return try decoder.decode(APIModel.self, from: data)
        } catch {
            // Print decoding failure and response body to help debug mismatches
            if let str = String(data: data, encoding: .utf8) {
                print("Decoding error: \(error). Response body:\n\(str)")
            } else {
                print("Decoding error: \(error). Response data length: \(data.count)")
            }
            throw error
        }
    }
}
