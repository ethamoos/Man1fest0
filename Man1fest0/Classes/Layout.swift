//
//  Layout.swift
//  Man1fest0
//
//  Created by Amos Deane on 23/04/2024.
//

import Foundation
import SwiftUI


class Layout: ObservableObject {
    
    @EnvironmentObject var networkController: NetBrain
    
    let date = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .short))

//   var urlString: String = ""
   var showAlert = false
   var alertMessage = ""
    
    
    let column = [
        GridItem(.fixed(200), alignment: .leading)
    ]
    
    let columns = [
        GridItem(.fixed(200), alignment: .leading), // <------ HERE!
        GridItem(.flexible(minimum: 50, maximum: .infinity), alignment: .leading)
    ]
    let threeColumns = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    
    let fourColumns = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200)),
        GridItem(.fixed(250)),
        GridItem(.flexible()),
    ]
    
    let fiveColumns = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200)),
        GridItem(.fixed(250)),
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    
    let columnAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading)
    ]
    
    let columnsAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading),
        GridItem(.adaptive(minimum: 250))
    ]
    
    let threeColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250))
    ]
    let fourColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250))
    ]
   
    let fiveColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
    ]
    
    let fiveColumnsAdaptiveWide = [
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
    ]
      
    let columnsFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
        GridItem(.flexible(minimum: 20), alignment: .leading)
    ]
    let threeColumnsFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100))
    ]
    
      let fourColumnsFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100))
    ]
    
    let columnFlex = [
        GridItem(.flexible(minimum: 250), alignment: .leading)
    ]
    
    let columnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(minimum: 250))
    ]
    
    let threeColumnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fourColumnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fiveColumnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    
    let columnsAllFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible())
    ]
    
    let columnFlexAdaptive = [
        GridItem(.adaptive(minimum: 300), alignment: .leading)
    ]
    
    let columnsFlexAdaptive = [
        GridItem(.adaptive(minimum: 300), alignment: .leading),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnsFlexMedium = [
        GridItem(.fixed(600), alignment: .leading),
        GridItem(.flexible(minimum: 600))
    ]
    
    let threeColumnsFlexMedium = [
        GridItem(.fixed(600), alignment: .leading),
        GridItem(.fixed(600)),
        GridItem(.flexible(minimum: 600))
    ]
    
    let columnsFlexAdaptiveMedium = [
        GridItem(.adaptive(minimum: 150), alignment: .leading),
        GridItem(.adaptive(minimum: 150))
    ]
    
    let columnFlexMedium = [
        GridItem(.adaptive(minimum: 150), alignment: .leading),
    ]
    
    let columnFlexWide = [
        GridItem(.flexible(minimum: 400), alignment: .leading),
    ]
    
    let columnsFlexWide = [
        GridItem(.flexible(minimum: 300), alignment: .leading),
        GridItem(.flexible(minimum: 300))
    ]
    
    let columnWide = [
        GridItem(.fixed(400), alignment: .leading),
    ]
    
    let columnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.fixed(400))
    ]
    
    let threeColumnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    let fourColumnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let fiveColumnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnFixed = [
        GridItem(.fixed(200), alignment: .leading),
    ]
    let columnsFixed = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200), alignment: .leading)
    ]
    
    let threeColumnsFixed = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200), alignment: .leading)
    ]
    
    func separationLine() {
        print("------------------------------------------------")
    }
    
    func doubleSeparationLine() {
        print("================================================")
    }
    
    func asteriskSeparationLine() {
        print("************************************************")
    }
    
    func atSeparationLine() {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    }
    
    private func translateJamfAPIURL(_ url: URL) -> URL? {
        // We're only interested in paths that contain `/JSSResource/{resource}/id/{id}`
        let components = url.pathComponents.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }.filter { !$0.isEmpty }
        // components would be ["JSSResource","policies","id","1111"] for the example
        guard components.count >= 4 else { return nil }
        guard components[0].lowercased() == "jssresource" else { return nil }

        let resource = components[1]

        // find the "id" segment and the following value
        if let idIndex = components.firstIndex(where: { $0.lowercased() == "id" }), components.indices.contains(idIndex + 1) {
            let idValue = components[idIndex + 1]

            var newComponents = URLComponents()
            newComponents.scheme = url.scheme
            newComponents.host = url.host
            newComponents.port = url.port
            // Preserve user/password if present
            if let user = url.user, !user.isEmpty { newComponents.user = user }
            if let password = url.password, !password.isEmpty { newComponents.password = password }

            newComponents.path = "/\(resource).html"
            newComponents.queryItems = [
                URLQueryItem(name: "id", value: idValue),
                URLQueryItem(name: "o", value: "r")
            ]

            return newComponents.url
        }

        return nil
    }

    // Translate a Jamf API URL to the format used by the Jamf Pro web UI for a given request type.
    // Example:
    //  input:  https://server/JSSResource/computers/id/18562, requestType: "computers"
    //  output: https://server/JSSResource/computers?id=18562&o=r
    func translateJamfURL(_ url: URL, requestType: String) -> URL? {
        // Normalize path components and remove empty segments caused by double slashes
        let components = url.pathComponents.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }.filter { !$0.isEmpty }
        guard !components.isEmpty else { return nil }

        // Try to find an explicit "id" segment first
        var idValue: String? = nil
        if let idIndex = components.firstIndex(where: { $0.lowercased() == "id" }), components.indices.contains(idIndex + 1) {
            idValue = components[idIndex + 1]
        } else {
            // Fallback: find the requestType segment and take the following component if it looks numeric
            if let rtIndex = components.firstIndex(where: { $0.lowercased() == requestType.lowercased() }), components.indices.contains(rtIndex + 1) {
                let possible = components[rtIndex + 1]
                if Int(possible) != nil {
                    idValue = possible
                }
            }
        }

        guard let idUnwrapped = idValue else { return nil }

        var newComponents = URLComponents()
        newComponents.scheme = url.scheme
        newComponents.host = url.host
        newComponents.port = url.port
        if let user = url.user, !user.isEmpty { newComponents.user = user }
        if let password = url.password, !password.isEmpty { newComponents.password = password }

        // Build the target path: /JSSResource/{requestType}
        newComponents.path = "/JSSResource/\(requestType)"
        newComponents.queryItems = [
            URLQueryItem(name: "id", value: idUnwrapped),
            URLQueryItem(name: "o", value: "r")
        ]

        return newComponents.url
    }

    /// Open a URL in the default browser. If `requestType` is provided, prefer translating
    /// the URL using `translateJamfURL(_:requestType:)`. Otherwise fall back to the
    /// automatic `translateJamfAPIURL(_:)` translation (if any).
    func openURL(urlString: String, requestType: String? = nil) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alertMessage = "Please enter a URL."
            showAlert = true
            return
        }

        // If the user didn't include a scheme, default to https
        var candidate = trimmed
        if URL(string: candidate)?.scheme == nil {
            candidate = "https://" + candidate
        }

        guard let url = URL(string: candidate) else {
            alertMessage = "The text you entered is not a valid URL."
            showAlert = true
            return
        }

        // If a requestType is supplied prefer that translation (e.g. "computers").
        var urlToOpen: URL = url
        if let req = requestType, !req.trimmingCharacters(in: .whitespaces).isEmpty,
           let translated = self.translateJamfURL(url, requestType: req) {
            urlToOpen = translated
        } else if let translated = self.translateJamfAPIURL(url) {
            // Fallback to existing automatic translation
            urlToOpen = translated
        }

        if !NSWorkspace.shared.open(urlToOpen) {
            alertMessage = "Failed to open the URL in the default browser."
            showAlert = true
        }
    }
    
}
    
//}
