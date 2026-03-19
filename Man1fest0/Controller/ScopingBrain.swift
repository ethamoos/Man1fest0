//
//  ScopingBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 16/07/2024.
//

import Foundation
import SwiftUI
import AEXML

@MainActor class ScopingBrain: ObservableObject {
    
    
    @Published var status: String = ""
    @Published var encoded = ""
    @Published var url: URL? = nil
    
    //    #################################################################################
    //    Environment objects
    //    #################################################################################
    
//    @EnvironmentObject var layout: Layout
//    @EnvironmentObject var xmlBrain: XmlBrain
//    // @EnvironmentObject var controller: JamfController
//    @EnvironmentObject var networkController: NetBrain
    
    //    #################################################################################
    //    Policies
    //    #################################################################################
    
    @Published var currentPolicyID: Int = 0
    @Published var currentPolicyName: String = ""
    @Published var currentPolicyIDIString: String = ""
    //    @Published var policyProcessList: [Policy] = []
    
    //    #################################################################################
    //    ############ Process lists - for batch operations
    //    #################################################################################
    
    @Published var computerProcessList: [Computer] = []
    @Published var policyProcessList: [Policy] = []
    @Published var policiesProcessList: [Policy] = []
    @Published var packageProcessList: [Package] = []
    @Published var genericProcessList: [Any] = []
    @Published var processingComplete: Bool = true
    
    //    #################################################################################
    //    XML data
    //    #################################################################################
    
    @Published var aexmlDoc: AEXMLDocument = AEXMLDocument()
    @Published var currentPolicyScopeXML: String = ""
    @Published var computerGroupMembersXML: String = ""
    @State var currentPolicyAsXML: String = ""
    
#if os(macOS)
    @State var element: XMLNode = XMLNode()
    @State var element2: XMLNode = XMLNode()
    @State var item: XMLNode = XMLNode()
    @State var item2: XMLNode = XMLNode()
#endif

    //    ##################################################
    //    LDAP
    //    ##################################################
    
    @Published var allLdapServers: [LDAPServer] = []
    @Published var allLdapGroups: [LDAPGroup] = []
    @Published var allLdapCustomGroupsCombinedArray: [LDAPCustomGroup] = []
    @Published var allLDAPSearchResponse: LDAPSearchResponse = LDAPSearchResponse(totalCount: 0, results:[])
    
    enum NetError: Error {
        case couldntEncodeNamePass
        case badResponseCode
    }
    
    //    ##################################################
    //    XML Global Operations
    //    ##################################################

    //    #################################################################################
    //    sendRequestAsXML
    //    #################################################################################
    
    
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String ) {
        //        Request in XML format
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        // separationLine is MainActor-isolated; ensure we call it on the MainActor from this (possibly background) caller
        Task { await MainActor.run { self.separationLine() } }
        print("Running sendRequestAsXML Scoping Brain function - resourceType is set as:\(resourceType)")
        //        DEBUG
        print("url is:\(url)")
        // separationLine is MainActor-isolated; ensure we call it on the MainActor from this (possibly background) caller
        Task { await MainActor.run { self.separationLine() } }
        print("httpMethod is:\(httpMethod)")
        
        let headers = [
            "Accept": "application/xml",
            "Content-Type": "application/xml",
            "Authorization": "Bearer \(authToken)"
        ]
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = httpMethod
        request.httpBody = xmldata
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                //                self.separationLine()
                //                print("Doing processing of sendRequestAsXML:\(httpMethod)")
                //                print("Data is:\(data)")
                //                print("Data is:\(response)")
                Task { await MainActor.run { self.separationLine() } }
                print("Doing processing of sendRequestAsXML:\(httpMethod)")
                print("Data is:\(data)")
                print("Data is:\(response)")
                if resourceType == ResourceType.computer {
                    print("Resource type is:\(resourceType)")
                } else if resourceType == ResourceType.policy {
                    print("Resource type is:\(resourceType)")
                } else {
                    print("Resource type is:\(resourceType)")
                }
            } else {
                print("Error encountered")
                var text = "\n\nFailed."
                if let error = error {
                    text += " \(error)."
                }
                print(text)
            }
        }
        dataTask.resume()
    }
    
    //   #################################################################################
    //   getPolicyAsXML
    //   #################################################################################
    
    func getPolicyAsXML(server: String, authToken: String, policyID: Int) {
        
        let policyIdString = String(describing: policyID )
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyIdString)"
        let url = URL(string: jamfURLQuery)!
        
        let headers = [
            "Accept": "application/xml",
            "Content-Type": "application/xml",
            "Authorization": "Bearer \(authToken)" ]
        
        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "GET"
        print("Running: scopingController.getPolicyAsXML")
        print("policyID set as: \(policyID)")
        print("jamfURLQuery set as: \(jamfURLQuery)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                //                layout.separationLine()
                print("getPolicyAsXML failed")
                print(String(describing: error))
                return
            }
            print("scopingController.getPolicyAsXML data is:")
            print(String(data: data, encoding: .utf8)!)
            DispatchQueue.main.async {
                self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
            }
        }
        task.resume()
    }
    
    //    ##################################################
    //    XML Global Operations - END
    //    ##################################################
    
    
    func separationLine() {
        print("------------------------------------------------------------------")
    }
    
    func doubleSeparationLine() {
        print("==================================================================")
    }
    
    func asteriskSeparationLine() {
        print("******************************************************************")
    }
    func atSeparationLine() {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    }
    
    //    ##################################################
    //    Batch Operations
    //    ##################################################
    
    //    #################################################################################
    //    updateScopeMultiplePolicies - batch
    //    #################################################################################
    
    //    func updateScopeMultiplePolicies(selection:  Set<Policy>, server: String, authToken: String, groupName: String, groupId: String, xmlString: String) {
    //
    //        layout.separationLine()
    //        print("Running: processDeletePolicies")
    //        print("Set processingComplete to false")
    //        self.processingComplete = true
    //        print(String(describing: self.processingComplete))
    //
    //        for eachItem in selection {
    //            layout.separationLine()
    //            print("Items as Dictionary is \(eachItem)")
    //
    //            let policyID = String(describing:eachItem.id)
    //            let jamfID: String = String(describing:eachItem.jamfId ?? 0)
    //            print("Current policyID is:\(policyID)")
    //            print("Current jamfID is:\(String(describing: jamfID))")
    //            print("Run:getPolicyAsXML")
    //            xmlController.getPolicyAsXML(server: server, policyID: eachItem.jamfId ?? 0)
    //
    //            self.updateScopeAddCompGroup(xmlString: xmlString, groupName: groupName, groupId: groupId)
    //        }
    //        layout.separationLine()
    //        print("Finished - Set processingComplete to true")
    //        self.processingComplete = true
    //        print(String(describing: self.processingComplete))
    //    }
    
    //    #################################################################################
    //    SCOPING SECTION - START
    //    #################################################################################
    
    //    #################################################################################
    //    updateScopeExclusions - update a single or multiple policies with a single group
    //    #################################################################################
    
            
            func updateScopeExclusions (xmlString: String, groupName: String, groupId: String) -> String {
                 // Use AEXML to manipulate the policy XML to avoid Foundation placeholder node issues
                 guard !xmlString.isEmpty else { return "" }
                 do {
                     let doc = try AEXMLDocument(xml: Data(xmlString.utf8))

                     // Ensure /policy/scope/exclusions exists, creating missing intermediate nodes as needed
                     var scopeElem = doc.root["scope"]
                     if scopeElem.name == "" {
                         scopeElem = doc.root.addChild(name: "scope")
                     }

                     var exclusionsElem = scopeElem["exclusions"]
                     if exclusionsElem.name == "" {
                         exclusionsElem = scopeElem.addChild(name: "exclusions")
                     }

                     // Ensure <computer_groups> exists under exclusions
                     var compGroupsElem = exclusionsElem["computer_groups"]
                     if compGroupsElem.name == "" {
                         compGroupsElem = exclusionsElem.addChild(name: "computer_groups")
                     }

                     // Append a new <computer_group> with <id> and <name>
                     let newGroup = compGroupsElem.addChild(name: "computer_group")
                     newGroup.addChild(name: "id", value: groupId)
                     newGroup.addChild(name: "name", value: groupName)

                     // Return the updated XML string
                     return doc.xml
                 } catch {
                     print("updateScopeExclusions failed to parse XML: \(error)")
                     return xmlString
                 }
              }
            
            // Add an exclusion entry for an individual computer
            func updateScopeExclusionsAddComputer(xmlString: String, computerName: String, computerId: String) -> String {
                guard !xmlString.isEmpty else { return "" }
                do {
                    let doc = try AEXMLDocument(xml: Data(xmlString.utf8))
                    var scopeElem = doc.root["scope"]
                    if scopeElem.name == "" { scopeElem = doc.root.addChild(name: "scope") }
                    var exclusionsElem = scopeElem["exclusions"]
                    if exclusionsElem.name == "" { exclusionsElem = scopeElem.addChild(name: "exclusions") }
                    var comps = exclusionsElem["computers"]
                    if comps.name == "" { comps = exclusionsElem.addChild(name: "computers") }
 
                // dedupe by id if possible
                for child in comps.children {
                    if child["id"].value == computerId || child["name"].value == computerName { return doc.xml }
                }
 
                let newItem = comps.addChild(name: "computer")
                newItem.addChild(name: "id", value: computerId)
                newItem.addChild(name: "name", value: computerName)
                return doc.xml
            } catch {
                print("updateScopeExclusionsAddComputer failed: \(error)")
                return xmlString
            }
        }
 
        func updateScopeExclusionsAddBuilding(xmlString: String, buildingName: String, buildingId: String) -> String {
            guard !xmlString.isEmpty else { return "" }
            do {
                let doc = try AEXMLDocument(xml: Data(xmlString.utf8))
                var scopeElem = doc.root["scope"]
                if scopeElem.name == "" { scopeElem = doc.root.addChild(name: "scope") }
                var exclusionsElem = scopeElem["exclusions"]
                if exclusionsElem.name == "" { exclusionsElem = scopeElem.addChild(name: "exclusions") }
                var builds = exclusionsElem["buildings"]
                if builds.name == "" { builds = exclusionsElem.addChild(name: "buildings") }
                for child in builds.children {
                    if child["id"].value == buildingId || child["name"].value == buildingName { return doc.xml }
                }
                let newItem = builds.addChild(name: "building")
                newItem.addChild(name: "id", value: buildingId)
                newItem.addChild(name: "name", value: buildingName)
                return doc.xml
            } catch {
                print("updateScopeExclusionsAddBuilding failed: \(error)")
                return xmlString
            }
        }

        func updateScopeExclusionsAddDepartment(xmlString: String, departmentName: String, departmentId: String) -> String {
            guard !xmlString.isEmpty else { return "" }
            do {
                let doc = try AEXMLDocument(xml: Data(xmlString.utf8))
                var scopeElem = doc.root["scope"]
                if scopeElem.name == "" { scopeElem = doc.root.addChild(name: "scope") }
                var exclusionsElem = scopeElem["exclusions"]
                if exclusionsElem.name == "" { exclusionsElem = scopeElem.addChild(name: "exclusions") }
                var deps = exclusionsElem["departments"]
                if deps.name == "" { deps = exclusionsElem.addChild(name: "departments") }
                for child in deps.children {
                    if child["id"].value == departmentId || child["name"].value == departmentName { return doc.xml }
                }
                let newItem = deps.addChild(name: "department")
                newItem.addChild(name: "id", value: departmentId)
                newItem.addChild(name: "name", value: departmentName)
                return doc.xml
            } catch {
                print("updateScopeExclusionsAddDepartment failed: \(error)")
                return xmlString
            }
        }

        func updateScopeExclusionsAddUser(xmlString: String, userName: String, userId: String) -> String {
            guard !xmlString.isEmpty else { return "" }
            do {
                let doc = try AEXMLDocument(xml: Data(xmlString.utf8))
                var scopeElem = doc.root["scope"]
                if scopeElem.name == "" { scopeElem = doc.root.addChild(name: "scope") }
                var exclusionsElem = scopeElem["exclusions"]
                if exclusionsElem.name == "" { exclusionsElem = scopeElem.addChild(name: "exclusions") }
                var users = exclusionsElem["users"]
                if users.name == "" { users = exclusionsElem.addChild(name: "users") }
                for child in users.children {
                    if child["id"].value == userId || child["name"].value == userName { return doc.xml }
                }
                let newItem = users.addChild(name: "user")
                newItem.addChild(name: "id", value: userId)
                newItem.addChild(name: "name", value: userName)
                return doc.xml
            } catch {
                print("updateScopeExclusionsAddUser failed: \(error)")
                return xmlString
            }
        }

        func updateScopeExclusionsAddUserGroup(xmlString: String, groupName: String, groupId: String) -> String {
            guard !xmlString.isEmpty else { return "" }
            do {
                let doc = try AEXMLDocument(xml: Data(xmlString.utf8))
                var scopeElem = doc.root["scope"]
                if scopeElem.name == "" { scopeElem = doc.root.addChild(name: "scope") }
                var exclusionsElem = scopeElem["exclusions"]
                if exclusionsElem.name == "" { exclusionsElem = scopeElem.addChild(name: "exclusions") }
                var groups = exclusionsElem["user_groups"]
                if groups.name == "" { groups = exclusionsElem.addChild(name: "user_groups") }
                for child in groups.children {
                    if child["id"].value == groupId || child["name"].value == groupName { return doc.xml }
                }
                let newItem = groups.addChild(name: "user_group")
                newItem.addChild(name: "id", value: groupId)
                newItem.addChild(name: "name", value: groupName)
                return doc.xml
            } catch {
                print("updateScopeExclusionsAddUserGroup failed: \(error)")
                return xmlString
            }
        }
    
    //    #################################################################################
    //    updatePolicyScopeGroup
    //    #################################################################################
    
    
    func updatePolicyScopeGroup(server: String, authToken: String, resourceType: ResourceType, policyName: String, policyID: String, computer_groupID: String, computer_groupName: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        self.separationLine()
        print("updateSSName XML")
        print("updateSSName is set as:\(policyName)")
        
        xml = """
        <policy>
                <scope>
                    <all_computers>false</all_computers>
                    <computers/>
                    <computer_groups>
                        <computer_group>
                            <id>\(computer_groupID)</id>
                            <name>\(computer_groupName)</name>
                        </computer_group>
                    </computer_groups>
                </scope>
        </policy>
        """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running updateSSName name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    //    #################################################################################
    //    updatePolicyScopeLimitations2Groups
    //    #################################################################################
    
    func updatePolicyScopeLimitations2Groups(server: String, authToken: String, resourceType: ResourceType, policyName: String, policyID: String, ldapUserGroupID: String, ldapUserGroupName: String, ldapUserGroupID2: String, ldapUserGroupName2: String) {
        
        //        Updated the limtations for a policy to 2 ldap groups
        
        let resourcePath = getURLFormat(data: (resourceType))
        let receivedPolicyID = String(describing: policyID)
        var xml: String
        self.separationLine()
        print("Running updatePolicyScopeLimitations2Groups")
        print("Policy name is set as:\(policyName)")
        print("receivedPolicyID is set as:\(receivedPolicyID)")
        print("Policy id is set as:\(policyID)")
        print("ldapUserGroupName is set as:\(ldapUserGroupName)")
        print("ldapUserGroupName2 is set as:\(ldapUserGroupName2)")
        print("ldapUserGroupID is set as:\(ldapUserGroupID)")
        print("ldapUserGroupID2 is set as:\(ldapUserGroupID2)")
        
        xml = """
                   <policy>
                           <scope>
                           <all_computers>true</all_computers>
                           <all_computers>true</all_computers>
                           <limit_to_users>
                                <user_groups>
                                    <user_group>\(ldapUserGroupName)</user_group>
                                    <user_group>\(ldapUserGroupName2)</user_group>
                                </user_groups>
                            </limit_to_users>
                            <limitations>
                                <users/>
                                <user_groups>
                                    <user_group>
                                        <id>\(ldapUserGroupID)</id>
                                        <name>\(ldapUserGroupName)</name>
                                    </user_group>
                                    <user_group>
                                        <id>\(ldapUserGroupID2)</id>
                                        <name>\(ldapUserGroupName2)</name>
                                    </user_group>
                                </user_groups>
                                <network_segments/>
                                <ibeacons/>
                            </limitations>
                           </scope>
                   </policy>
                   """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(receivedPolicyID)
                print("Running updatePolicyScopeLimitations2Groups name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                self.separationLine()
                print("Passing to sendRequestAsXML")
                // print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                //                    appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    //    #################################################################################
    //    updatePolicyScopeLimitations
    //    #################################################################################
    
    func updatePolicyScopeToAll(server: String, authToken: String, resourceType: ResourceType, policyName: String, policyID: String, building: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        self.separationLine()
        print("updateSSName XML")
        print("updateSSName is set as:\(policyName)")
        
        var xml = """
                <policy>
                        <scope>
                            <all_computers>true</all_computers>
                        </scope>
                </policy>
            """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running updateSSName name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
        self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    
    //    #################################################################################
    //    updatePolicyScopeExclusions - manual
    //    #################################################################################
    
    
    func updatePolicyScopeExclusions(server: String, authToken: String, resourceType: ResourceType, policyName: String, policyID: String, building: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        self.separationLine()
        print("updateSSName XML")
        print("updateSSName is set as:\(policyName)")

        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running updateSSName name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
        self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
            }
        }
        else {
            print("Nothing to do")
        }
    }

    func getLdapGroupsSearch(server: String, search: String, authToken: String) async throws {
        
        print("Running getLdapGroupsSearch")
        let jamfURLQuery = server + "/api/v1/ldap/groups?q=" + search
        let url = URL(string: jamfURLQuery)!
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            print("Response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
        
        print("Request was successful")
        let decoder = JSONDecoder()
        print("Set decoder was successful")
        self.allLDAPSearchResponse = try decoder.decode(LDAPSearchResponse.self, from: data)
        print("Set allLdapGroupsCombined was successful")
        self.allLdapCustomGroupsCombinedArray = allLDAPSearchResponse.results

    }

    
    func getLdapServers(server: String, authToken: String ) async throws {

        let jamfURLQuery = server + "/JSSResource/ldapservers"
        let url = URL(string: jamfURLQuery)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getLdapServers")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            print("Data is:\(data)")
            print("Response is:\(response)")
            print("URL is:\(url)")
            throw JamfAPIError.badResponseCode
        }
        print("Request was successful")
        let decoder = JSONDecoder()
        self.allLdapServers = try decoder.decode(LDAPServers.self, from: data).ldapServers

    }
    
    
    // Flush log for policies with configurable interval and log_id specifying computers
    func flushLogComputer(serverURL: String, authToken: String, interval: String, policyId: String, computer_id: String) async throws {
//        Supported values are a combination of [Zero, One, Two, Three, Six] and [Days, Weeks, Months, Years]. For example: "Three+Months"
        
        
        let parameters = """
        <logflush>
            <log>policy</log>
            <log_id>\(policyId)</log_id>
            <interval>\(interval)</interval>
            <computers>
                <computer>
                    <id>\(computer_id)</id>
                </computer>
            </computers>
        </logflush>
        """
        let postData = parameters.data(using: .utf8)
        guard let url = URL(string: "\(serverURL)/JSSResource/logflush") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        request.httpBody = postData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            print("Data is:\(data)")
            print("Response is:\(response)")
            print("URL is:\(url)")
            throw JamfAPIError.badResponseCode
        }
        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else {
//                print(String(describing: error))
//                return
//            }
//            print(String(data: data, encoding: .utf8) ?? "No response data")
//        }
//        task.resume()
    }
    
    
    // Flush log for a specific interval using RESTful path
    func logFlushInterval(server: String, policyId: String, logType: String, interval: String,authToken: String) async throws {
        let jamfURLQuery = "\(server)/JSSResource/logflush/\(logType)/id/\(policyId)/interval/\(interval)"
        
        guard let url = URL(string: jamfURLQuery) else {
            print("Invalid URL: \(jamfURLQuery)")
            return
        }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
      
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            print("Data is:\(data)")
            print("Response is:\(response)")
            print("URL is:\(url)")
            throw JamfAPIError.badResponseCode
        }
    }
    
    
}
