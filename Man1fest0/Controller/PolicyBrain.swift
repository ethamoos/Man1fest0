//
//  PolicyBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 30/07/2024.
//

import Foundation
import SwiftUI
import AEXML

class PolicyBrain: ObservableObject {
    
//    @EnvironmentObject var layout: Layout
//    @EnvironmentObject var xmlBrain: XmlBrain
    // Use an injected NetBrain reference instead of @EnvironmentObject here so
    // PolicyBrain can be constructed programmatically (previews, app init) and
    // won't crash if a View environment doesn't provide NetBrain.
    var networkController: NetBrain?
    
    @State var debugStatus = true
    
    //    #################################################################################
    //    ############ Process lists - for batch operations
    //    #################################################################################
    
    @Published var computerProcessList: [Computer] = []
    @Published var policyProcessList: [Policy] = []
    @Published var policiesProcessList: [Policy] = []
    @Published var packageProcessList: [Package] = []
    @Published var genericProcessList: [Any] = []
    @Published var processingComplete: Bool = true

    // Replace-policies progress & results (for the ReplacePolicies button)
    @Published var replacePoliciesInProgress: Bool = false
    @Published var replacePoliciesResults: [ReplacePolicyResult] = []

    struct ReplacePolicyResult: Identifiable {
        let id = UUID()
        let policyId: String
        let filename: String
        let success: Bool
        let message: String
    }

    // ── XML Find & Replace ────────────────────────────────────────────────────
    @Published var xmlFindReplaceFiles: [URL] = []
    @Published var xmlFindReplacePreviewResults: [XMLFindReplacePreview] = []
    @Published var xmlFindReplaceApplyResults:   [XMLFindReplaceResult2] = []
    @Published var xmlFindReplaceInProgress: Bool = false
    @Published var xmlFindReplaceApplied:    Bool = false

    struct XMLFindReplacePreview: Identifiable {
        let id = UUID()
        let url: URL
        var filename: String { url.lastPathComponent }
        let matchCount: Int
        let snippet: String     // short excerpt around first match
    }

    struct XMLFindReplaceResult2: Identifiable {
        let id = UUID()
        let filename: String
        let success: Bool
        let replacementsApplied: Int
        let message: String
    }
    
    //    #################################################################################
    //    Packages
    //    #################################################################################
    
    var currentPackageId: Package = (Package(id: (UUID(uuidString: "") ?? UUID()), jamfId: 0, name: "", udid: ""))
    var currentPackageName: Package = (Package(id: (UUID(uuidString: "") ?? UUID()), jamfId: 0, name: "", udid: ""))
    var currentPackageIdInt = 0
    var currentPackageNameString = ""
    
    //    #################################################################################
    //    Scripts
    //    #################################################################################
    
    @State var assignedScripts: [PolicyScripts] = []
    @Published var assignedScriptsByNameDict: [String: String] = [:]
    @State var assignedScriptsByNameSet = Set<String>()
    @State var assignedScriptsArray: [String] = []

    
    @State var clippedScripts = Set<String>()
    @State var unassignedScriptsSet = Set<String>()
    @Published var unassignedScriptsArray: [String] = []
    @State var unassignedScriptsByNameDict: [String: String] = [:]
    
    @State var allScripts: [ScriptClassic] = []
    @State var allScriptsByNameDict: [String: String] = [:]
    @State var allScriptsByNameSet = Set<String>()
    
    @State var totalScriptsNotUsed = 0
    
    //    #################################################################################
    //    Icons
    //    #################################################################################
//    @State var iconId = ""
//    @State var iconName = ""
//    @State var iconUrl = ""
    
    //    #################################################################################
    //    XML data
    //    #################################################################################
    
    var aexmlDoc: AEXMLDocument = AEXMLDocument()
    var computerGroupMembersXML: String = ""
    var policyAsXMLScope: String = ""
    var currentPolicyAsXML: String = ""
    var newPolicyAsXML: String = ""
    var updateXML: Bool = false

#if os(macOS)
    @State var element: XMLNode = XMLNode()
    @State var element2: XMLNode = XMLNode()
    @State var item: XMLNode = XMLNode()
    @State var item2: XMLNode = XMLNode()
#endif

    
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
    //    XML Global Operations
    //    ##################################################
    
    //
    //
    //    #################################################################################
    //    readXMLDataFromStringScopingBrain
    //    #################################################################################
    //
    //    #################################################################################
    //    Enums
    //    #################################################################################

    enum NetError: Error {
        case couldntEncodeNamePass
        case badResponseCode
    }
    
    
    
    
    func readXMLDataFromStringPolicyBrain(xmlContent: String) {
        //        Reads xml and stores in a variable
        
        self.separationLine()
        print("Running readXMLDataFromStringPolicyBrain")
        //        print("xmlContent is:\(xmlContent)")
        
        guard let data = xmlContent.data(using: .utf8)
        else {
            print("Sample XML Data error.")
            return
        }
        do {
            self.aexmlDoc = try AEXMLDocument(xml: data)
        }
        catch {
            print("\(error)")
        }
    }

    //    #################################################################################
    //    sendRequestAsXML
    //    #################################################################################

    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String ) {
        //        Request in XML format
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        self.separationLine()
        print("Running sendRequestAsXML Policy Brain function - resourceType is set as:\(resourceType)")
        //        DEBUG
        print("url is:\(url)")
//        print("username is:\(username)")
        //        print("password is:\(password)")
        //            self.separationLine()
        print("xml as a string is:")
        print(xml)
        self.separationLine()
        print("xmldata is:\(String(describing: xmldata))")
        print(String(describing: xmldata))
        self.separationLine()
        
        print("httpMethod is:\(httpMethod)")
        //      //  print("authToken is:\(authToken)")
        
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
                self.separationLine()
                //                print("Posting so response is not necessarily important!")
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
                //                self.appendStatus(text)
                print(text)
            }
        }
        dataTask.resume()
    }
//
//    //    #################################################################################
//    //    Create Policies - via XML
//    //    #################################################################################
//
//    func createNewPolicyXML(server: String, authToken: String, policyName: String, customTrigger: String, departmentID: String, notificationName: String, notificationStatus: String, iconId: String, iconName: String, iconUrl: String, selfServiceEnable: String ) {
//
//        var xml:String
////        let sem = DispatchSemaphore.init(value: 0)
//
//        self.separationLine()
//        print("DEBUGGING - DISABLE IF NOT TESTING")
//        self.separationLine()
//        print("Running createNewPolicyXML - PolicyBrain")
////        print("username is set as:\(username)")
//        //        print("password is set as:\(password)")
//        //        print("authToken is set as:\(authToken)")
//        print("Url is set as:\(server)")
//        print("policyName is set as:\(policyName)")
//        print("notificationName is set as:\(notificationName)")
//        print("notificationStatus is set as:\(notificationStatus)")
//
//        //    #################################################################################
//        //    newPolicyXml
//        //    #################################################################################
//
//        xml = """
//        <?xml version="1.0" encoding="utf-8"?>
//        <policy>
//            <general>
//                <id>0</id>
//                <name>\(policyName)</name>
//                <enabled>true</enabled>
//                <trigger>EVENT</trigger>
//                <trigger_checkin>false</trigger_checkin>
//                <trigger_enrollment_complete>false</trigger_enrollment_complete>
//                <trigger_login>false</trigger_login>
//                <trigger_logout>false</trigger_logout>
//                <trigger_network_state_changed>false</trigger_network_state_changed>
//                <trigger_startup>false</trigger_startup>
//                <trigger_other>\(customTrigger)</trigger_other>
//                <frequency>Ongoing</frequency>
//                <retry_event>none</retry_event>
//                <retry_attempts>-1</retry_attempts>
//                <notify_on_each_failed_retry>false</notify_on_each_failed_retry>
//                <location_user_only>false</location_user_only>
//                <target_drive>/</target_drive>
//                <offline>false</offline>
//                <category>
//                </category>
//                <date_time_limitations>
//                    <activation_date/>
//                    <activation_date_epoch>0</activation_date_epoch>
//                    <activation_date_utc/>
//                    <expiration_date/>
//                    <expiration_date_epoch>0</expiration_date_epoch>
//                    <expiration_date_utc/>
//                    <no_execute_on/>
//                    <no_execute_start/>
//                    <no_execute_end/>
//                </date_time_limitations>
//                <network_limitations>
//                    <minimum_network_connection>No Minimum</minimum_network_connection>
//                    <any_ip_address>true</any_ip_address>
//                    <network_segments/>
//                </network_limitations>
//                <override_default_settings>
//                    <target_drive>default</target_drive>
//                    <distribution_point/>
//                    <force_afp_smb>false</force_afp_smb>
//                    <sus>default</sus>
//                    <netboot_server>current</netboot_server>
//                </override_default_settings>
//                <network_requirements>Any</network_requirements>
//                <site>
//                    <id>-1</id>
//                    <name>None</name>
//                </site>
//            </general>
//            <scope>
//                <all_computers>false</all_computers>
//            </scope>
//            <self_service>
//                <use_for_self_service>\(selfServiceEnable)</use_for_self_service>
//                <self_service_display_name/>
//                <install_button_text>Install</install_button_text>
//                <reinstall_button_text>Reinstall</reinstall_button_text>
//                <self_service_description/>
//                <force_users_to_view_description>false</force_users_to_view_description>
//                <self_service_icon>
//                    <id>\(iconId)</id>
//                    <filename>\(iconName)</filename>
//                    <uri>\(iconUrl)</uri>
//                </self_service_icon>
//                <feature_on_main_page>false</feature_on_main_page>
//                <self_service_categories/>
//                <notification>\(notificationStatus)</notification>
//                <notification>Self Service</notification>
//                <notification_subject>\(notificationName)</notification_subject>
//                <notification_message/>
//            </self_service>
//        </policy>
//        """
////
//
//        //              ################################################################################
//        //              DEBUG
//        //              ################################################################################
//
//        self.separationLine()
//        print("Setting newPolicyAsXML variable - PolicyBrain")
//        self.newPolicyAsXML = xml
//        //        print("Printing initial xml data for new policy")
//        //        print(self.newPolicyAsXML)
//        //        self.separationLine()
//        print("XML variable is set as:")
//        print(xml)
//        print("Reading xml data with AEXML")
//        self.readXMLDataFromStringPolicyBrain(xmlContent: xml)
//
//        print("XML data is now stored in:self.aexmlDoc.root - PolicyBrain")
//        print(self.aexmlDoc.root)
//        self.separationLine()
//
//        //        if URL(string: server) != nil {
//        //            if let serverURL = URL(string: server) {
//        //
//        //                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
//        //                let xmldata = xml.data(using: .utf8)
//        //                print(url)
//        //                // Request options
//        //                var request = URLRequest(url: url)
//        //                request.httpMethod = "POST"
//        //                request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
//        //                request.setValue("application/xml", forHTTPHeaderField: "Accept")
//        //                request.httpBody = xmldata
//        //                let config = URLSessionConfiguration.default
//        //                config.httpAdditionalHeaders = ["Authorization": "Bearer \(authToken)"]
//        //                URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
//        //                    defer { sem.signal() }
//        //
//        //                    guard let httpResponse = response as? HTTPURLResponse,
//        //                          (200...299).contains(httpResponse.statusCode) else {
//        //                        print("Bad Credentials")
//        //                        print(response!)
//        //                        return
//        //                    }
//        //
//        //                }.resume()
//        //
//        //                sem.wait()
//        //            }
//        //        }
//    }
//
    
    
    //    #################################################################################
    //    Post new policy - via XML
    //    #################################################################################
    
    
    func postNewPolicy(server: String, authToken: String, xml: String ) {
        
        let sem = DispatchSemaphore.init(value: 0)
        
        
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        self.atSeparationLine()
        self.separationLine()
        print("Running postNewPolicy")
//        print("username is set as:\(username)")
        //        print("password is set as:\(password)")
        print("Url is set as:\(server)")
        //        print("authToken is set as:\(authToken)")
        self.separationLine()
        print("XML is set as:")
        print(xml)
        self.atSeparationLine()
        
        //              ################################################################################
        //              DEBUG - END
        //              ################################################################################
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                let xmldata = xml.data(using: .utf8)
                print(url)
                // Request options
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                request.setValue("application/xml", forHTTPHeaderField: "Accept")
                request.httpBody = xmldata
                let config = URLSessionConfiguration.default
                config.httpAdditionalHeaders = ["Authorization": "Bearer \(authToken)"]
                URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
                    defer { sem.signal() }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Bad Credentials")
                        print(String(describing: response))
                        return
                    }
                }.resume()
                sem.wait()
            }
        }
    }
    
    
    
    
    
    //    ##################################################
    //    addComputerToGroup
    //    ##################################################
    
    
    
    //    func addComputerToGroup(xmlContent: String, computerName: String, authToken: String, computerId: String,groupId: String, resourceType: ResourceType, server: String) {
    //        readXMLDataFromString(xmlContent: xmlContent)
    //
    //        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
    //        let url = URL(string: jamfURLQuery)!
    //self.separationLine()
    //        print("Running addComputerToGroup")
    //        print("xmlContent is:\(xmlContent)")
    //        print("url is:\(url)")
    //        print("computerName is:\(computerId)")
    //        print("computerId is:\(computerId)")
    //
    //        let computers = self.aexmlDoc.root["computers"].addChild(name: "computer")
    //        computers.addChild(name: "id", value: computerId)
    //        computers.addChild(name: "name", value: computerName)
    //        print("updatedContent is:\(self.aexmlDoc.root.xml)")
    //        let jamfCount = computers.count
    //        print("jamfCount is:\(jamfCount)")
    //
    //        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")

    //
    //    }
    
//    // ######################################################################################
//    // addCategoryToPolicy
//    // ######################################################################################
//
//
//    func addCategoryToPolicy(xmlContent: String,authToken: String, resourceType: ResourceType, server: String, policyId: String, categoryName: String, categoryId: String, newPolicyFlag: Bool ) {
//
//        self.readXMLDataFromStringPolicyBrain(xmlContent: xmlContent)
//
//        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
//        let url = URL(string: jamfURLQuery)!
//        self.separationLine()
//        print("Running addCategoryToPolicy")
//        print("xmlContent is:\(xmlContent)")
//        print("url is:\(url)")
//        print("categoryName is:\(categoryName)")
//        print("categoryId is:\(categoryId)")
//        let category = self.aexmlDoc.root["general"].addChild(name: "category")
//        //        if categoryId != "" {
//        //            category.addChild(name: "id", value: categoryId)
//        //        }
//        if categoryName != "" && categoryId != "" {
//            category.addChild(name: "name", value: categoryName)
//
//
//        print("updatedContent is:")
//        print(xmlContent)
//
//            if newPolicyFlag == false {
//                print("Posting data")
//
//
//                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xmlContent, httpMethod: "PUT")
//            }
//
//        } else {
//            print("Category is not set - not updating")
//        }
//    }
//
    
    
    
    
    
    
    
    
    
    
    //    ##################################################
    //    Batch operations
    //    ##################################################
    
    
    //    #################################################################################
    //    Delete polcies selection
    //    #################################################################################
    
    
    func processDeletePolicies(selection:  Set<Policy>, server: String, authToken: String, resourceType: ResourceType) {
        
        self.separationLine()
        print("Running: processDeletePolicies")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
        for eachItem in selection {
            self.separationLine()
            print("Items as Dictionary is \(eachItem)")
            let policyID = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.jamfId ?? 0)
            print("Current policyID is:\(policyID)")
            print("Current jamfID is:\(String(describing: jamfID))")
            // networkController may be nil in preview/test contexts; call the
            // main-actor-isolated method on the MainActor to satisfy Swift's
            // concurrency checks. Use a Task so we don't block the caller.
            if let nc = self.networkController {
                Task {
                    await MainActor.run {
                        nc.deletePolicy(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken)
                    }
                }
            } else {
                print("processDeletePolicies: no networkController available")
            }
            print("List is:\(packageProcessList)")
        }
        self.separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    //    #################################################################################
    //    Remove all packages from selected policies
    //    #################################################################################
    
    
    func removeAllPackagesSelectionNestedFunction(selection:  Set<Policy>, server: String, authToken: String, operation:(String, String, String)->Void ) {
        
//    #################################################################################
//        Calling function: removeAllPackagesManual         with parameters
//        (server: server, authToken: networkController.authToken, policyID: String(describing: policyID)
//    #################################################################################

        self.separationLine()
        print("Running: removeAllPackagesSelection")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
        for eachItem in selection {
            self.separationLine()
            print("Items as Dictionary is \(eachItem)")
            let policyID = String(describing:eachItem.id)
            print("Current policyID is:\(policyID)")

            operation(server, authToken, policyID)
            
        }
        self.separationLine()
//        print("Finished - Set processingComplete to true")
//        self.processingComplete = true
//        print(String(describing: self.processingComplete))
    }
    
    
    
    //    #################################################################################
    //    testPostNewPolicyXML - check if static XML is working
    //    #################################################################################
    
    
    func testPostNewPolicyXML(server: String, authToken: String, xml: String ) {
        
        let sem = DispatchSemaphore.init(value: 0)
        
        
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        self.atSeparationLine()
        self.separationLine()
        print("Running testPostNewPolicyXML")
//        print("username is set as:\(username)")
        //        print("password is set as:\(password)")
        print("Url is set as:\(server)")
        //        print("authToken is set as:\(authToken)")
        self.separationLine()
        print("XML is set as:")
        print(xml)
        self.atSeparationLine()
        
        //              ################################################################################
        //              DEBUG - END
        //              ################################################################################
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                let xmldata = xml.data(using: .utf8)
                print(url)
                // Request options
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                request.setValue("application/xml", forHTTPHeaderField: "Accept")
                request.httpBody = xmldata
                let config = URLSessionConfiguration.default
                config.httpAdditionalHeaders = ["Authorization": "Bearer \(authToken)"]
                URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
                    defer { sem.signal() }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Bad Credentials")
                        print(String(describing: response))
                        return
                    }
                }.resume()
                sem.wait()
            }
        }
    }
    
    //  ########################################
    //  getScriptsInUse
    //  ########################################
    
    
    func getScriptsInUse (allPoliciesDetailed: [PolicyDetailed?] ) {
        
        for eachPolicy in allPoliciesDetailed {
            print("Policy is:\(String(describing: eachPolicy))")
            let scriptsFound: [PolicyScripts]? = eachPolicy?.scripts
            
            for script in scriptsFound ?? [] {
                print("Script is:\(script)")
                
                //        ########################################
                //                Convert to dict
                //        ########################################
                
                self.assignedScriptsByNameDict[script.name ?? "" ] = String(describing: script.jamfId)
                self.assignedScripts.insert(script, at: 0)
            }
        }
    }
    
    func setValues(assignedScriptsArray: [String], unassignedScriptsArray: [String]) {
        
        print("Setting script values")
        self.assignedScriptsArray = assignedScriptsArray
        self.unassignedScriptsArray = unassignedScriptsArray
        
    }
    
    func getScriptValues(allScripts: [ScriptClassic]) {
        
        //        ########################################
        //                Convert all scripts to dict
        //        ########################################
        
        for script in allScripts {
            
            self.allScriptsByNameDict[script.name ] = String(describing: script.jamfId)
            
        }
        
        //        ########################################
        //        DEBUG
        //        ########################################
        //        print("allScriptsByNameDict is:")
        //        print(allScriptsByNameDict)
        
        print(self.separationLine())
        //        print("assignedScriptsByNameDict is:")
        //        print(assignedScriptsByNameDict)
        print("assignedScriptsByNameDict initial count is:\(self.assignedScriptsByNameDict.count)")
        
        //        ########################################
        //        All Scripts - convert to set
        //        ########################################
        self.allScriptsByNameSet = Set(Array(self.allScriptsByNameDict.keys))
        //        ########################################
        //        Assigned Scripts - All scripts found in policies
        //        ########################################
        self.assignedScriptsByNameSet = Set(Array(self.assignedScriptsByNameDict.keys))
        //        ########################################
        //        Unassigned scripts (those in allScripts but not in assigned)
        //        ########################################
        print(self.separationLine())
        print("everything not in both - scripts not in use")
        // Use set subtraction to obtain scripts present in all scripts but not assigned
        self.unassignedScriptsSet = self.allScriptsByNameSet.subtracting(self.assignedScriptsByNameSet)
        print(self.unassignedScriptsSet.count)
        print(self.separationLine())
        print("unassignedScriptsArray")
        self.unassignedScriptsArray = Array(self.unassignedScriptsSet)
        print(self.unassignedScriptsArray.count)
        print("--------------------------------------------")
        print("unusedScripts are:")
        print(self.unassignedScriptsByNameDict.count)
        
        //        ########################################
        //                Convert all unassignedscripts to dict
        //        ########################################
        print("All unnassigned Set")
        //        for script in self.unassignedScriptsSet {
        //            print("Script in scriptSet is:\(script)")
        //            print("Script is:\(script) - add to allScriptsByNameDict")
        //        //            assignedScripts.append(script)
        ////                    unassignedScriptsByNameDict[script.name ] = script.jamfId
        //        }
        print(self.separationLine())
        print("One set minus the contents of another - scripts not in use")
        self.clippedScripts = self.allScriptsByNameSet.subtracting(self.assignedScriptsByNameSet)
        print(self.clippedScripts.count)
        
    }
    
    
    func readXMLDataFromString(xmlContent: String) {
        self.separationLine()
        separationLine()
        print("Running readXMLDataFromString - PolicyBrain")
//        print("xmlContent is:\(xmlContent)")
        
        guard let data = xmlContent.data(using: .utf8)
        else {
            print("Sample XML Data error.")
            return
        }
        do {
            self.aexmlDoc = try AEXMLDocument(xml: data)
        }
        catch {
            print("\(error)")
        }
    }
    
//    CLONING AND NEW POLICIES
    
    
    //    #################################################################################
    //    clonePolicy
    //    #################################################################################
    
    func clonePolicy(xmlContent: String, server: String, policyName: String, authToken: String ) {
        
        // Parse the provided XML directly so we do not rely on shared parser state.
        let trimmed = xmlContent.trimmingCharacters(in: .whitespacesAndNewlines)
        print("clonePolicy called for '")
        print("  policyName: \(policyName)")
        print("  xml length: \(trimmed.count)")
        if trimmed.count > 0 {
            let head = String(trimmed.prefix(500))
            print("  xml head: \n\(head)\n--- end head ---")
            if !trimmed.contains("<general>") {
                print("  xml does not contain <general> tag (will attempt to parse anyway)")
            }
        } else {
            print("clonePolicy: provided xmlContent is empty")
            return
        }

        do {
            let doc = try AEXMLDocument(xml: Data(trimmed.utf8))
            separationLine()
            print("Running clonePolicy - xmlDoc parsed; will edit and POST. policyName=\(policyName)")
            let sem = DispatchSemaphore.init(value: 0)

            let wholeDoc = doc.root
            print("doc.root name=\(wholeDoc.name); children=\(wholeDoc.children.map({ $0.name }))")
            let policyGeneral = doc.root["general"]
            print("policyGeneral name=\(policyGeneral.name); children names=\(policyGeneral.children.map({ $0.name }))")

            // Ensure we have a <general> node with name/id children; be defensive and remove existing
            // name/id nodes then add ours so we avoid accidental deletion of newly added nodes.
            let existingNameNodes = policyGeneral.children.filter { $0.name == "name" }
            let existingIdNodes = policyGeneral.children.filter { $0.name == "id" }

            // Remove existing name/id nodes (if any)
            for n in existingNameNodes { n.removeFromParent() }
            for i in existingIdNodes { i.removeFromParent() }

            // Add our new name and id
            print("Add new policy name:\(policyName)")
            _ = policyGeneral.addChild(name: "name", value: policyName)
            print("Add new policy id:0")
            _ = policyGeneral.addChild(name: "id", value: "0")

            // Debug: show the general block
            print("policyGeneral after edit:\n\(policyGeneral.xml)")

            let updatedPolicy = wholeDoc.xml
            separationLine()

            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                    let xmldata = updatedPolicy.data(using: .utf8)
                    separationLine()
                    print("url is set as:\(url)")
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                    request.setValue("application/xml", forHTTPHeaderField: "Accept")
                    request.httpBody = xmldata
                    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                    let config = URLSessionConfiguration.default
                    URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
                        defer { sem.signal() }
                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            print("Bad Credentials")
                            print(String(describing: response))
                            return
                        }
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                print("Success! Policy cloned. Update XML")
                                self.updateXML = true
                                // After creating the clone, refresh the global policies list.
                                // Wait briefly to allow the server to finish processing the new policy.
                                        Task { [weak self] in
                                            guard let self = self else { return }
                                            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
                                                    do {
                                                        guard let nc = self.networkController else {
                                                            print("clonePolicy: no networkController available to refresh policies")
                                                            return
                                                        }
                                                        try await nc.getAllPolicies(server: server, authToken: authToken)
                                                        print("Refreshed policies after clone")
                                                    } catch {
                                                        print("Failed to refresh policies after clone: \(error)")
                                                    }
                                        }
                            }
                    }.resume()
                    sem.wait()
                }
            }
        } catch {
            print("clonePolicy: Failed to parse xmlContent: \(error)")
            return
        }
    }
    
    
    func createPolicyManual(xmlContent: String,  server: String, resourceType: ResourceType, policyName: String, authToken: String) {
        
        let sem = DispatchSemaphore.init(value: 0)
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                let xmldata = xmlContent.data(using: .utf8)
                separationLine()
                print("url is set as:\(url)")
                print("Running createPolicyManual for policyName:\(policyName)")
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                request.setValue("application/xml", forHTTPHeaderField: "Accept")
                request.httpBody = xmldata
                let config = URLSessionConfiguration.default
                let authString = "Bearer \(authToken)"
                config.httpAdditionalHeaders = ["Authorization" : authString]
                URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
                    defer { sem.signal() }
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Bad Credentials")
                        print(String(describing: response))
                        return
                    }
                    
                    DispatchQueue.main.async {
                        print("Success! Policy created.")
                    }
                }.resume()
                
                sem.wait()
            }
        }
    }
    
    
    func replacePolicy(xmlContent: String,  server: String, resourceType: ResourceType, policyId: String, authToken: String) {
        
        let sem = DispatchSemaphore.init(value: 0)
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/\(policyId)")
                let xmldata = xmlContent.data(using: .utf8)
                separationLine()
                print("Runing replace policy with ID \(policyId)")
                print("url is set as:\(url)")
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                request.setValue("application/xml", forHTTPHeaderField: "Accept")
                request.httpBody = xmldata
                let config = URLSessionConfiguration.default
                let authString = "Bearer \(authToken)"
                config.httpAdditionalHeaders = ["Authorization" : authString]
                URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
                    defer { sem.signal() }
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Bad Credentials")
                        print(String(describing: response))
                        return
                    }
                    
                    DispatchQueue.main.async {
                        print("Success! Policy replaced.")
                    }
                }.resume()
                
                sem.wait()
            }
        }
    }
    
    
    
    //    #################################################################################
    //    addCustomCommand - to policy
    //    #################################################################################
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - XML Find & Replace
    // ─────────────────────────────────────────────────────────────────────────

    /// Opens an NSOpenPanel that lets the user pick files AND / OR a folder.
    /// Any chosen folder is scanned recursively for .xml files.
    /// The collected URLs are stored in `xmlFindReplaceFiles`.
    @MainActor
    func showOpenPanelForXMLFindReplace() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.title            = "Select XML Files or a Folder"
        panel.message          = "Choose individual XML files or a folder containing XML files."
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = true
        panel.allowedContentTypes     = [.xml, .folder]
        panel.prompt = "Select"
        guard panel.runModal() == .OK else { return }

        var collected: [URL] = []
        for url in panel.urls {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue {
                // Recursively collect all .xml files from the folder
                if let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let fileURL as URL in enumerator
                    where fileURL.pathExtension.lowercased() == "xml" {
                        collected.append(fileURL)
                    }
                }
            } else if url.pathExtension.lowercased() == "xml" {
                collected.append(url)
            }
        }
        // Deduplicate by path
        var seen = Set<String>()
        xmlFindReplaceFiles = collected.filter { seen.insert($0.path).inserted }
        xmlFindReplacePreviewResults = []
        xmlFindReplaceApplyResults   = []
        xmlFindReplaceApplied        = false
        print("xmlFindReplace: selected \(xmlFindReplaceFiles.count) XML file(s)")
        #endif
    }

    /// Scans each file in `xmlFindReplaceFiles` for `search`, counts matches,
    /// and builds a short snippet showing context around the first match.
    /// Does NOT write any files.
    func previewXMLFindReplace(search: String, replacement: String) {
        guard !search.isEmpty else {
            DispatchQueue.main.async { self.xmlFindReplacePreviewResults = [] }
            return
        }
        DispatchQueue.main.async { self.xmlFindReplaceInProgress = true }

        let files = xmlFindReplaceFiles
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var previews: [XMLFindReplacePreview] = []

            for url in files {
                guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                    previews.append(XMLFindReplacePreview(
                        url: url, matchCount: 0,
                        snippet: "⚠️ Could not read file"
                    ))
                    continue
                }

                // Count occurrences (case-sensitive)
                var count = 0
                var searchRange = content.startIndex..<content.endIndex
                while let range = content.range(of: search, range: searchRange) {
                    count += 1
                    searchRange = range.upperBound..<content.endIndex
                }

                // Build a context snippet around the first match
                var snippet = "No matches"
                if count > 0, let firstRange = content.range(of: search) {
                    let ctxStart = content.index(firstRange.lowerBound,
                                                  offsetBy: -40,
                                                  limitedBy: content.startIndex) ?? content.startIndex
                    let ctxEnd   = content.index(firstRange.upperBound,
                                                  offsetBy: 60,
                                                  limitedBy: content.endIndex) ?? content.endIndex
                    let before   = String(content[ctxStart..<firstRange.lowerBound])
                    let matched  = String(content[firstRange])
                    let after    = String(content[firstRange.upperBound..<ctxEnd])
                    snippet      = "…\(before)[\(matched)]→[\(replacement)]\(after)…"
                }

                previews.append(XMLFindReplacePreview(
                    url: url, matchCount: count, snippet: snippet
                ))
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.xmlFindReplacePreviewResults = previews
                self.xmlFindReplaceInProgress = false
            }
        }
    }

    /// Applies find-and-replace to every file in `xmlFindReplaceFiles`,
    /// writes the result back to the same path, and records per-file results.
    func applyXMLFindReplace(search: String, replacement: String) {
        guard !search.isEmpty else { return }
        DispatchQueue.main.async {
            self.xmlFindReplaceInProgress = true
            self.xmlFindReplaceApplyResults = []
        }

        let files = xmlFindReplaceFiles
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var results: [XMLFindReplaceResult2] = []

            for url in files {
                let filename = url.lastPathComponent
                do {
                    let original  = try String(contentsOf: url, encoding: .utf8)
                    let replaced  = original.replacingOccurrences(of: search, with: replacement)
                    // Count the actual number of replacements made
                    let repCount = original.components(separatedBy: search).count - 1
                    try replaced.write(to: url, atomically: true, encoding: .utf8)
                    results.append(XMLFindReplaceResult2(
                        filename: filename,
                        success: true,
                        replacementsApplied: repCount,
                        message: repCount == 0
                            ? "No matches in \(filename)"
                            : "✓ \(repCount) replacement(s) in \(filename)"
                    ))
                    print("xmlFindReplace: \(repCount) replacement(s) in \(filename)")
                } catch {
                    results.append(XMLFindReplaceResult2(
                        filename: filename,
                        success: false,
                        replacementsApplied: 0,
                        message: "✗ \(filename): \(error.localizedDescription)"
                    ))
                    print("xmlFindReplace error in \(filename): \(error)")
                }
                Thread.sleep(forTimeInterval: 0.05) // tiny pacing
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.xmlFindReplaceApplyResults = results
                self.xmlFindReplaceInProgress   = false
                self.xmlFindReplaceApplied      = true
                let ok   = results.filter { $0.success && $0.replacementsApplied > 0 }.count
                let skip = results.filter { $0.success && $0.replacementsApplied == 0 }.count
                let fail = results.filter { !$0.success }.count
                self.networkController?.messageStore?.show(
                    "XML Find & Replace complete",
                    level: fail == 0 ? .success : .warning,
                    details: "\(ok) file(s) updated, \(skip) unchanged, \(fail) error(s)"
                )
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Replace Policies from XML Files
    // ─────────────────────────────────────────────────────────────────────────

    /// Opens an NSOpenPanel allowing the user to pick one or more XML files.
    /// Returns the selected URLs, or an empty array if the user cancels.
    @MainActor
    func showOpenPanelForXMLFiles() -> [URL] {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.title = "Select Policy XML Files"
        panel.message = "Choose one or more policy XML files to replace. The policy ID is taken from each filename (e.g. 12345.xml → policy 12345)."
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.xml]
        panel.prompt = "Replace"
        guard panel.runModal() == .OK else { return [] }
        return panel.urls
        #else
        return []
        #endif
    }

    /// For each selected XML file:
    ///   1. Reads the file contents as a UTF-8 string.
    ///   2. Extracts the policy ID from the filename (strips extension).
    ///   3. Validates the ID is numeric.
    ///   4. Calls `replacePolicy(xmlContent:server:resourceType:policyId:authToken:)`.
    ///   5. Appends a `ReplacePolicyResult` entry so the UI can show per-file feedback.
    func replacePolicies(from files: [URL], server: String, authToken: String) {
        guard !files.isEmpty else {
            print("replacePolicies: no files supplied")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.replacePoliciesInProgress = true
            self.replacePoliciesResults = []
        }

        separationLine()
        print("replacePolicies: processing \(files.count) file(s)")

        // Process files sequentially on a background queue so we don't block the main thread
        // but also don't overwhelm the server with simultaneous PUTs.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            var results: [ReplacePolicyResult] = []

            for fileURL in files {
                let filename = fileURL.lastPathComponent
                // Extract policy ID: strip the file extension
                let policyId = fileURL.deletingPathExtension().lastPathComponent

                // Validate that the filename stem is a non-empty integer
                guard !policyId.isEmpty, Int(policyId) != nil else {
                    print("replacePolicies: skipping '\(filename)' — filename stem '\(policyId)' is not a numeric policy ID")
                    results.append(ReplacePolicyResult(
                        policyId: policyId,
                        filename: filename,
                        success: false,
                        message: "Filename '\(filename)' does not contain a numeric policy ID — skipped."
                    ))
                    continue
                }

                // Read XML content
                let xmlContent: String
                do {
                    xmlContent = try String(contentsOf: fileURL, encoding: .utf8)
                } catch {
                    print("replacePolicies: failed to read '\(filename)': \(error)")
                    results.append(ReplacePolicyResult(
                        policyId: policyId,
                        filename: filename,
                        success: false,
                        message: "Could not read file: \(error.localizedDescription)"
                    ))
                    continue
                }

                guard !xmlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    print("replacePolicies: '\(filename)' is empty — skipping")
                    results.append(ReplacePolicyResult(
                        policyId: policyId,
                        filename: filename,
                        success: false,
                        message: "File '\(filename)' is empty — skipped."
                    ))
                    continue
                }

                print("replacePolicies: replacing policy ID \(policyId) from '\(filename)'")
                self.replacePolicy(
                    xmlContent: xmlContent,
                    server: server,
                    resourceType: .policyDetail,
                    policyId: policyId,
                    authToken: authToken
                )

                results.append(ReplacePolicyResult(
                    policyId: policyId,
                    filename: filename,
                    success: true,
                    message: "Replace request sent for policy \(policyId)."
                ))

                // Small delay between requests to avoid overwhelming the server
                Thread.sleep(forTimeInterval: 0.3)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.replacePoliciesResults = results
                self.replacePoliciesInProgress = false
                let successCount = results.filter { $0.success }.count
                let failCount = results.count - successCount
                print("replacePolicies: complete — \(successCount) sent, \(failCount) skipped/failed")
                self.networkController?.messageStore?.show(
                    "Replace Policies complete",
                    level: failCount == 0 ? .success : .warning,
                    details: "\(successCount) replaced, \(failCount) skipped/failed"
                )
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────

    func addCustomCommand(server: String, authToken: String, policyID: String, command: String) {
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
//        let policyIDString = String(policyID)
        var xml: String
        print("Running scopeAllComputersAndUsers")
        
                xml = """
                        <policy>
                            <files_processes>
                                <run_command>\(command)</run_command>
                            </files_processes>
                        </policy>
                    
                    """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
            }
        }
    }
    
    func clearCustomCommand(server: String, authToken: String, policyID: String, command: String) {
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
//        let policyIDString = String(policyID)
        var xml: String
        print("Running scopeAllComputersAndUsers")
        
                xml = """
                        <policy>
                            <files_processes>
                                <run_command>\(command)</run_command>
                            </files_processes>
                        </policy>
                    
                    """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
            }
        }
    }
    
    
    

}
