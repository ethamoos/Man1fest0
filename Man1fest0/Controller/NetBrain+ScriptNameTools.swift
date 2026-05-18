import Foundation
import AEXML

@MainActor
extension NetBrain {
    // Provide a simple helper used by the Tools UI to update a script's name logically.
    // This mirrors the policy helper but operates on the scripts resource.
    // action examples: "removelast", "replacelast", "replaceall", "removefirst", "replacefirst", "addlast", "addfirst"
    func updateScriptNameLogical(server: String, authToken: String, resourceType: ResourceType, scriptID: String, action: String, count: Int, match: String, replacement: String) async {
        do {
            let jamfURLQuery = server + "/JSSResource/scripts/id/" + "\(scriptID)"
            guard let url = URL(string: jamfURLQuery) else { return }

            // GET existing script XML
            var getReq = URLRequest(url: url)
            getReq.httpMethod = "GET"
            getReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            getReq.setValue("application/xml", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: getReq)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("updateScriptNameLogical: failed to fetch script XML - status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }

            let xmlString = String(data: data, encoding: .utf8) ?? ""
            let doc = try AEXMLDocument(xml: Data(xmlString.utf8))

            // Script XML uses <script><general><name>
            let currentName = doc.root["general"]["name"].string
            var newName = currentName

            switch action {
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
            case "replaceall":
                newName = currentName.replacingOccurrences(of: match, with: replacement)
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
            default:
                print("updateScriptNameLogical: unknown action '\(action)'. Supported: removelast, replacelast, removefirst, replacefirst, addlast, addfirst, replaceall")
                return
            }

            // If nothing changed, skip update
            if newName == currentName {
                print("updateScriptNameLogical: computed name is identical to current name; nothing to do")
                return
            }

            // Replace the <name> element in the XML
            if let nameElem = doc.root["general"]["name"].last {
                nameElem.removeFromParent()
            }
            _ = doc.root["general"].addChild(name: "name", value: newName)

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
                print("updateScriptNameLogical: updated script \(scriptID) name to: \(newName)")
            } else {
                print("updateScriptNameLogical: failed to update script - status: \(status)")
            }
        } catch {
            print("updateScriptNameLogical failed: \(error)")
        }
    }
}
