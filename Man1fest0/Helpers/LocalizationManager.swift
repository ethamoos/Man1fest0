import Foundation
import SwiftUI

/// Lightweight localization manager to support runtime language override and fallback to development region (en).
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var languageCode: String? {
        didSet {
            if let code = languageCode {
                UserDefaults.standard.set([code], forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
            // Note: Changing AppleLanguages at runtime doesn't automatically refresh Foundation lookups in all cases.
            // Our String extension uses bundles, so it will take effect for new lookups.
        }
    }

    private init() {
        // read saved override (if any)
        if let langs = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String], let first = langs.first {
            languageCode = first
        } else {
            languageCode = nil
        }
    }
}

extension String {
    /// Return localized string using app bundle but honoring LocalizationManager override when present.
    func localized(using language: String? = nil, tableName: String? = nil) -> String {
        // priority: explicit param > manager override > system
        let lang = language ?? LocalizationManager.shared.languageCode
        guard let lang = lang else {
            return NSLocalizedString(self, tableName: tableName, bundle: .main, value: self, comment: "")
        }
        // try to load bundle for language
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let b = Bundle(path: path) {
            return NSLocalizedString(self, tableName: tableName, bundle: b, value: self, comment: "")
        }
        // fallback to main
        return NSLocalizedString(self, tableName: tableName, bundle: .main, value: self, comment: "")
    }
}
