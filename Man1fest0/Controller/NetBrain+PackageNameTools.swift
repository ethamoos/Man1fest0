import Foundation
import AEXML

@MainActor
extension NetBrain {
    // Logical rename helper for packages
    func updatePackageNameLogical(server: String, authToken: String, resourceType: ResourceType, packageID: String, action: String, count: Int, match: String, replacement: String) async {
        do {
                let jamfURLQuery = server + "/JSSResource/packages/id/" + "\(packageID)"
                guard let url = URL(string: jamfURLQuery) else { return }

                // GET existing package XML
                var getReq = URLRequest(url: url)
                getReq.httpMethod = "GET"
                getReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                getReq.setValue("application/xml", forHTTPHeaderField: "Accept")

                let (data, response) = try await URLSession.shared.data(for: getReq)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    print("updatePackageNameLogical: failed to fetch package XML - status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    return
                }

                let xmlString = String(data: data, encoding: .utf8) ?? ""
                let doc = try AEXMLDocument(xml: Data(xmlString.utf8))

                // Try common locations for the name element
                var currentName = doc.root["general"]["name"].string
                var nameLocation: (parent: AEXMLElement, key: String)? = nil

                if !currentName.isEmpty {
                    nameLocation = (parent: doc.root["general"], key: "name")
                } else if !doc.root["name"].string.isEmpty {
                    currentName = doc.root["name"].string
                    nameLocation = (parent: doc.root, key: "name")
                } else if !doc.root["package"]["name"].string.isEmpty {
                    currentName = doc.root["package"]["name"].string
                    nameLocation = (parent: doc.root["package"], key: "name")
                } else if !doc.root["package"]["general"]["name"].string.isEmpty {
                    currentName = doc.root["package"]["general"]["name"].string
                    nameLocation = (parent: doc.root["package"]["general"], key: "name")
                }

                var newName = currentName

                switch action.lowercased() {
                case "removelast":
                    if count >= currentName.count {
                        newName = ""
                    } else if count > 0 {
                        newName = String(currentName.dropLast(count))
                    }
                case "replacelast":
                    if count >= currentName.count {
                        newName = replacement
                    } else if count > 0 {
                        newName = String(currentName.dropLast(count)) + replacement
                    } else {
                        newName = replacement
                    }
                case "removefirst":
                    if count >= currentName.count {
                        newName = ""
                    } else if count > 0 {
                        newName = String(currentName.dropFirst(count))
                    }
                case "replacefirst":
                    if count >= currentName.count {
                        newName = replacement
                    } else if count > 0 {
                        newName = replacement + String(currentName.dropFirst(count))
                    } else {
                        newName = replacement
                    }
                case "addlast":
                    newName = currentName + replacement
                case "addfirst":
                    newName = replacement + currentName
                case "replaceall":
                    newName = currentName.replacingOccurrences(of: match, with: replacement)
                default:
                    print("updatePackageNameLogical: unknown action '\(action)'. Supported: removelast, replacelast, removefirst, replacefirst, addlast, addfirst, replaceall")
                    return
                }

                // If nothing changed, skip update
                if newName == currentName {
                    print("updatePackageNameLogical: computed name is identical to current name; nothing to do")
                    return
                }

                // Replace the name element in whichever parent we found
                if let loc = nameLocation {
                    if let elem = loc.parent[loc.key].last {
                        elem.removeFromParent()
                    }
                    _ = loc.parent.addChild(name: loc.key, value: newName)
                } else {
                    // Fallback: set <package><name>
                    if let pkg = doc.root["package"] {
                        if let elem = pkg["name"].last { elem.removeFromParent() }
                        _ = pkg.addChild(name: "name", value: newName)
                    } else {
                        if let elem = doc.root["name"].last { elem.removeFromParent() }
                        _ = doc.root.addChild(name: "name", value: newName)
                    }
                }

                // PUT updated XML back to server
                var putReq = URLRequest(url: url)
                putReq.httpMethod = "PUT"
                putReq.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                putReq.setValue("application/xml", forHTTPHeaderField: "Accept")
                putReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                putReq.httpBody = doc.xml.data(using: .utf8)

                let (_, putResp) = try await URLSession.shared.data(for: putReq)
                let status = (putResp as? HTTPURLResponse)?.statusCode ?? -1
                if (200...299).contains(status) {
                    print("updatePackageNameLogical: updated package \(packageID) name to: \(newName)")
                } else {
                    print("updatePackageNameLogical: failed to update package - status: \(status)")
                }
            } catch {
                print("updatePackageNameLogical failed: \(error)")
            }
    }
}
