import Foundation

// Simple test runner that decodes a ComputerDetailedFullResponse from a JSON file
let fm = FileManager.default
let args = CommandLine.arguments
let path: String
if args.count > 1 {
    path = args[1]
} else {
    path = "./tools/sample_computer.json"
}

guard fm.fileExists(atPath: path) else {
    print("Test JSON file not found at path: \(path)")
    exit(2)
}

let url = URL(fileURLWithPath: path)
let data = try Data(contentsOf: url)

let decoder = JSONDecoder()

do {
    let resp = try decoder.decode(ComputerDetailedFullResponse.self, from: data)
    print("Decode succeeded. Dumping structure:\n")
    dump(resp)
} catch {
    print("Decoding failed: \(error)\n")
    if let dec = error as? DecodingError {
        switch dec {
        case .typeMismatch(let type, let context):
            print("typeMismatch: ")
            print("  type: \(type)")
            print("  context: \(context)")
        case .valueNotFound(let value, let context):
            print("valueNotFound: \(value) \(context)")
        case .keyNotFound(let key, let context):
            print("keyNotFound: \(key) \(context)")
        case .dataCorrupted(let ctx):
            print("dataCorrupted: \(ctx)")
        @unknown default:
            print("unknown decoding error: \(dec)")
        }
    } else {
        print(error)
    }
    exit(1)
}
