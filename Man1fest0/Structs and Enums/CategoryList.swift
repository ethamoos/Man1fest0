// ...existing code...
import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct AllCategories: Codable {
    let categories: [Category]
}
// ...existing code...
