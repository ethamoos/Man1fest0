 import Foundation

// Simple shared debug/visual helper lines available throughout the app.
// Put lightweight helpers here so individual classes don't have to re-define them.

public func separationLine() {
    print("-----------------------------------")
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
public var DebugHelpers_enabled: Bool = true

public func logDebug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    guard DebugHelpers_enabled else { return }
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
}

/// Convenience wrapper so callers can use `Debug.separationLine()` from inside classes without ambiguity.
public enum Debug {
    public static func separationLine() { separationLine() }
    public static func doubleSeparationLine() { doubleSeparationLine() }
    public static func asteriskSeparationLine() { asteriskSeparationLine() }
    public static func atSeparationLine() { atSeparationLine() }
    public static func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        logDebug(items.map { "\($0)" }.joined(separator: separator), separator: "", terminator: terminator)
    }
}
