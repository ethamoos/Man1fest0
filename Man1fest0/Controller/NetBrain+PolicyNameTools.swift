import Foundation
import AEXML

@MainActor
extension NetBrain {
    // Provide a simple helper used by the Tools UI to update a policy's name logically.
    // action: "removelast", "replacelast", "replaceall"
    func updatePolicyNameLogical(server: String, authToken: String, resourceType: ResourceType, policyID: String, action: String, count: Int, match: String, replacement: String) {
        Task {
            do {
                let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
                guard let url = URL(string: jamfURLQuery) else { return }

                // GET existing policy XML
                var getReq = URLRequest(url: url)
                getReq.httpMethod = "GET"
                getReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                getReq.setValue("application/xml", forHTTPHeaderField: "Accept")

                let (data, response) = try await URLSession.shared.data(for: getReq)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    print("updatePolicyNameLogical: failed to fetch policy XML - status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    return
                }

                let xmlString = String(data: data, encoding: .utf8) ?? ""
                let doc = try AEXMLDocument(xml: Data(xmlString.utf8))

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
                default:
                    print("updatePolicyNameLogical: unknown action \(action)")
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
                    print("updatePolicyNameLogical: updated policy \(policyID) name to: \(newName)")
                } else {
                    print("updatePolicyNameLogical: failed to update policy - status: \(status)")
                }
            } catch {
                print("updatePolicyNameLogical failed: \(error)")
            }
        }
    }
}
