, import Foundation

// Small test harness to verify ComputerSearches decoding with different JSON shapes.

let decoder = JSONDecoder()

let jsonVariants: [(String, String)] = [
    ("object_form", "{ \"advanced_computer_searches\": { \"size\": 1, \"advanced_computer_search\": [ { \"id\": 123, \"name\": \"Test Search\" } ] } }") ,
    ("array_form", "{ \"advanced_computer_searches\": [ { \"id\": 456, \"name\": \"Array Search\" } ] }") ,
    ("single_object_inner", "{ \"advanced_computer_searches\": { \"size\": 1, \"advanced_computer_search\": { \"id\": 789, \"name\": \"Single Inner\" } } }")
]

for (label, json) in jsonVariants {
    print("--- Testing: \(label) ---")
    if let data = json.data(using: .utf8) {
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
}
