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
    Logger.shared.verbose("-----------------------------------")
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
        var logFileHandle: FileHandle? = nil
        // Determine a sane Application Support directory and ensure it exists inside the app container.
        let bundleID = Bundle.main.bundleIdentifier ?? "Man1fest0"
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent(bundleID, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                print("Logger: failed to create Application Support directory '\(dir.path)' - \(error)")
            }

            let logFileURL = dir.appendingPathComponent("Man1fest0.log")
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                let created = FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
                if !created {
                    print("Logger: failed to create log file at path: \(logFileURL.path)")
                }
            }

            do {
                logFileHandle = try FileHandle(forWritingTo: logFileURL)
                // Place cursor at end so we append
                try logFileHandle?.seekToEnd()

                // Write a guaranteed startup line so a user can locate the file immediately.
                let time = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
                let startup = "[\(time)] [startup] Application started\n"
                if let startupData = startup.data(using: .utf8) {
                    logFileHandle?.write(startupData)
                }
                print("Logger initialized, log file: \(logFileURL.path)")
                // Also write a small diagnostic file into the app's temporary directory so the developer
                // can quickly confirm that Logger.init ran even if Application Support writes fail.
                let diagDir = FileManager.default.temporaryDirectory
                let diagURL = diagDir.appendingPathComponent("Man1fest0_logger_diagnostic.txt")
                let diagLine = "[\(time)] Logger init; bundleID=\(bundleID); logPath=\(logFileURL.path); fhPresent=\(logFileHandle != nil)\n"
                if FileManager.default.fileExists(atPath: diagURL.path) {
                    if let diagFileHandle = try? FileHandle(forWritingTo: diagURL) {
                        _ = try? diagFileHandle.seekToEnd()
                        if let diagData = diagLine.data(using: .utf8) { diagFileHandle.write(diagData) }
                        _ = try? diagFileHandle.close()
                    }
                } else {
                    _ = try? diagLine.write(to: diagURL, atomically: true, encoding: .utf8)
                }
            } catch {
                print("Logger: failed to open or write to log file '\(logFileURL.path)' - \(error)")
            }
        } else {
            print("Logger: unable to determine Application Support directory; bundleID=\(bundleID)")
        }

        // DEV fallback: if we couldn't open the Application Support log, write to /tmp for easy local debugging.
        // This is guarded by DEBUG so it won't affect production builds.
#if DEBUG
            if logFileHandle == nil {
            let tmpDir = FileManager.default.temporaryDirectory
            let tmpLogURL = tmpDir.appendingPathComponent("Man1fest0_dev.log")
            if !FileManager.default.fileExists(atPath: tmpLogURL.path) {
                FileManager.default.createFile(atPath: tmpLogURL.path, contents: nil)
            }
                if let tmpFileHandle = try? FileHandle(forWritingTo: tmpLogURL) {
                _ = try? tmpFileHandle.seekToEnd()
                let time = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
                let startup = "[\(time)] [startup/dev-fallback] Application started\n"
                if let startupData = startup.data(using: .utf8) { tmpFileHandle.write(startupData) }
                // Also append a diagnostic line to the same diagnostic file used elsewhere
                let diagLine = "[\(time)] Logger fallback to temp; bundleID=\(bundleID); logPath=\(tmpLogURL.path); fhPresent=true\n"
                let diagURL = FileManager.default.temporaryDirectory.appendingPathComponent("Man1fest0_logger_diagnostic.txt")
                if FileManager.default.fileExists(atPath: diagURL.path) {
                    if let diagFileHandle = try? FileHandle(forWritingTo: diagURL) {
                        _ = try? diagFileHandle.seekToEnd()
                        if let diagData = diagLine.data(using: .utf8) { diagFileHandle.write(diagData) }
                        _ = try? diagFileHandle.close()
                    }
                } else {
                    _ = try? diagLine.write(to: diagURL, atomically: true, encoding: .utf8)
                }
                logFileHandle = tmpFileHandle
                print("Logger fallback to temp: \(tmpLogURL.path)")
            } else {
                print("Logger: failed to open fallback temp log at \(tmpLogURL.path)")
            }
        }
#endif

        self.fileHandle = logFileHandle
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
            guard let fileHandle = self?.fileHandle else { return }
            if let data = line.data(using: .utf8) { fileHandle.write(data) }
        }
    }

    func normal(_ items: Any...) { log(items.map { "\($0)" }.joined(separator: " "), level: .normal) }
    func verbose(_ items: Any...) { log(items.map { "\($0)" }.joined(separator: " "), level: .verbose) }
}

public func doubleSeparationLine() {
    Logger.shared.verbose("===================================")
}

public func asteriskSeparationLine() {
    Logger.shared.verbose("***********************************")
}

public func atSeparationLine() {
    Logger.shared.verbose("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
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
    // Use the process-local temporary directory (sandbox-friendly) for module-load diagnostics
    let diagURL = FileManager.default.temporaryDirectory.appendingPathComponent("Man1fest0_module_load.txt")
    // Write to /tmp (best-effort); do not throw.
        if FileManager.default.fileExists(atPath: diagURL.path) {
        if let diagFileHandleLocal = try? FileHandle(forWritingTo: diagURL) {
            _ = try? diagFileHandleLocal.seekToEnd()
            if let diagDataLocal = diag1.data(using: .utf8) { diagFileHandleLocal.write(diagDataLocal) }
            _ = try? diagFileHandleLocal.close()
        }
    } else {
        _ = try? diag1.write(to: diagURL, atomically: true, encoding: .utf8)
    }
    // Also write a simple NSLog so Console.app can show it if available
    NSLog("Man1fest0: module_load; bundleID=%@", bundleID)
}()
