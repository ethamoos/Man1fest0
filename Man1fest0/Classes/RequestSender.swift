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

    // MARK: Errors

    enum RequestError: LocalizedError {
        case invalidURL(String)
        case unauthorized
        case forbidden
        case notFound
        case serverError(statusCode: Int, body: String?)
        case unexpectedStatus(statusCode: Int, body: String?)
        case network(Error)
        case decoding(Error, body: String?)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let url):
                return "Invalid server URL: \(url). Check your server setting and include the scheme (https://)."
            case .unauthorized:
                return "Authentication failed. Please check your username/password and try again."
            case .forbidden:
                return "You don't have permission to perform that operation. Please check your account privileges."
            case .notFound:
                return "The requested resource was not found on the server."
            case .serverError(let code, let body):
                var msg = "Server error (HTTP \(code))."
                if let body = body, !body.isEmpty { msg += " Response: \(body)" }
                return msg
            case .unexpectedStatus(let code, let body):
                var msg = "Unexpected response from server (HTTP \(code))."
                if let body = body, !body.isEmpty { msg += " Response: \(body)" }
                return msg
            case .network(let err):
                return "Network error: \(err.localizedDescription)"
            case .decoding(let err, let body):
                var msg = "Failed to decode server response: \(err.localizedDescription)."
                if let body = body, !body.isEmpty { msg += " Response body: \(body)" }
                return msg
            }
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
            throw RequestError.invalidURL(jamfURLQuery)
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.stringValue
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Debug logs for request
        let maskedTokenInfo = authToken.isEmpty ? "(none)" : "(present) length=\(authToken.count)"
        print("RequestSender: requesting \(request.httpMethod ?? "") \(url.absoluteString)")
        print("RequestSender: authToken \(maskedTokenInfo)")

        // send the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResp = response as? HTTPURLResponse else {
                print("Non-HTTP response received: \(String(describing: response))")
                throw RequestError.unexpectedStatus(statusCode: -1, body: nil)
            }

            let status = httpResp.statusCode
            // Try to capture response body (safely convert to string)
            let bodyString = String(data: data, encoding: .utf8)

            print("Response status code: \(status)")
            if status == 200 {
                // decode the request result as APIModel
                do {
                    return try decoder.decode(APIModel.self, from: data)
                } catch {
                    // provide body to help debugging
                    print("Decoding error: \(error). Response body: \(bodyString ?? "<binary>")")
                    throw RequestError.decoding(error, body: bodyString)
                }
            }

            // Handle common HTTP status codes with descriptive errors
            switch status {
            case 401:
                print("401 Unauthorized. Response body: \(bodyString ?? "")")
                throw RequestError.unauthorized
            case 403:
                print("403 Forbidden. Response body: \(bodyString ?? "")")
                throw RequestError.forbidden
            case 404:
                print("404 Not Found. Response body: \(bodyString ?? "")")
                throw RequestError.notFound
            case 500...599:
                print("Server error \(status). Response body: \(bodyString ?? "")")
                throw RequestError.serverError(statusCode: status, body: bodyString)
            default:
                print("Unexpected status \(status). Response body: \(bodyString ?? "")")
                throw RequestError.unexpectedStatus(statusCode: status, body: bodyString)
            }

        } catch let reqErr as RequestError {
            throw reqErr
        } catch let urlErr as URLError {
            print("Network URLError: \(urlErr)")
            throw RequestError.network(urlErr)
        } catch {
            print("Unexpected networking error: \(error)")
            throw RequestError.network(error)
        }
    }
}
