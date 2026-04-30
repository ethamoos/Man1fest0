import Foundation

/// Simple file-backed logger with levels and optional 'flag file' override.
final class Logger {
    enum Level: Int {
        case off = 0
        case normal = 1
        case verbose = 2
    }

    static let shared = Logger()

    private let fileURL: URL?
    private let fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "Man1fest0.Logger")

    private init() {
        // Determine Application Support directory for this app
        var supportURL: URL? = nil
        if let bundleID = Bundle.main.bundleIdentifier {
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                supportURL = appSupport.appendingPathComponent(bundleID, isDirectory: true)
            }
        } else {
            supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Man1fest0", isDirectory: true)
        }

        if let dir = supportURL {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
                let f = dir.appendingPathComponent("Man1fest0.log")
                self.fileURL = f
                if !FileManager.default.fileExists(atPath: f.path) {
                    FileManager.default.createFile(atPath: f.path, contents: nil, attributes: nil)
                }
                self.fileHandle = try FileHandle(forWritingTo: f)
                // move to end for appending
                try self.fileHandle?.seekToEnd()
            } catch {
                self.fileURL = nil
                self.fileHandle = nil
            }
        } else {
            self.fileURL = nil
            self.fileHandle = nil
        }
    }

    deinit {
        try? fileHandle?.close()
    }

    var currentLevel: Level {
        // First, see if a flag file requests verbose logging
        if let bundleID = Bundle.main.bundleIdentifier,
           let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let flag = appSupport.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent("enable_full_debug")
            if FileManager.default.fileExists(atPath: flag.path) {
                return .verbose
            }
        }

        // Read from UserDefaults (string or int supported)
        let key = "Man1fest0LogLevel"
        if let v = UserDefaults.standard.object(forKey: key) as? Int {
            return Level(rawValue: v) ?? .normal
        }
        if let s = UserDefaults.standard.string(forKey: key) {
            switch s.lowercased() {
            case "off": return .off
            case "verbose", "full", "debug": return .verbose
            default: return .normal
            }
        }

        // Fallback: check Info.plist for a bundle-provided default value
        if let infoVal = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            switch infoVal.lowercased() {
            case "off": return .off
            case "verbose", "full", "debug": return .verbose
            default: return .normal
            }
        }

        // Default
        return .normal
    }

    func shouldLog(level: Level) -> Bool {
        return level.rawValue <= currentLevel.rawValue && currentLevel != .off
    }

    func log(_ message: String, level: Level = .normal) {
        guard shouldLog(level: level) else { return }
        let time = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
        let line = "[\(time)] [\(level)] \(message)\n"
        // Print to stdout for Xcode console
        print(line, terminator: "")

        // Append to file asynchronously
        queue.async { [weak self] in
            guard let fh = self?.fileHandle else { return }
            if let data = line.data(using: .utf8) {
                fh.write(data)
            }
        }
    }

    // Convenience
    func normal(_ items: Any...) {
        log(items.map { "\($0)" }.joined(separator: " "), level: .normal)
    }

    func verbose(_ items: Any...) {
        log(items.map { "\($0)" }.joined(separator: " "), level: .verbose)
    }
}
