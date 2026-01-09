// MARK: - APIRequest

struct APIRequest<Result: Decodable>: Sendable {
    let endpoint: String
    let method: HTTPMethod
}
