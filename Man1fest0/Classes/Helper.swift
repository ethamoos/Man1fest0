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
    public static func separationLine() { Man1fest0.separationLine() }
    public static func doubleSeparationLine() { Man1fest0.doubleSeparationLine() }
    public static func asteriskSeparationLine() { Man1fest0.asteriskSeparationLine() }
    public static func atSeparationLine() { Man1fest0.atSeparationLine() }
    public static func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        logDebug(items.map { "\($0)" }.joined(separator: separator), separator: "", terminator: terminator)
    }
}
