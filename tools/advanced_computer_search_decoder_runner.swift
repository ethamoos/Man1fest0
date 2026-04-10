import Foundation

// Re-declare the minimal model structs to allow standalone decoding tests in a script.

struct ComputerSearches: Codable {
    let advancedComputerSearches: AdvancedComputerSearchesContainer

    enum CodingKeys: String, CodingKey {
        case advancedComputerSearches = "advanced_computer_searches"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // First, try the canonical object form
        if let obj = try? container.decode(AdvancedComputerSearchesContainer.self, forKey: .advancedComputerSearches) {
            self.advancedComputerSearches = obj
            return
        }

        // If that fails, try if the key maps directly to an array of searches
        if let arr = try? container.decode([AdvancedComputerSearch].self, forKey: .advancedComputerSearches) {
            self.advancedComputerSearches = AdvancedComputerSearchesContainer(size: arr.count, advancedComputerSearch: arr)
            return
        }

        // If neither worked, throw a helpful decoding error
        let context = DecodingError.Context(codingPath: [CodingKeys.advancedComputerSearches], debugDescription: "Expected advanced_computer_searches to be either an object or an array")
        throw DecodingError.typeMismatch(AdvancedComputerSearchesContainer.self, context)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(advancedComputerSearches, forKey: .advancedComputerSearches)
    }
}

struct AdvancedComputerSearchesContainer: Codable {
    var size: Int?
    var advancedComputerSearch: [AdvancedComputerSearch]

    enum CodingKeys: String, CodingKey {
        case size
        case advancedComputerSearch = "advanced_computer_search"
    }

    init(size: Int? = nil, advancedComputerSearch: [AdvancedComputerSearch]) {
        self.size = size
        self.advancedComputerSearch = advancedComputerSearch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // size is optional
        let size = try? container.decodeIfPresent(Int.self, forKey: .size)

        // advanced_computer_search might be an array or a single object
        if let arr = try? container.decode([AdvancedComputerSearch].self, forKey: .advancedComputerSearch) {
            self.advancedComputerSearch = arr
            self.size = size
            return
        }

        if let single = try? container.decode(AdvancedComputerSearch.self, forKey: .advancedComputerSearch) {
            self.advancedComputerSearch = [single]
            self.size = size ?? 1
            return
        }

        // If neither present, it might be that the decoder was handed an array directly.
        // Try decoding a top-level array from the underlying container.
        let singleContainer = try decoder.singleValueContainer()
        if let arr = try? singleContainer.decode([AdvancedComputerSearch].self) {
            self.advancedComputerSearch = arr
            self.size = arr.count
            return
        }

        // Nothing matched
        let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode advanced_computer_search(es)")
        throw DecodingError.typeMismatch([AdvancedComputerSearch].self, context)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encode(advancedComputerSearch, forKey: .advancedComputerSearch)
    }
}

struct AdvancedComputerSearch: Codable, Identifiable, Hashable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

// Now run decoding tests
let decoder = JSONDecoder()
let jsonVariants: [(String, String)] = [
    ("object_form", "{ \"advanced_computer_searches\": { \"size\": 1, \"advanced_computer_search\": [ { \"id\": 123, \"name\": \"Test Search\" } ] } }"),
    ("array_form", "{ \"advanced_computer_searches\": [ { \"id\": 456, \"name\": \"Array Search\" } ] }"),
    ("single_object_inner", "{ \"advanced_computer_searches\": { \"size\": 1, \"advanced_computer_search\": { \"id\": 789, \"name\": \"Single Inner\" } } }")
]

for (label, json) in jsonVariants {
    print("--- Testing: \(label) ---")
    guard let data = json.data(using: .utf8) else { print("failed to create data"); continue }
    do {
        let result = try decoder.decode(ComputerSearches.self, from: data)
        print("Decoded count: \(result.advancedComputerSearches.advancedComputerSearch.count)")
        for s in result.advancedComputerSearches.advancedComputerSearch {
            print("- id=\(s.id) name=\(s.name)")
        }
    } catch {
        print("Failed to decode variant \(label): \(error)")
    }
}
