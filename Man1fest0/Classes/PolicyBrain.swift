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
    @EnvironmentObject var networkController: NetBrain
    
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
        
        guard let data = try? Data(xmlContent.utf8)
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
                        print(response!)
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
            networkController.deletePolicy(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken )
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
                        print(response!)
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
        //        Unassigned scripts
        //        ########################################
        print(self.separationLine())
        print("everything not in both - scripts not in use")
        self.unassignedScriptsSet = self.allScriptsByNameSet.symmetricDifference(self.assignedScriptsByNameSet)
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
        print("Running readXMLDataFromString - NetBrain")
        print("xmlContent is:\(xmlContent)")
        
        guard let data = try? Data(xmlContent.utf8)
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
        
        readXMLDataFromString(xmlContent: xmlContent)
        
        if self.aexmlDoc.name.isEmpty != true {
            
            separationLine()
            print("Running clonePolicy - xmlDoc available:\(policyName)")
            let sem = DispatchSemaphore.init(value: 0)
            let wholeDoc = aexmlDoc.root
            let policyGeneral = aexmlDoc.root["general"]
            let lastID = policyGeneral["id"].last!
            let reference = policyGeneral["name"].last!
            //    #################################################################################
            //        ADD NEW STRINGS
            //    #################################################################################
            separationLine()
            print("Add new policy name:\(policyName)")
            policyGeneral.addChild(name: "name", value: policyName)
            print("Add new policy id:0")
            policyGeneral.addChild(name: "id", value: "0")
            //    #################################################################################
            //        REMOVE LAST STRINGS
            //    #################################################################################
            separationLine()
            print("lastID ID IS:\(lastID.xml)")
            print("Removing:\(lastID.xml)")
            lastID.removeFromParent()
            print("Removing:\(reference.xml)")
            reference.removeFromParent()
            //    #################################################################################
            //    Confirm
            //    #################################################################################
            separationLine()
            print("policyGeneral IS:\(policyGeneral.xml)")
            let updatedPolicy = wholeDoc.xml
            separationLine()
            
//            DEBUG
//            atSeparationLine()
//            print("xml is set as:\(String(describing:updatedPolicy))")
            
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
                            print(response!)
                            return
                        }
                        DispatchQueue.main.async {
                            print("Success! Policy cloned. Update XML")
                            self.updateXML = true
                        }
                    }.resume()
                    sem.wait()
                }
            }
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
                        print(response!)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        print("Success! Package pushed.")
                    }
                }.resume()
                
                sem.wait()
            }
        }
    }
    
    
    
    
    //    #################################################################################
    //    addCustomCommand - to policy
    //    #################################################################################
    
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
    
    
    
    
}

