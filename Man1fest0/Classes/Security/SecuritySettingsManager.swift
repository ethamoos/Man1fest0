import Foundation
import SwiftUI

// MARK: - Security Settings Manager
@MainActor
class SecuritySettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var inactivityTimeout: InactivityTimeout = .fiveMinutes
    @Published var useKeychainForPassword: Bool = false
    @Published var requirePasswordOnWake: Bool = true
    
    // MARK: - Inactivity Timeout Enum
    enum InactivityTimeout: Int, CaseIterable, Identifiable {
        case never = 0
        case oneMinute = 1
        case fiveMinutes = 5
        case fifteenMinutes = 15
        case thirtyMinutes = 30
        case oneHour = 60
        case twoHours = 120
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .never:
                return "Never"
            case .oneMinute:
                return "1 Minute"
            case .fiveMinutes:
                return "5 Minutes"
            case .fifteenMinutes:
                return "15 Minutes"
            case .thirtyMinutes:
                return "30 Minutes"
            case .oneHour:
                return "1 Hour"
            case .twoHours:
                return "2 Hours"
            }
        }
        
        var timeInterval: TimeInterval {
            return TimeInterval(rawValue * 60)
        }
    }
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let inactivityTimeout = "SecurityInactivityTimeout"
        static let useKeychainForPassword = "SecurityUseKeychainForPassword"
        static let requirePasswordOnWake = "SecurityRequirePasswordOnWake"
        static let lastActiveTime = "SecurityLastActiveTime"
        static let isLocked = "SecurityIsLocked"
    }
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        if let timeoutRaw = UserDefaults.standard.object(forKey: Keys.inactivityTimeout) as? Int,
           let timeout = InactivityTimeout(rawValue: timeoutRaw) {
            inactivityTimeout = timeout
        }
        
        useKeychainForPassword = UserDefaults.standard.bool(forKey: Keys.useKeychainForPassword)
        requirePasswordOnWake = UserDefaults.standard.bool(forKey: Keys.requirePasswordOnWake)
    }
    
    func saveSettings() {
        UserDefaults.standard.set(inactivityTimeout.rawValue, forKey: Keys.inactivityTimeout)
        UserDefaults.standard.set(useKeychainForPassword, forKey: Keys.useKeychainForPassword)
        UserDefaults.standard.set(requirePasswordOnWake, forKey: Keys.requirePasswordOnWake)
    }
    
    // MARK: - Inactivity Tracking
    func updateLastActiveTime() {
        UserDefaults.standard.set(Date(), forKey: Keys.lastActiveTime)
        UserDefaults.standard.set(false, forKey: Keys.isLocked)
    }
    
    func getLastActiveTime() -> Date? {
        return UserDefaults.standard.object(forKey: Keys.lastActiveTime) as? Date
    }
    
    func isLocked() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.isLocked)
    }
    
    func setLocked(_ locked: Bool) {
        UserDefaults.standard.set(locked, forKey: Keys.isLocked)
    }
    
    func shouldLock() -> Bool {
        guard inactivityTimeout != .never else { return false }
        guard let lastActive = getLastActiveTime() else { return false }
        
        let timeSinceLastActive = Date().timeIntervalSince(lastActive)
        return timeSinceLastActive >= inactivityTimeout.timeInterval
    }
    
    // MARK: - Keychain Integration
    func savePasswordToKeychain(_ password: String, username: String) {
        guard useKeychainForPassword else { return }
        
        // Remove existing password first
        KeychainHelper.deletePassword(for: username)
        
        // Save new password
        KeychainHelper.savePassword(password, for: username)
    }
    
    func getPasswordFromKeychain(username: String) -> String? {
        guard useKeychainForPassword else { return nil }
        return KeychainHelper.getPassword(for: username)
    }
    
    func clearKeychainPassword(username: String) {
        KeychainHelper.deletePassword(for: username)
    }
}

// MARK: - Keychain Helper
struct KeychainHelper {
    
    static func savePassword(_ password: String, for username: String) {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecValueData as String: data,
            kSecAttrService as String: "Man1fest0"
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to save password to keychain: \(status)")
        }
    }
    
    static func getPassword(for username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: "Man1fest0",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    static func deletePassword(for username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: "Man1fest0"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}