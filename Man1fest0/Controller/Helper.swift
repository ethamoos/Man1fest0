//
//  Helper.swift
//  Man1fest0
//
//  Created by Amos Deane on 05/12/2025.
//




 import Foundation

// Simple shared debug/visual helper lines available throughout the app.
// Put lightweight helpers here so individual classes don't have to re-define them.

public func separationLine() {
    print("-----------------------------------")
}

// Lightweight file-backed logger included here so it's always available to the app
final class Logger {
    enum Level: Int {
        case off = 0, normal = 1, verbose = 2
    }
    static let shared = Logger()
    private let fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "Man1fest0.Logger")

    private init() {
        var fh: FileHandle? = nil
        // Determine a sane Application Support directory and ensure it exists inside the app container.
        let bundleID = Bundle.main.bundleIdentifier ?? "Man1fest0"
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent(bundleID, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                print("Logger: failed to create Application Support directory '\(dir.path)' - \(error)")
            }

            let f = dir.appendingPathComponent("Man1fest0.log")
            if !FileManager.default.fileExists(atPath: f.path) {
                let created = FileManager.default.createFile(atPath: f.path, contents: nil)
                if !created {
                    print("Logger: failed to create log file at path: \(f.path)")
                }
            }

            do {
                fh = try FileHandle(forWritingTo: f)
                // Place cursor at end so we append
                try fh?.seekToEnd()

                // Write a guaranteed startup line so a user can locate the file immediately.
                let time = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
                let startup = "[\(time)] [startup] Application started\n"
                if let d = startup.data(using: .utf8) {
                    fh?.write(d)
                }
                print("Logger initialized, log file: \(f.path)")
                // Also write a small diagnostic file into /tmp so the developer can quickly
                // confirm that Logger.init ran even if Application Support writes fail.
                let diagURL = URL(fileURLWithPath: "/tmp/Man1fest0_logger_diagnostic.txt")
                let diagLine = "[\(time)] Logger init; bundleID=\(bundleID); logPath=\(f.path); fhPresent=\(fh != nil)\n"
                if FileManager.default.fileExists(atPath: diagURL.path) {
                    if let dh = try? FileHandle(forWritingTo: diagURL) {
                        try? dh.seekToEnd()
                        if let dd = diagLine.data(using: .utf8) { dh.write(dd) }
                        try? dh.close()
                    }
                } else {
                    try? diagLine.write(to: diagURL, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Logger: failed to open or write to log file '\(f.path)' - \(error)")
            }
        } else {
            print("Logger: unable to determine Application Support directory; bundleID=\(bundleID)")
        }

        self.fileHandle = fh
    }

    var currentLevel: Level {
        // flag file override
        if let bundleID = Bundle.main.bundleIdentifier,
           let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let flag = appSupport.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent("enable_full_debug")
            if FileManager.default.fileExists(atPath: flag.path) { return .verbose }
        }
        let key = "Man1fest0LogLevel"
        if let v = UserDefaults.standard.object(forKey: key) as? Int { return Level(rawValue: v) ?? .normal }
        if let s = UserDefaults.standard.string(forKey: key) {
            switch s.lowercased() {
            case "off": return .off
            case "verbose", "full", "debug": return .verbose
            default: return .normal
            }
        }
        if let infoVal = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            switch infoVal.lowercased() {
            case "off": return .off
            case "verbose", "full", "debug": return .verbose
            default: return .normal
            }
        }
        return .normal
    }

    func shouldLog(level: Level) -> Bool { level.rawValue <= currentLevel.rawValue && currentLevel != .off }

    func log(_ message: String, level: Level = .normal) {
        guard shouldLog(level: level) else { return }
        let time = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
        let line = "[\(time)] [\(level)] \(message)\n"
        print(line, terminator: "")
        queue.async { [weak self] in
            guard let fh = self?.fileHandle else { return }
            if let d = line.data(using: .utf8) { fh.write(d) }
        }
    }

    func normal(_ items: Any...) { log(items.map { "\($0)" }.joined(separator: " "), level: .normal) }
    func verbose(_ items: Any...) { log(items.map { "\($0)" }.joined(separator: " "), level: .verbose) }
}

public func doubleSeparationLine() {
    print("===================================")
}

public func asteriskSeparationLine() {
    print("***********************************")
}

public func atSeparationLine() {
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
}

/// Debug logging helper that can be toggled from one place if you want to silence debug output later.
public var DebugHelpers_enabled: Bool = false

public func logDebug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    guard DebugHelpers_enabled else { return }
    let output = items.map { "\($0)" }.joined(separator: separator)
    // Also forward to file-backed logger when enabled
    Logger.shared.normal(output)
}

/// Convenience wrapper so callers can use `Debug.separationLine()` from inside classes without ambiguity.
public enum Debug {
    public static func separationLine() { Man1fest0.separationLine() }
    public static func doubleSeparationLine() { Man1fest0.doubleSeparationLine() }
    public static func asteriskSeparationLine() { Man1fest0.asteriskSeparationLine() }
    public static func atSeparationLine() { Man1fest0.atSeparationLine() }
    public static func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        logDebug(items.map { "\($0)" }.joined(separator: separator), separator: "", terminator: terminator)
    }
}

// File-load diagnostic: this closure runs when the module is loaded. It helps detect
// whether the source is being loaded/executed in the runtime you launched.
private let _Man1fest0_logger_module_load: Void = {
    let bundleID = Bundle.main.bundleIdentifier ?? "Man1fest0"
    let time = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
    let diag1 = "[\(time)] module_load; bundleID=\(bundleID)\n"
    let diagURL = URL(fileURLWithPath: "/tmp/Man1fest0_module_load.txt")
    // Write to /tmp (best-effort); do not throw.
    if FileManager.default.fileExists(atPath: diagURL.path) {
        if let fh = try? FileHandle(forWritingTo: diagURL) {
            try? fh.seekToEnd()
            if let d = diag1.data(using: .utf8) { fh.write(d) }
            try? fh.close()
        }
    } else {
        try? diag1.write(to: diagURL, atomically: true, encoding: .utf8)
    }
    // Also write a simple NSLog so Console.app can show it if available
    NSLog("Man1fest0: module_load; bundleID=%@", bundleID)
}()
