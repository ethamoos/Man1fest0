//
//  XmlBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 08/07/2024.
//

import Foundation
import SwiftUI
import AEXML

class XmlBrain: ObservableObject {
    
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var policyController: PolicyBrain
    @EnvironmentObject var importExportBrain: ImportExportBrain

//    #################################################################################
//    DEBUG STATUS
//    #################################################################################

    @State var debugStatus = false

#if os(macOS)

    @State var element: XMLNode = XMLNode()
    @State var element2: XMLNode = XMLNode()
    @State var item: XMLNode = XMLNode()
    @State var item2: XMLNode = XMLNode()

#endif

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
    //    XML data
    //    #################################################################################
    @Published var xmlDoc: AEXMLDocument = AEXMLDocument()

    @Published var computerGroupMembersXML: String = ""
    @Published var currentPolicyAsXML: String = ""
    @Published var updateXML: Bool = false
    var policyAsXMLScope: String = ""
    var newPolicyAsXML: String = ""
    @Published var currentPolicyScopeXML: String = ""
    
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
    
    func getPolicyAsXMLAwait(server: String, authToken: String, policyID: String) async throws {
        
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
        print("Running: getPolicyAsXMLAwait")
        print("policyID set as: \(policyID)")
        print("jamfURLQuery set as: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        Task {
            self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
        }
    }
    
    
    //    #################################################################################
    //    COMPUTER GROUPS
    //    #################################################################################

    func addComputerToGroup(xmlContent: String, computerName: String, authToken: String, computerId: String,groupId: String, resourceType: ResourceType, server: String) {
        readXMLDataFromStringXmlBrain(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
       separationLine()
        print("Running addComputerToGroup")
        
        if debugStatus == true {
            print("xmlContent is:\(xmlContent)")
        }
        
        print("url is:\(url)")
        print("computerName is:\(computerId)")
        print("computerId is:\(computerId)")
        let computers = self.xmlDoc.root["computers"]
        let computersUpdated = computers.addChild(name: "computer")
        computersUpdated.addChild(name: "id", value: computerId)
        computersUpdated.addChild(name: "name", value: computerName)
        
//        let size = computers["size"]
//        size.removeFromParent()
//        let computerCount = computers.count
//        print("computerCount is:\(computerCount)")
//        let updatedComputerCount = computerCount+1
//        print("updatedComputerCount is:\(computerCount)")
//        computers.addChild(name: "size", value: String(describing:computerCount))
        separationLine()
        print("updatedContent is:\(self.xmlDoc.root.xml)")
        self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    #############################################################################
    //    getGroupMembersXML - getAsXML
    //    #############################################################################
    
    func getGroupMembersXML(server: String, groupId: Int) {
        
        let groupIdString = String(describing: groupId )
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupIdString)"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        self.separationLine()
        print("Running: getGroupMembersXML")
        print("groupId set as: \(groupId)")
        print("jamfURLQuery set as: \(jamfURLQuery)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                self.separationLine()
                print("getGroupMembersXML failed")
                print(String(describing: error))
                return
            }
            
            if self.debugStatus == true {
                self.separationLine()
                print("getGroupMembersXML data is:")
                print(String(data: data, encoding: .utf8)!)
            }
            DispatchQueue.main.async {
                self.computerGroupMembersXML = (String(data: data, encoding: .utf8)!)
            }
        }
        task.resume()
    }

    func updateScopeAddCompGroup (xmlString: String, groupName: String, groupId: String) -> String {
        
#if os(macOS)
        let document = try! XMLDocument(xmlString: xmlString) //Change this to a suitable init
        let nodes = try! document.nodes(forXPath: "/policy/scope/computer_groups/computer_group")
        
        for node in nodes {
            if let item = node as? XMLElement {
                
                print("---------------------------------------------")
                print("Node is:\(node)")
                element = XMLNode.element(withName: "name", stringValue: groupName) as! XMLNode
                item.addChild(element)
                element2 = XMLNode.element(withName: "id", stringValue: groupId) as! XMLNode
                item.addChild(element2)
            }
        }
                  
        print("---------------------------------------------")
        print("element is:\(element)")
        print("---------------------------------------------")
        print("all nodes are:\(nodes)")
        print("---------------------------------------------")
        print("Updated document is:")
        print("---------------------------------------------")
        print((document))
        print("---------------------------------------------")
        print(String(describing: document))
        return String(describing: document)

#endif
        return("")
    }
    
    //   #################################################################################
    //   getPolicyAsXML
    //   #################################################################################
    
//    func getPolicyAsXML(server: String, authToken: String, policyID: Int) {
//        
//        let policyIdString = String(describing: policyID )
//        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyIdString)"
//        let url = URL(string: jamfURLQuery)!
//
//        let headers = [
//            "Accept": "application/xml",
//            "Content-Type": "application/xml",
//            "Authorization": "Bearer \(authToken)" ]
//        
//        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
//        request.allHTTPHeaderFields = headers
//        request.httpMethod = "GET"
//       self.separationLine()
//        print("Running: getPolicyAsXML")
//        print("policyID set as: \(policyID)")
//        print("jamfURLQuery set as: \(jamfURLQuery)")
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else {
//                self.separationLine()
//                print("getPolicyAsXML failed")
//                print(String(describing: error))
//                return
//            }
//            //            #########################################################################
//            //            DEBUG - CHECK XML
//            //            self.separationLine()
//            //            print("getPolicyAsXML data is:")
//            //            print(String(data: data, encoding: .utf8)!)
//            DispatchQueue.main.async {
//                self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
//            }
//        }
//        task.resume()
//    }
    
    
//    #################################################################################
//    LDAP Group limitations
//    #################################################################################

    func readXMLDataFromStringXmlBrain(xmlContent: String) {
        self.separationLine()
        print("Running readXMLDataFromString")
        print("xmlContent is:\(xmlContent)")
        
        guard let data = try? Data(xmlContent.utf8)
        else {
            print("Sample XML Data error.")
            return
        }
        do {
            self.xmlDoc = try AEXMLDocument(xml: data)
        }
        catch {
            print("\(error)")
        }
    }
    
    //    #################################################################################
    //    editPolicyScript - computer
    //    #################################################################################
    
    func editPolicyScript(server: String, authToken: String, resourceType: ResourceType, scriptID: String, scriptName: String, updatePressed: Bool, policyID: String, parameter4: String, parameter5: String,parameter6: String, parameter7: String, parameter8: String, parameter9: String, parameter10: String, parameter11: String) {
        
        let policyID = policyID
        var xml: String
        
        print("Running togglePolicyOnOff")
        if updatePressed == true {
            print("Updating XML")
            print("scriptID is set as:\(scriptID)")
            print("categoryName is set as:\(scriptName)")
            
            xml = """
                <policy>
                    <scripts>
                        <size>1</size>
                        <script>
                            <id>\(scriptID)</id>
                            <name>\(scriptName)</name>
                            <priority>After</priority>
                            <parameter4>\(parameter4)</parameter4>
                            <parameter5>\(parameter5)</parameter5>
                            <parameter6>\(parameter6)</parameter6>
                            <parameter7>\(parameter7)</parameter6>
                            <parameter8>\(parameter8)</parameter6>
                            <parameter9>\(parameter9)</parameter6>
                            <parameter10>\(parameter10)</parameter6>
                            <parameter11>\(parameter11)</parameter6>
                        </script>
                    </scripts>
                </policy>
                """
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("policy").appendingPathComponent(policyID)
                    print("Running editPolicyScript - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    if debugStatus == true {
                         print("xml is set as:\(xml)")
                    }
                    sendRequestAsXML(url: url,authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT" )
//                    appendStatus("Connecting to \(url)...")
                }
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }

    func readXMLDataFromString(xmlContent: String) {
        self.separationLine()
        print("Running readXMLDataFromString - NetBrain")
        if debugStatus == true {
            print("xmlContent is:\(xmlContent)")
        }
        guard let data = try? Data(xmlContent.utf8)
        else {
            print("Sample XML Data error.")
            return
        }
        do {
            self.xmlDoc = try AEXMLDocument(xml: data)
        }
        catch {
            print("\(error)")
        }
    }
    
    
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String ) {
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        self.atSeparationLine()
        print("Running sendRequestAsXML XMLBrain function - resourceType is set as:\(resourceType)")
        print("url is:\(url)")

        //        DEBUG
        if debugStatus == true {
            atSeparationLine()
            print("xml is:\(xml)")
            atSeparationLine()
            print("xmldata is:\(String(describing: xmldata))")
        }
        
        atSeparationLine()
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
                self.doubleSeparationLine()
                
                if self.debugStatus == true {
                    print("Data is:\(data)")
                    print("Data is:\(response)")
                }
                    
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

    
    func createScript(name: String, category: String, filename: String, info: String, notes: String, priority: String, parameter4: String, parameter5: String, parameter6: String, parameter7: String, parameter8: String, parameter9: String,parameter10: String,parameter11: String, os_requirements: String,script_contents: String,script_contents_encoded: String,scriptID: String, server: String, authToken: String) {
       
        self.separationLine()
        print("Running createScript")
        print("Script ID is:\(scriptID)")
        print("Server is:\(server)")
        
        let parameters = "<script>\n\t<name>\(name)</name>\n\t<category>\(category)</category>\n\t<filename>\(filename)</filename>\n\t<info>\(info)</info>\n\t<notes>\(notes)</notes>\n\t<priority>\(priority)</priority>\n\t<parameters>\n\t\t<parameter4>\(parameter4)</parameter4>\n\t\t<parameter5>\(parameter5)</parameter5>\n\t\t<parameter6>\(parameter6)</parameter6>\n\t\t<parameter7>\(parameter7)</parameter7>\n\t\t<parameter8>\(parameter8)</parameter8>\n\t\t<parameter9>\(parameter9)</parameter9>\n\t\t<parameter10>\(parameter10)</parameter10>\n\t\t<parameter11>\(parameter11)</parameter11>\n\t</parameters>\n\t<os_requirements>\(os_requirements)</os_requirements>\n\t<script_contents>\(script_contents)</script_contents>\n\t<script_contents_encoded>\(script_contents_encoded)</script_contents_encoded>\n</script>"
        
        let postData = parameters.data(using: .utf8)
        
                let jamfURLQuery = server + "/JSSResource/scripts/id/" + "\(scriptID)"
        
        let url = URL(string: jamfURLQuery)!
        
        var request = URLRequest(url: url)
        
        print("jamfURLQuery is:\(jamfURLQuery)")
        print("Paramameters are set as:\(parameters)")

        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
    
    // ######################################################################################
    // addScriptToPolicy
    // ######################################################################################
    
    func addScriptToPolicy(xmlContent: AEXMLDocument, xmlContentString: String,authToken: String,   resourceType: ResourceType, server: String, policyId: String, scriptName: String, scriptId: String, scriptParameter4: String, scriptParameter5: String, scriptParameter6: String, scriptParameter7: String, scriptParameter8: String, scriptParameter9: String,scriptParameter10: String,scriptParameter11: String, priority: String, newPolicyFlag: Bool ) {
        
//        if newPolicyFlag == false {
//            self.separationLine()
//            print("Is not new policy - converting xml to AEXML Document format")
//            self.readXMLDataFromStringXmlBrain(xmlContent: xmlContentString)
//        }
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running addScriptToPolicy")
        print("xmlContent is:\(xmlContent.xml)")
        print("url is:\(url)")
        print("scriptName is:\(scriptName)")
        print("scriptId is:\(scriptId)")
        let scripts = self.xmlDoc.root["scripts"].addChild(name: "script")
        scripts.addChild(name: "id", value: scriptId)
        scripts.addChild(name: "name", value: scriptName)
        scripts.addChild(name: "priority", value: "After")
        
        if scriptParameter4 != "" {
            print("scriptParameter4 value supplied:\(scriptParameter4)")
            scripts.addChild(name: "parameter4", value: scriptParameter4)
        }
        if scriptParameter5 != "" {
            print("scriptParameter5 value supplied:\(scriptParameter5)")
            scripts.addChild(name: "parameter5", value: scriptParameter5)
        }
        if scriptParameter6 != "" {
            print("scriptParameter6 value supplied:\(scriptParameter6)")
            scripts.addChild(name: "parameter6", value: scriptParameter6)
        }
        if scriptParameter7 != "" {
            print("scriptParameter7 value supplied:\(scriptParameter7)")
 scripts.addChild(name: "parameter7", value: scriptParameter7)
        }
        if scriptParameter8 != "" {
            print("scriptParameter8 value supplied:\(scriptParameter8)")
scripts.addChild(name: "parameter8", value: scriptParameter8)
        }
        if scriptParameter9 != "" {
            print("scriptParameter9 value supplied:\(scriptParameter9)")
scripts.addChild(name: "parameter9", value: scriptParameter9)
        }
        if scriptParameter10 != "" {
            print("scriptParameter10 value supplied:\(scriptParameter10)")
scripts.addChild(name: "parameter10", value: scriptParameter10)
        }
        if scriptParameter11 != "" {
            print("scriptParameter11 value supplied:\(scriptParameter11)")
scripts.addChild(name: "parameter11", value: scriptParameter11)
        }

        let scriptCount = scripts.count
        print("scriptCount is:\(scriptCount)")
        let updatedScriptCount = scriptCount+1
        print("updatedScriptCount is:\(updatedScriptCount)")
        self.xmlDoc.root["scripts"].addChild(name: "size", value: String(describing:updatedScriptCount))
        
        if newPolicyFlag == true {
            self.separationLine()
            print("Is new policy - not posting package data to Jamf at this point")
        } else {
            self.separationLine()
            print("Is not new policy - posting updated package data to Jamf")
            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xmlContent.xml, httpMethod: "PUT")
        }
        
        print("updatedContent is:")
        print(xmlContent.xml)
//        print(self.xmlDoc.root.xml)
    }
    
    
    // ######################################################################################
    // addPackageToPolicy
    // ######################################################################################
    
    func addPackageToPolicy(xmlContent: AEXMLDocument, xmlContentString: String, authToken: String, server: String, packageName: String, packageId: String,policyId: String, resourceType: ResourceType, newPolicyFlag: Bool) {
        
//        if newPolicyFlag == false {
//            self.separationLine()
//            print("Is not new policy - converting xml to AEXML Document format")
//            self.readXMLDataFromStringXmlBrain(xmlContent: xmlContentString)
//        }
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!

//              ################################################################################
//              DEBUG
//              ################################################################################

        self.separationLine()
        print("Running addPackageToPolicy - XmlBrain")
        print("Initial xmlContent is:")
        self.atSeparationLine()
        print(xmlContent.xml)
        self.atSeparationLine()
        print("url is:\(url)")
        print("packageName is:\(packageName)")
        print("packageId is:\(packageId)")
        print("newPolicyFlag status is:\(newPolicyFlag)")
        self.atSeparationLine()
        
//              ################################################################################
//              DEBUG
//              ################################################################################

        let packages = xmlContent.root["package_configuration"]["packages"].addChild(name: "package")
        packages.addChild(name: "id", value: packageId)
        packages.addChild(name: "name", value: packageName)
        packages.addChild(name: "action", value: "Install")
        packages.addChild(name: "fut", value: "false")
        packages.addChild(name: "feu", value: "false")
        packages.addChild(name: "update_autorun", value: "false")
        
//              ################################################################################
//              DEBUG
//              ################################################################################

        self.atSeparationLine()
        print("updated XML after addPackageToPolicy has run is:")
        print(xmlContent.xml)
        self.atSeparationLine()
//              ################################################################################
//              DEBUG
//              ################################################################################
        
        let packageCount = packages.count
        print("packageCount is:\(packageCount)")

        if newPolicyFlag == true {
            self.separationLine()
            print("Is new policy - not posting package data to Jamf at this point")
        } else {
            self.separationLine()
            print("Is not new policy - posting updated package data to Jamf")
            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xmlContent.xml, httpMethod: "PUT")
        }
        
    }
    
    
    //   #################################################################################
    //   addSelectedPackagesToPolicy
    //   #################################################################################
    
    func addSelectedPackagesToPolicy(selection: Set<Package>, authToken: String, server: String, xmlContent: AEXMLDocument, policyId: String) {
        
        let packageCount = selection.count
        self.separationLine()
        print("Running addSelectedPackagesToPolicy")
        print("Adding in structure to xml")
        _ = self.xmlDoc.root.addChild(name: "package_configuration")
        _ = self.xmlDoc.root["package_configuration"].addChild(name: "packages")
        
        if packageCount == 0 {
            print("No packages to add")
        } else {
            
            for eachPackage in selection {
                print("Item is \(String(describing: eachPackage))")
                let currentPackageIdInt = eachPackage.jamfId
                let currentPackageNameString = eachPackage.name
                print("Current currentPackageIdInt is:\(String(describing: self.currentPackageIdInt))")
                print("Current currentPackageNameString is:\(String(describing: self.currentPackageNameString))")
                print("Adding package:\(eachPackage.name) to list")
                self.addPackageToPolicy(xmlContent: self.xmlDoc, xmlContentString: "", authToken: authToken, server: server, packageName: currentPackageNameString, packageId: String(describing: currentPackageIdInt), policyId: policyId, resourceType: ResourceType.policyDetail, newPolicyFlag: true)
            }
        }
        
        self.separationLine()
        print("Adding packageCount:\(packageCount)")
        let packages = self.xmlDoc.root["package_configuration"]["packages"].addChild(name: "size", value: String(describing: packageCount))
        
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        
        if debugStatus == true {
            self.atSeparationLine()
            print("updated XML after addPackageToPolicy has run is:")
            print(self.xmlDoc.root.xml)
        }
        self.atSeparationLine()
        print("Have finished adding packages to policy - posting xml")
        self.postNewPolicy(server: server, authToken: authToken, xml: self.xmlDoc.root.xml)
    }
    
    
    //    #################################################################################
    //    Post new policy - via XML
    //    #################################################################################
    
    func postNewPolicy(server: String, authToken: String, xml: String ) {
        
        let sem = DispatchSemaphore.init(value: 0)
        self.atSeparationLine()
        self.separationLine()
        print("Running postNewPolicy XmlBrain")
        print("Url is set as:\(server)")
        self.separationLine()
        print("XML is set as:")
        print(xml)
        self.atSeparationLine()
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                let xmldata = xml.data(using: .utf8)
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
    
    
    //    #################################################################################
    //    updatePolicyScopeMultipleGroups - batch
    //    #################################################################################
    
//    func updatePolicyScopeMultipleGroups(selectedPolicy: Int, server: String, authToken: String, groupSelection: Set<ComputerGroup>, xmlString: String) {
//        
//        //    #################################################################################
//        //    Update a single policy with one or more groups - selected
//        //    #################################################################################
//
//        layout.separationLine()
//        print("Running: updatePolicyScopeMultipleGroups")
//        print("Set processingComplete to false")
//        self.processingComplete = true
//        print(String(describing: self.processingComplete))
//        print("selectedPolicy is:\(selectedPolicy)")
//        networkController.getPolicyAsXML(server: server, policyID: selectedPolicy, authToken: authToken)
//        
//        for eachItem in groupSelection {
//            layout.separationLine()
//            print("Items as Dictionary is \(eachItem)")
//            
//            let groupID = String(describing:eachItem.id)
//            let groupName: String = String(describing:eachItem.name)
//            print("Current groupID is:\(groupID)")
//            print("Current groupName is:\(String(describing: groupName))")
//            print("Run:getPolicyAsXML")
//            
//            //            self.updateScopeAddCompGroup(xmlString: xmlString, groupName: groupName, groupId: groupId)
//        }
//        layout.separationLine()
//        print("Finished - Set processingComplete to true")
//        self.processingComplete = true
//        print(String(describing: self.processingComplete))
//    }
    
    
    //    #################################################################################
    //    readXMLDataFromStringScopingBrain
    //    #################################################################################
    
    
    func readXMLDataFromStringScopingBrain(xmlContent: String) {
        self.separationLine()
        print("Running readXMLDataFromStringScopingBrain")
        
        //        DEBUG
        if debugStatus == true {
            print("Initial xmlContent is:\(xmlContent)")
        }
        
        self.separationLine()
        print("Adding to: AEXMLDocument")
        
        guard let data = try? Data(xmlContent.utf8)
                
        else {
            print("Sample XML Data error.")
            return
        }
        do {
            self.xmlDoc = try AEXMLDocument(xml: data)
        }
        catch {
            print("\(error)")
        }
    }
    
    //    #################################################################################
    //    updateScopeCompGroupSetAsync - update a single or multiple policies with a single group
    //    #################################################################################
    
    func updateScopeCompGroupSetAsync(groupSelection: ComputerGroup, authToken: String, resourceType: ResourceType, server: String, policiesSelection: [Int?]) async {

        let groupName = groupSelection.name
        let groupId = groupSelection.id

        self.separationLine()
        print("Running scopingController.updateScopeCompGroupSet")
        print("group name is:\(groupName)")
        print("group id is:\(groupId)")
        //        print("currentPolicyAsXML is:\(currentPolicyAsXML)")
        print("policiesSelection is:\(String(describing: policiesSelection))")

        for eachPolicy in policiesSelection {

            let eachPolicyId: String = String(describing: eachPolicy ?? 0)
            print("eachPolicyId is:\(eachPolicyId)")

            let jamfURLQuery = server + "/JSSResource/policies/id/" + eachPolicyId
            let url = URL(string: jamfURLQuery)!

                do {
                    let policyAsXML = try await self.getPolicyAsXMLaSync(server: server, policyID: eachPolicy ?? 0, authToken: authToken)
                    print("Xml data is present - reading")
                    print(policyAsXML)
                    self.readXMLDataFromStringScopingBrain(xmlContent: policyAsXML)
                } catch {
                    print("Fetching detailed policy as xml failed: \(error)")
                }
                    let currentComputerGroups = xmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
                    currentComputerGroups.addChild(name: "name", value: groupName)
                    currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
                    currentComputerGroups.addChild(name: "isSmart", value: "false")

                    let scope = xmlDoc.root["scope"].addChild(name: "scope")
                    let allComputers = xmlDoc.root["scope"]["all_computers"]
                    allComputers.removeFromParent()
                    scope.addChild(name: "all_computers", value: "false")
                    self.separationLine()
                    print("Read main XML doc - updated")
                    print(xmlDoc.xml)
                    print("Submit updated doc")
                    self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
                    print("The string is not empty")
            }
    }
    
//    #################################################################################
//    updateScopeCompGroupSetAsyncSingle - update a single or multiple policies with a single group
//    #################################################################################

    func updateScopeCompGroupSetAsyncSingle(groupSelection: ComputerGroup, authToken: String, resourceType: ResourceType, server: String, policyID: String, policyAsXML: String) {

        let groupName = groupSelection.name
        let groupId = groupSelection.id
        self.separationLine()
        print("Running scopingController.updateScopeCompGroupSet")
        print("group name is:\(groupName)")
        print("group id is:\(groupId)")
        print("policyID is:\(String(describing: policyID))")

        let jamfURLQuery = server + "/JSSResource/policies/id/" + policyID
        let url = URL(string: jamfURLQuery)!

        print("Xml data is present - reading")
        print(policyAsXML)
        self.readXMLDataFromStringScopingBrain(xmlContent: policyAsXML)
        
        let currentComputerGroups = xmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
        currentComputerGroups.addChild(name: "name", value: groupName)
        currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
        currentComputerGroups.addChild(name: "isSmart", value: "false")
        
        let scope = xmlDoc.root["scope"].addChild(name: "scope")
        let allComputers = xmlDoc.root["scope"]["all_computers"]
        allComputers.removeFromParent()
        scope.addChild(name: "all_computers", value: "false")
        self.separationLine()
        print("Read main XML doc - updated")
        print(xmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
        print("The string is not empty")
        
    }
            
        //    #################################################################################
        //    getPolicyAsXMLaSync
        //    #################################################################################
    
    func getPolicyAsXMLaSync(server: String, policyID: Int, authToken: String) async throws -> String{

        let policyIdString = String(describing: policyID )
        print("Running:getPolicyAsXMLaSync - policyID is:\(policyIdString) ")
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyIdString)"
        let url = URL(string: jamfURLQuery)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseCode = (response as? HTTPURLResponse)?.statusCode
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - Response is:\(String(describing: responseCode))")
            throw JamfAPIError.badResponseCode
        }
        self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
        return self.currentPolicyAsXML
    }
    
            
        //    #################################################################################
        //    updateScopeCompGroupSingle
        //    #################################################################################

    
    func updateScopeCompGroupSingle(groupSelection: ComputerGroup, authToken: String, resourceType: ResourceType, server: String, policyID: String, currentPolicyAsXML: String, currentPolicyAsAEXML: AEXMLDocument) {
        
        let groupName = groupSelection.name
        let groupId = groupSelection.id
        
        self.separationLine()
        print("Running updateScopeCompGroupSingle")
        print("group name is:\(groupName)")
        print("group id is:\(groupId)")
        
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
        let url = URL(string: jamfURLQuery)!
        
        //    #################################################################################
        //            Read data back
        //    #################################################################################
        
        if  currentPolicyAsXML.isEmpty {
            print("The currentPolicyAsXML string is empty - wait")
            Task {
                try await self.getPolicyAsXMLAwait(server: server, authToken: authToken, policyID: String(describing: policyID))
            }
            
        } else {
            
            let currentComputerGroups = xmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
            currentComputerGroups.addChild(name: "name", value: groupName)
            currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
            currentComputerGroups.addChild(name: "isSmart", value: "false")
            
            let scope = xmlDoc.root["scope"].addChild(name: "scope")
            scope.addChild(name: "all_computers", value: "false")
            self.separationLine()
            print("Read main XML doc - updated")
            print(xmlDoc.xml)
            print("Submit updated doc")
            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
        }
    }
    
    
    
    //    ##################################################
    //    addComputerToPolicyScope - via reading xml and updating
    //    ##################################################
    
    func addComputerToPolicyScope(xmlContent: String, computerName: String, authToken: String, computerId: String, resourceType: ResourceType, server: String, policyId: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
        
        self.separationLine()
        print("Running addComputerToPolicyScope")
        print("computer name is:\(computerName)")
        print("computer id is:\(computerId)")
        let computers = xmlDoc.root["scope"]["computers"].addChild(name: "computer")
        computers.addChild(name: "id", value: computerId)
        computers.addChild(name: "name", value: computerName)
        let scope = xmlDoc.root["scope"].addChild(name: "scope")
        scope.addChild(name: "all_computers", value: "false")
        self.separationLine()
        print("Read main XML doc - updated")
        print(xmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    ##################################################
    //    addComputerToPolicyScope - via reading xml and updating
    //    ##################################################
    
    func enableAllComputersToScope(xmlContent: String, authToken: String, resourceType: ResourceType, server: String, policyId: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
        self.separationLine()
        print("Running addAllComputersToScope")
        let scope = xmlDoc.root["scope"]
        let currentSettingsAllComps = xmlDoc.root["scope"]["all_computers"]
        currentSettingsAllComps.removeFromParent()
        scope.addChild(name: "all_computers", value: "true")
        self.separationLine()
        print("Read main XML doc - updated")
        print(xmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    
    func disableAllComputersToScope(xmlContent: String, authToken: String, resourceType: ResourceType, server: String, policyId: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
        self.separationLine()
        print("Running addAllComputersToScope")
        let scope = xmlDoc.root["scope"]
        let currentSettingsAllComps = xmlDoc.root["scope"]["all_computers"]
        currentSettingsAllComps.removeFromParent()
        scope.addChild(name: "all_computers", value: "false")
        self.separationLine()
        print("Read main XML doc - updated")
        print(xmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    #################################################################################
    //    updatePolicyScopeDepartment - requires policy as XML
    //    #################################################################################
    
    func addDepartmentToPolicyScope(xmlContent: String, departmentName: String, departmentId: String, authToken: String, policyId: String, resourceType: ResourceType, server: String) {
        self.separationLine()
        print("Running:addDepartmentToPolicyScope")
        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        print("Adding XML data")
        print("Adding departmentName: \(departmentName)")
        print("Adding departmentId: \(departmentId)")
        let departments = xmlDoc.root["scope"]["departments"].addChild(name: "department")
        departments.addChild(name: "name", value: departmentName)
        departments.addChild(name: "id", value: departmentId)
        let departmentCount = departments.count
        print("departmentCount is:\(departmentCount)")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    #################################################################################
    //    updatePolicyScopeBuilding - requires policy as XML
    //    #################################################################################
    
    func addBuildingToPolicyScope(xmlContent: String, buildingName: String, buildingId: String, policyId: String, resourceType: ResourceType, server: String, authToken: String) {
        self.separationLine()
        print("Running:addBuildingToPolicyScope")
        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        let buildings = self.xmlDoc.root["scope"]["buildings"].addChild(name: "building")
        buildings.addChild(name: "name", value: buildingName)
        buildings.addChild(name: "id", value: buildingId)
        print("updatedContent is:\(self.xmlDoc.root.xml)")
        let buildingCount = buildings.count
        print("buildingCount is:\(buildingCount)")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    #################################################################################
    //    updatePolicyScopeLimitationsAuto
    //    #################################################################################
    
    
    func updatePolicyScopeLimitationsAuto(groupSelection: LDAPCustomGroup, authToken: String, resourceType: ResourceType, server: String, policyID: String) async {
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
        let url = URL(string: jamfURLQuery)!
        let ldapUserGroupName = groupSelection.name
        let ldapUserGroupID = groupSelection.id
        self.separationLine()
        print("Running updatePolicyScopeLimitationsAuto - Scoping Controller")
        print("policyID is:\(policyID)")
        print("ldapUserGroupName is:\(ldapUserGroupName)")
        print("ldapUserGroupID is:\(ldapUserGroupID)")

        Task {
            do {
                let policyAsXML = try await self.getPolicyAsXMLaSync(server: server, policyID: Int(policyID) ?? 0, authToken: authToken)
                self.separationLine()
                print("policyAsXML is:\(policyAsXML)")
                print("policyID is:\(policyID)")
                print("Xml data is present - reading and adding to:self.readXMLDataFromStringScopingBrain ")
//                print("policyAsXML is:\(policyAsXML)")
                self.readXMLDataFromStringScopingBrain(xmlContent: policyAsXML)
                print("Adding limit_to_users")
                let currentLdapGroups = self.xmlDoc.root["scope"]["limit_to_users"]["user_groups"]
                currentLdapGroups.addChild(name: "user_group", value: ldapUserGroupName)
                let currentLdapGroupsLimitations = self.xmlDoc.root["scope"]["limitations"]["user_groups"].addChild(name: "user_group")
                currentLdapGroupsLimitations.addChild(name: "id", value: String(describing: ldapUserGroupID))
                currentLdapGroupsLimitations.addChild(name: "name", value: String(describing: ldapUserGroupName))
                self.separationLine()
                print("Read main XML doc - updated")
                print(self.xmlDoc.xml)
                print("Submit updated doc")
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
            } catch {
                print("Fetching detailed policy as xml failed: \(error)")
            }
        }
    }
        
        
    
    //    #################################################################################
    //    updatePolicyScopeLimitationsAutoRemove
    //    #################################################################################
    
    
    func updatePolicyScopeLimitAutoRemove(authToken: String, resourceType: ResourceType, server: String, policyID: String, currentPolicyAsXML: String) {
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
        let url = URL(string: jamfURLQuery)!
        
        self.separationLine()
        print("Running updatePolicyScopeLimitatAutoRemove")
        
//        print("Running readXMLDataFromStringScopingBrain")

        self.readXMLDataFromStringScopingBrain(xmlContent: currentPolicyAsXML)
        self.separationLine()
        self.atSeparationLine()
        print("DEBUG")
        print("currentPolicyAsXML is:\n\(currentPolicyAsXML)")

        var currentScopeOverall = xmlDoc.root["scope"]
        let currentComputers = xmlDoc.root["scope"]["computers"]
        let currentComputer_groups = xmlDoc.root["scope"]["computer_groups"]
        let currentBuildings = xmlDoc.root["scope"]["buildings"]
        let currentDepartments = xmlDoc.root["scope"]["departments"]
        let currentUserGroups = xmlDoc.root["scope"]["limit_to_users"]["user_groups"]
        let currentUserLimitationsUsers = xmlDoc.root["scope"]["limitations"]["users"]
        let currentUserLimitationsUserGroups = xmlDoc.root["scope"]["limitations"]["user_groups"]
        let currentUserLimitationsNetworkSegments = xmlDoc.root["scope"]["limitations"]["network_segments"]
        let currentUserLimitationsiBeacons = xmlDoc.root["scope"]["limitations"]["ibeacons"]
        let currentLimitations = xmlDoc.root["scope"]["limitations"]
        
        if let computers = xmlDoc.root["scope"]["computers"].all {
            print("All current computers are:")
            for computer in computers {
                if let name = computer.value {
                    print(name)
                }
            }
        }
        
        if let computer_groups = xmlDoc.root["scope"]["computer_groups"].all {
            print("All current UserGroups are:")
            for computerGroup in computer_groups {
                if let name = computerGroup.value {
                    print(name)
                }
            }
        }
        
        if let departments = xmlDoc.root["scope"]["departments"].all {
            print("All current departments are:")
            for department in departments {
                if let name = department.value {
                    print(name)
                }
            }
        }
        
        if let limitations = xmlDoc.root["scope"]["limitations"].all {
            print("All current limitations are:")
            for limitation in limitations {
                if let name = limitation.value {
                    print(name)
                }
            }
        }
        
        print("Removing all limitations settings")
        currentLimitations.removeFromParent()
        separationLine()
        //        print("Scope overall is:\(currentScopeOverall.xml)")
        print("Scope overall is:\n\(currentScopeOverall.xml)")
        separationLine()
        
        print("Removing all currentUserGroups limitations settings")
        currentUserGroups.removeFromParent()
        //            currentUserLimitationsUsers.removeFromParent()
        //            currentUserLimitationsUserGroups.removeFromParent()
        //            currentUserLimitationsNetworkSegments.removeFromParent()
        //            currentUserLimitationsiBeacons.removeFromParent()
        separationLine()
        
        print("Update currentScopeOverall")
        currentScopeOverall = xmlDoc.root["scope"]
        
        
        currentScopeOverall.addChild(currentComputers)
        currentScopeOverall.addChild(currentComputer_groups)
        currentScopeOverall.addChild(currentBuildings)
        currentScopeOverall.addChild(currentDepartments)
        separationLine()
        
        print("Scope overall updated is:\n\(currentScopeOverall.xml)")
        
        self.currentPolicyScopeXML = currentScopeOverall.xml
        self.separationLine()
        print("Read main XML doc - updated")
        print(xmlDoc.xml)
        separationLine()
        
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
        print("The string is not empty")
        //    }
    }
    
    
    
    //    #################################################################################
    //    updateGroup - addToGroup
    //    #################################################################################
    
    
//    func updateGroup(server: String,resourceType: ResourceType, groupID: String, computerID: Int, computerName: String) {
//        
//        //        let resourcePath = getURLFormat(data: (resourceType))
//        //           let policyID = policyID
//        var xml: String
//        
//        print("Running updateGroup - updating via xml")
//        print("computerID is set as:\(computerID)")
//        print("computerName is set as:\(computerName)")
//        print("groupID is set as:\(groupID)")
//        
//        xml = """
//                   <computer_group>
//                       <computers>
//                               <computer>
//                               <name>﻿\(computerName)</name>
//                               </computer>
//                       </computers>
//                   </computer_group>
//                   """
//        
//        if URL(string: server) != nil {
//            if let serverURL = URL(string: server) {
//                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
//                print("Running update group function - url is set as:\(url)")
//                print("resourceType is set as:\(resourceType)")
//                // print("xml is set as:\(xml)")
//                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
//                appendStatus("Connecting to \(url)...")
//            }
//        }
//    }
    
    
    
    
    
    
    
}
