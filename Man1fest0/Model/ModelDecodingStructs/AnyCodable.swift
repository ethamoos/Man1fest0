import Foundation

// Minimal AnyCodable for decoding heterogeneous arrays/objects returned by the API.
// Only implements Decodable (we don't need Encodable here).
struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
            return
        }

        if let intVal = try? container.decode(Int.self) {
            self.value = intVal
            return
        }

        if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
            return
        }

        if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
            return
        }

        if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
            return
        }

        if let arr = try? container.decode([AnyCodable].self) {
            self.value = arr.map { $0.value }
            return
        }

        if let dict = try? container.decode([String: AnyCodable].self) {
            var d: [String: Any] = [:]
            for (k, v) in dict {
                d[k] = v.value
            }
            self.value = d
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
    }
}
