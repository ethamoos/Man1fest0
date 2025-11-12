//
//  XmlBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 08/07/2024.
//
// XmlBrain handles operations that deal with XML data, inclyding using the AEXML module
//
// Originally, these were present throughout other classes but I am gradually migrating them here.

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
    @State var debugStatus = true
    //    #################################################################################
    
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
    //    Icons
    //    #################################################################################
    //    @State var iconId = ""
    //    @State var iconName = ""
    //    @State var iconUrl = ""
    
    //    #################################################################################
    //    XML data
    //    #################################################################################
    @Published var aexmlDoc: AEXMLDocument = AEXMLDocument()
    @Published var computerGroupMembersXML: String = ""
    @Published var currentPolicyAsXML: String = ""
    @Published var updateXML: Bool = false
    var policyAsXMLScope: String = ""
    var newPolicyAsXML: String = ""
    @Published var currentPolicyScopeXML: String = ""
    
    // #########################################################################
    //  Build identifiers
    // #########################################################################

        
        let product_name = Bundle.main.infoDictionary!["CFBundleName"] as? String
        let product_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let build_version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

    //    #################################################################################
    //    ############ Computers
    //    #################################################################################
    
    @Published var computers: [Computer] = []
    @Published var computersBasic: [Computers.ComputerResponse] = []
    @Published var allComputersBasic: ComputerBasic = ComputerBasic(computers: [])
    @Published var allComputersBasicDict = [ComputerBasicRecord]()
    
    //    #################################################################################
    //    ############ GROUPS
    //    #################################################################################
    
    //    Members of a computer group
    @Published var compGroupComputers = [computerGroupResponse.Computer]()
    @Published var allComputerGroups: [ComputerGroup] = []
    @Published var computerGroupMembers: [ComputerGroupMembers] = []
    @Published var computerGroupInstance: [ComputerGroupInstance] = []
    
    @Published var computerGroupMembersComputers: [ComputerMember] = []
    @Published var allComputerRecordsInit: ComputerGroupMembers = ComputerGroupMembers(computer: ComputerMember(id: 0, name: "") )
    @Published var allComputerGroupsInitDict = ComputerMember(id: 0, name: "")
    
    @Published var userGroupsLDAP = ""
    //        Groups in policy scope
    @Published var allComputerGroupsScope: [ComputerGroup] = []
    
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
    
    
   
    
    //    #################################################################################
    //    COMPUTER GROUPS
    //    #################################################################################
    
    func addComputerToGroup(xmlContent: String, computerName: String, authToken: String, computerId: String,groupId: String, resourceType: ResourceType, server: String) {
        readXMLDataFromStringXmlBrain(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
        separationLine()
        print("Running addComputerToGroup XML brain")
        separationLine()
        print("xmlContent is:")
        separationLine()
        print(xmlContent)
        separationLine()
        print("url is:\(url)")
        print("computerName is:\(computerName)")
        print("computerId is:\(computerId)")
        print("groupId is:\(groupId)")
        
        let computers = self.aexmlDoc.root["computers"].addChild(name: "computer")
        computers.addChild(name: "id", value: computerId)
        computers.addChild(name: "name", value: computerName)
        separationLine()
        print("updatedContent is:")
        separationLine()
        print(self.aexmlDoc.root.xml)
        let jamfCount = computers.count
        print("jamfCount is:\(jamfCount)")
        self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
    }

    
    
    func addMultipleComputersToGroupOld(xmlContent: String, computers: Set<ComputerBasicRecord.ID>, authToken: String,groupId: String, resourceType: ResourceType, server: String) {
        readXMLDataFromStringXmlBrain(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
        separationLine()
        print("Running addMultipleComputersToGroupOLD XML brain")
        separationLine()
        print("xmlContent is:")
        separationLine()
        print(xmlContent)
        separationLine()
        print("url is:\(url)")
//        print("computerName is:\(computerName)")
//        print("computerId is:\(computerId)")
        print("groupId is:\(groupId)")
        
        for eachComputerID in computers {
            
            let computers = self.aexmlDoc.root["computers"]
            let computer = self.aexmlDoc.root["computers"].addChild(name: "computer")
            computer.addChild(name: "id", value:String(describing: eachComputerID))
//            computers.addChild(name: "name", value: computerName)
            print("updatedContent is:")
            separationLine()
            print(self.aexmlDoc.root.xml)
            
        }
            separationLine()
        print("Updated Final Content is:")
        separationLine()
        print(self.aexmlDoc.root.xml)
        let jamfCount = computers.count
        print("jamfCount is:\(jamfCount)")
        self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
    }
    
    
    func addMultipleComputersToGroup(xmlContent: String, computers: Set<ComputerBasicRecord>, authToken: String,groupId: String, resourceType: ResourceType, server: String) {
        readXMLDataFromStringXmlBrain(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
        separationLine()
        print("Running addMultipleComputersToGroupOLD XML brain")
        separationLine()
        print("xmlContent is:")
        separationLine()
        print(xmlContent)
        separationLine()
        print("url is:\(url)")
        print("groupId is:\(groupId)")
        
        for eachComputer in computers {
            
            let computers = self.aexmlDoc.root["computers"]
            let computer = self.aexmlDoc.root["computers"].addChild(name: "computer")
            computer.addChild(name: "id", value:String(describing: eachComputer.id))
            computer.addChild(name: "name", value:String(describing: eachComputer.name))
            print("updatedContent is:")
            separationLine()
            print(self.aexmlDoc.root.xml)
            
        }
            separationLine()
        print("Updated Final Content is:")
        separationLine()
        print(self.aexmlDoc.root.xml)
        let jamfCount = computers.count
        print("jamfCount is:\(jamfCount)")
        self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
    }
    
    
    // ######################################################################################
    // addCategoryToPolicy
    // ######################################################################################
    
    func addCategoryToPolicy(xmlContent: String,authToken: String, resourceType: ResourceType, server: String, policyId: String, categoryName: String, categoryId: String, newPolicyFlag: Bool ) {
        
        self.readXMLDataFromStringXmlBrain(xmlContent: xmlContent)
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running addCategoryToPolicy")
        print("xmlContent is:\(xmlContent)")
        print("url is:\(url)")
        print("categoryName is:\(categoryName)")
        print("categoryId is:\(categoryId)")
        let category = self.aexmlDoc.root["general"].addChild(name: "category")
        if categoryName != "" && categoryId != "" {
            category.addChild(name: "name", value: categoryName)
            print("updatedContent is:")
            print(xmlContent)
            
            if newPolicyFlag == false {
                print("Posting data")
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xmlContent, httpMethod: "PUT")
            }
        } else {
            print("Category is not set - not updating")
        }
    }
    
    func addCategoryToPolicy2(authToken: String, resourceType: ResourceType, server: String, policyId: String, categoryName: String, categoryId: String, newPolicyFlag: Bool ) {
        
        //        self.readXMLDataFromStringXmlBrain(xmlContent: xmlContent)
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running addCategoryToPolicy")
        //        print("xmlContent is:\(xmlContent)")
        print("url is:\(url)")
        print("categoryName is:\(categoryName)")
        print("categoryId is:\(categoryId)")
        let category = self.aexmlDoc.root["general"].addChild(name: "category")
        if categoryName != "" && categoryId != "" {
            category.addChild(name: "name", value: categoryName)
            print("updatedContent is:")
            print(self.aexmlDoc.root.xml)
            
            //            if newPolicyFlag == false {
            //                print("Posting data")
            //                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xmlContent, httpMethod: "PUT")
            //            }
        } else {
            print("Category is not set - not updating")
        }
    }
    
    
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
//DEBUG
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
    
    
    //    ##################################################
    //    createPolicyViaAEXML
    //    ##################################################
    
    func createNewPolicyViaAEXML(authToken: String, server: String, policyName: String, policyID: String, scriptName: String, scriptID: String, packageName: String, packageID: String, SelfServiceEnabled: Bool, department: String, category: String, enabledStatus: Bool, iconId: String, iconName: String, iconUrl: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/0"
        let url = URL(string: jamfURLQuery)!
        
        //        <?xml version="1.0" encoding="utf-8"?>

        
        let xml = """
        <policy>
        </policy>
        """
        
        
        self.readXMLDataFromStringXmlBrain(xmlContent: xml)
        self.separationLine()
        print("Select the script and attribute")
        let policy = self.aexmlDoc.root
        print("Add policy children")
        
        //    ##################################################
        //    CREATE NODES
        //    ##################################################
        
        print("Adding: general node")
        self.aexmlDoc.root.addChild(name: "general")
        print("Adding: package_configuration node")
        self.aexmlDoc.root.addChild(name: "package_configuration")
        print("Adding: scripts node")
        self.aexmlDoc.root.addChild(name: "scripts")
        print("Adding: self_service node")
        self.aexmlDoc.root.addChild(name: "self_service")
        print("Adding: scope node")
        self.aexmlDoc.root.addChild(name: "scope")
        
        let general = self.aexmlDoc.root["general"]
        let scripts = self.aexmlDoc.root["policy"]["scripts"]
        let packageConfiguration = self.aexmlDoc.root["package_configuration"]
        let selfService = self.aexmlDoc.root["self_service"]
        let scope = self.aexmlDoc.root["scope"]
        
        self.separationLine()
        print("Read main XML doc - initial")
        print(self.aexmlDoc.xml)
        
        
        //    ##################################################
        //    GENERAL
        //    ##################################################
        
        self.separationLine()

        general.addChild(name: "id", value: "0")
        print("Add policy name:\(policyName)")
        general.addChild(name: "name", value: policyName)
        let policyName = general.name
        
        self.separationLine()
        print("Enable policy")
        
        if enabledStatus == true {
            general.addChild(name: "enabled", value: "true")
        } else {
            general.addChild(name: "enabled", value: "false")
        }
        
        //    ##################################################
        //    SCRIPTS
        //    ##################################################
        
        if scriptName.isEmpty != true {
            self.separationLine()
            print("Adding script")
            scripts.addChild(name: "name", value: scriptName)
            let numberOfScripts = self.aexmlDoc.root["scripts"]["script"].count
            _ = scripts.addChild(name: "size", value: String(describing: numberOfScripts))
        } else {
            print("No scripts specified - remove this node")
            scripts.removeFromParent()
        }
        
        //    ##################################################
        //    Packages
        //    ##################################################
        
        if packageName.isEmpty != true {
            self.separationLine()
            print("Adding script")
            scripts.addChild(name: "name", value: scriptName)
            let numberOfScripts = self.aexmlDoc.root["scripts"]["script"].count
            _ = scripts.addChild(name: "size", value: String(describing: numberOfScripts))
        } else {
            print("No scripts specified - remove this node")
            scripts.removeFromParent()
        }
        
        //    ##################################################
        //    selfService
        //    ##################################################
        
        if SelfServiceEnabled != false {
            self.separationLine()
            print("Adding script")
            selfService.addChild(name: "use_for_self_service", value: String(describing: SelfServiceEnabled))
            selfService.addChild(name: "self_service_icon", value: String(describing: SelfServiceEnabled))
            let selfServiceEnabled = self.aexmlDoc.root["policy"]["self_service"]["use_for_self_service"]
            
            if iconName != "" {
                
                let selfServiceIcon = self.aexmlDoc.root["policy"]["self_service"]["self_service_icon"]
                selfServiceIcon.addChild(name: "filename", value: "")
                selfServiceIcon.addChild(name: "id", value: iconId)
                selfServiceIcon.addChild(name: "uri", value: "")
                
            } else {
                print("No SelfServiceEnabled specified - remove this node")
                selfService.removeFromParent()
            }
            
        }
        self.newPolicyAsXML = self.aexmlDoc.xml
        self.separationLine()
        print("Read main XML doc - updated")
        print(self.aexmlDoc.xml)
        separationLine()
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: ResourceType.policyDetail, xml: self.aexmlDoc.root.xml, httpMethod: "POST")
        print("The string is not empty")
    }
    
    
    
    
    
    
    //    #################################################################################
    //    Create Policies - via XML
    //    #################################################################################
    
    func createNewPolicyXML(server: String, authToken: String, policyName: String, customTrigger: String, departmentID: String, notificationName: String, notificationStatus: String, iconId: String, iconName: String, iconUrl: String, selfServiceEnable: String ) {
        
        var xml:String
        self.separationLine()
        print("DEBUGGING - DISABLE IF NOT TESTING")
        self.separationLine()
        print("Running createNewPolicyXML - PolicyBrain")
        print("Url is set as:\(server)")
        print("policyName is set as:\(policyName)")
        print("notificationName is set as:\(notificationName)")
        print("notificationStatus is set as:\(notificationStatus)")
        
        //    #################################################################################
        //    newPolicyXml
        //    #################################################################################
        
        xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <policy>
            <general>
                <id>0</id>
                <name>\(policyName)</name>
                <enabled>true</enabled>
                <trigger>EVENT</trigger>
                <trigger_checkin>false</trigger_checkin>
                <trigger_enrollment_complete>false</trigger_enrollment_complete>
                <trigger_login>false</trigger_login>
                <trigger_logout>false</trigger_logout>
                <trigger_network_state_changed>false</trigger_network_state_changed>
                <trigger_startup>false</trigger_startup>
                <trigger_other>\(customTrigger)</trigger_other>
                <frequency>Ongoing</frequency>
                <retry_event>none</retry_event>
                <retry_attempts>-1</retry_attempts>
                <notify_on_each_failed_retry>false</notify_on_each_failed_retry>
                <location_user_only>false</location_user_only>
                <target_drive>/</target_drive>
                <offline>false</offline>
                <category>
                </category>
                <date_time_limitations>
                    <activation_date/>
                    <activation_date_epoch>0</activation_date_epoch>
                    <activation_date_utc/>
                    <expiration_date/>
                    <expiration_date_epoch>0</expiration_date_epoch>
                    <expiration_date_utc/>
                    <no_execute_on/>
                    <no_execute_start/>
                    <no_execute_end/>
                </date_time_limitations>
                <network_limitations>
                    <minimum_network_connection>No Minimum</minimum_network_connection>
                    <any_ip_address>true</any_ip_address>
                    <network_segments/>
                </network_limitations>
                <override_default_settings>
                    <target_drive>default</target_drive>
                    <distribution_point/>
                    <force_afp_smb>false</force_afp_smb>
                    <sus>default</sus>
                    <netboot_server>current</netboot_server>
                </override_default_settings>
                <network_requirements>Any</network_requirements>
                <site>
                    <id>-1</id>
                    <name>None</name>
                </site>
            </general>
            <scope>
                <all_computers>false</all_computers>
            </scope>
            <self_service>
                <use_for_self_service>\(selfServiceEnable)</use_for_self_service>
                <self_service_display_name/>
                <install_button_text>Install</install_button_text>
                <reinstall_button_text>Reinstall</reinstall_button_text>
                <self_service_description/>
                <force_users_to_view_description>false</force_users_to_view_description>
                <self_service_icon>
                    <id>\(iconId)</id>
                    <filename>\(iconName)</filename>
                    <uri>\(iconUrl)</uri>
                </self_service_icon>
                <feature_on_main_page>false</feature_on_main_page>
                <self_service_categories/>
                <notification>\(notificationStatus)</notification>
                <notification>Self Service</notification>
                <notification_subject>\(notificationName)</notification_subject>
                <notification_message/>
            </self_service>
        </policy>
        """
        
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        self.separationLine()
        print("Setting newPolicyAsXML variable - PolicyBrain")
        self.newPolicyAsXML = xml
        //        print("Printing initial xml data for new policy")
        //        print(self.newPolicyAsXML)
        self.separationLine()
        print("XML variable is initially set as:")
        print(xml)
        print("Reading xml data with AEXML")
        self.readXMLDataFromStringXmlBrain(xmlContent: xml)
        print("XML data is now stored in:self.aexmlDoc - PolicyBrain")
        print(self.aexmlDoc)
        self.separationLine()
        
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
                    //                        defer { sem.signal() }
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Bad Credentials")
                        print(response!)
                        return
                    }
                }.resume()
                //                    sem.wait()
            }
        }
    }
    //}
    
    
    
    //    #############################################################################
    //    getGroupMembersXML - getAsXML
    //    #############################################################################
    
    func getGroupMembersXML(server: String, groupId: Int, authToken: String ) {
        
        //        Runs in view to get the members for the selected group as xml
        
        let groupIdString = String(describing: groupId )
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupIdString)"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        self.separationLine()
        print("Running: getGroupMembersXML - xmlcontroller")
        print("groupId set as: \(groupId)")
        print("jamfURLQuery set as: \(jamfURLQuery)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                self.separationLine()
                print("getGroupMembersXML failed")
                print(String(describing: error))
                return
            }
            self.separationLine()
            print("getGroupMembersXML data is:")
            print(String(data: data, encoding: .utf8)!)
            DispatchQueue.main.async {
                self.computerGroupMembersXML = (String(data: data, encoding: .utf8)!)
            }
        }
        task.resume()
    }
    
    
    //    #################################################################################
    //    try await get Group Members
    //    #################################################################################
    
    
    func getGroupMembers(server: String,  name: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/computergroups/name/" + name
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
          request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        separationLine()
        print("Running func: getGroupMembers Xml brain")
        print("jamfURLQuery is: \(jamfURLQuery)")
        print("Server is: \(server)")
        print("Name is: \(name)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        
        //        DEBUG
        separationLine()
        print("processDetail getGroupMembers Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let compGroupData = try JSONDecoder().decode(computerGroupResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.allComputerGroupsInitDict = self.allComputerRecordsInit.computer
            self.allComputersBasicDict = self.allComputersBasic.computers
            self.compGroupComputers = compGroupData.computerGroup.computers
        }
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
    
    
    //    #################################################################################
    //    LDAP Group limitations
    //    #################################################################################
    
    func readXMLDataFromStringXmlBrain(xmlContent: String) {
        self.separationLine()
        print("Running readXMLDataFromString")
        if debugStatus == true {
//            self.separationLine()
//            print("xmlContent is:\(xmlContent)")
        }
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
    //    editPolicyScript - computer
    //    #################################################################################
    
    func editPolicyScript(server: String, authToken: String, resourceType: ResourceType, scriptID: String, scriptName: String, updatePressed: Bool, policyID: String, parameter4: String, parameter5: String,parameter6: String, parameter7: String, parameter8: String, parameter9: String, parameter10: String, parameter11: String) {
        
        //        let resourcePath = getURLFormat(data: (resourceType))
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
                    print("Running update policy category function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    // print("xml is set as:\(xml)")
                    sendRequestAsXML(url: url,authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT" )
                    // appendStatus("Connecting to \(url)...")
                }
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    func readXMLDataFromString(xmlContent: String) {
        //        self.separationLine()
//        print("Running readXMLDataFromString - NetBrain")
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
    
    
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String ) {
        //        Request in XML format
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        self.atSeparationLine()
        print("Running sendRequestAsXML XMLBrain function - resourceType is set as:\(resourceType)")
        print("url is:\(url)")
        atSeparationLine()
        print("xml is:\(xml)")
        //       atSeparationLine()
        //        print("xmldata is:\(String(describing: xmldata) ?? "")")
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
    
    
    func createScript(name: String, category: String, filename: String, info: String, notes: String, priority: String, parameter4: String, parameter5: String, parameter6: String, parameter7: String, parameter8: String, parameter9: String,parameter10: String,parameter11: String, os_requirements: String,script_contents: String,script_contents_encoded: String,scriptID: String, server: String, authToken: String) {
        
        print("Running createScript")
        print("Script ID is:\(scriptID)")
        print("Server is:\(server)")
        
        let parameters = "<script>\n\t<name>\(name)</name>\n\t<category>\(category)</category>\n\t<filename>\(filename)</filename>\n\t<info>\(info)</info>\n\t<notes>\(notes)</notes>\n\t<priority>\(priority)</priority>\n\t<parameters>\n\t\t<parameter4>\(parameter4)</parameter4>\n\t\t<parameter5>\(parameter5)</parameter5>\n\t\t<parameter6>\(parameter6)</parameter6>\n\t\t<parameter7>\(parameter7)</parameter7>\n\t\t<parameter8>\(parameter8)</parameter8>\n\t\t<parameter9>\(parameter9)</parameter9>\n\t\t<parameter10>\(parameter10)</parameter10>\n\t\t<parameter11>\(parameter11)</parameter11>\n\t</parameters>\n\t<os_requirements>\(os_requirements)</os_requirements>\n\t<script_contents>\(script_contents)</script_contents>\n\t<script_contents_encoded>\(script_contents_encoded)</script_contents_encoded>\n</script>"
        
        let postData = parameters.data(using: .utf8)
        
        //                let scriptIdString = String(describing: scriptID )
        
        let jamfURLQuery = server + "/JSSResource/scripts/id/" + "\(scriptID)"
        
        let url = URL(string: jamfURLQuery)!
        
        var request = URLRequest(url: url)
        
        print("jamfURLQuery is:\(jamfURLQuery)")
        
        print("Paramameters are set as:\(parameters)")
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
    
    
    //    <script>
    //        <name>Sample Script</name>
    //        <category>None</category>
    //        <filename>string</filename>
    //        <info>Script information</info>
    //        <notes>Sample Script</notes>
    //        <priority>Before</priority>
    //        <parameters>
    //            <parameter4>string</parameter4>
    //            <parameter5>string</parameter5>
    //            <parameter6>string</parameter6>
    //            <parameter7>string</parameter7>
    //            <parameter8>string</parameter8>
    //            <parameter9>string</parameter9>
    //            <parameter10>string</parameter10>
    //            <parameter11>string</parameter11>
    //        </parameters>
    //        <os_requirements>string</os_requirements>
    //        <script_contents>echo "Sample script"</script_contents>
    //        <script_contents_encoded>string</script_contents_encoded>
    //    </script>
    
    
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
        let scripts = self.aexmlDoc.root["scripts"].addChild(name: "script")
        //  print("Confirm current number of scripts as:\(numberOfScripts)")
        //  self.aexmlDoc.root["scripts"].addChild(name: "size", value: String(describing:numberOfScripts))
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
        
        //        packages.addChild(name: "action", value: "Install")
        //        print("updatedContent is:\(self.aexmlDoc.root.xml)")
        
        let scriptCount = scripts.count
        print("scriptCount is:\(scriptCount)")
        let updatedScriptCount = scriptCount+1
        print("updatedScriptCount is:\(updatedScriptCount)")
        self.aexmlDoc.root["scripts"].addChild(name: "size", value: String(describing:updatedScriptCount))
        
        if newPolicyFlag == true {
            self.separationLine()
            print("Is new policy - not posting package data to Jamf at this point")
        } else {
            self.separationLine()
            print("Is not new policy - posting updated package data to Jamf")
            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xmlContent.xml, httpMethod: "PUT")
        }
        
        print("addScriptToPolicy - updatedContent is:")
        print(xmlContent.xml)
        //        print(self.aexmlDoc.root.xml)
    }
    
    // ######################################################################################
    // addPackageToPolicy
    // ######################################################################################
    
    func addPackageToPolicy(xmlContent: AEXMLDocument, xmlContentString: String, authToken: String, server: String, packageName: String, packageId: String,policyId: String, resourceType: ResourceType, newPolicyFlag: Bool, action: String,fut: String, feu: String) {
        
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
        print("Running addPackageToPolicy - XML brain")
        print("Initial xmlContent in AEXMLDocument format is:")
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
        packages.addChild(name: "action", value: action)
        packages.addChild(name: "fut", value: "false")
        packages.addChild(name: "feu", value: "false")
        packages.addChild(name: "update_autorun", value: "false")
        
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        
        if debugStatus == true {
            self.atSeparationLine()
            print("updated XML after addPackageToPolicy has run is:")
            print(xmlContent.xml)
        }
        
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        
        self.atSeparationLine()
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
    
    // ######################################################################################
//    readBackUpdatedXML
    // ######################################################################################

    func readBackUpdatedXML() {
        if String(describing: self.aexmlDoc).isEmpty != true {
            self.separationLine()
            print("Running readBackUpdatedXML to confirm update - aexml is on xmlbrain")
            print(self.aexmlDoc.xml)
        } else {
            print("aexmlDoc has no data")
        }
    }
    
    
    // ######################################################################################
    // REMOVAL
    // ######################################################################################
    
    
    
    // ######################################################################################
    // removePackagesFromPolicy
    // ######################################################################################
    
    func removePackagesFromPolicy(xmlContent: AEXMLDocument,  authToken: String, server: String, policyId: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running removePackagesFromPolicy - XML brain")
        print("Initial xmlContent is:")
        self.atSeparationLine()
        print(xmlContent.xml)
        self.atSeparationLine()
        print("url is:\(url)")
        self.atSeparationLine()
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        let packages = xmlContent.root["package_configuration"]["packages"]
        let packageConfig = xmlContent.root["package_configuration"]
        print("Current packages are:\(packages.xml)")
        print("Removing current packages")
        packages.removeFromParent()
        print("Add empty packages")
        packageConfig.addChild(name: "packages")
        packages.addChild(name: "size", value: "0")
        print("Current packages are:\(packages.xml)")
        //  ################################################################################
        //              DEBUG
        //  ################################################################################
        if debugStatus == true {
            self.atSeparationLine()
            print("updated XML after removePackagesFromPolicy has run is:")
            print(xmlContent.xml)
        }
        //              ################################################################################
        //              DEBUG
        //              ################################################################################
        self.atSeparationLine()
        let packageCount = packages.count
        print("packageCount is:\(packageCount)")
        
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: ResourceType.policyDetail, xml: xmlContent.xml, httpMethod: "PUT")
        
    }
    // ######################################################################################
    // removeScriptFromPolicy
    // ######################################################################################
    
    
    func removeScriptFromPolicy(xmlContent: AEXMLDocument, authToken: String, server: String, policyId: String, selectedScriptNumber: Int) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running removeAllScriptsFromPolicy - XML brain")
        print("Initial xmlContent is:")
        self.atSeparationLine()
        print(xmlContent.xml)
        self.atSeparationLine()
        print("url is:\(url)")
        self.atSeparationLine()
        let scripts = xmlContent.root["scripts"]["script"]
        let scriptsRoot = xmlContent.root["scripts"]
        print("Current scripts are:\(scripts.xml)")
        let currentScript = self.aexmlDoc.root
        let selectedScript = self.aexmlDoc.root["scripts"].children[selectedScriptNumber]
        self.separationLine()
        print("Parameter4 is set - Remove selectedScriptParameter4")
        let removeSelectedScript: () = selectedScript.removeFromParent()
        self.separationLine()
        print("currentScript is set as:\(currentScript.xml)")

    }
    
    
    
    // ######################################################################################
    // removeAllScriptsFromPolicy
    // ######################################################################################
    
    func removeAllScriptsFromPolicy(xmlContent: AEXMLDocument,  authToken: String, server: String, policyId: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running removeAllScriptsFromPolicy - XML brain")
        print("Initial xmlContent is:")
        self.atSeparationLine()
        print(xmlContent.xml)
        self.atSeparationLine()
        print("url is:\(url)")
        self.atSeparationLine()
        let scripts = xmlContent.root["scripts"]["script"]
        let scriptsRoot = xmlContent.root["scripts"]
        print("Current scripts are:\(scripts.xml)")
        print("Removing current scripts")
        scripts.removeFromParent()
        print("Add empty scripts")
        scriptsRoot.addChild(name: "scripts")
        scripts.addChild(name: "size", value: "0")
        print("Current scripts are:\(scripts.xml)")
        //  ################################################################################
        //              DEBUG
        //  ################################################################################
        if debugStatus == true {
            self.atSeparationLine()
            print("updated XML after removePackagesFromPolicy has run is:")
            print(xmlContent.xml)
        }
        //  ################################################################################
        //              DEBUG
        //  ################################################################################
        self.atSeparationLine()
        let scriptsCount = scripts.count
        print("scriptsCount is:\(scriptsCount)")
        
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: ResourceType.policyDetail, xml: xmlContent.xml, httpMethod: "PUT")
        
    }
    
    
    
    func removeAllPackagesManual(server: String, authToken: String, policyID: String ) {
        //  Alternative method for removing all packages
        var xml:String
        
        self.separationLine()
        print("DEBUGGING")
        self.separationLine()
        print("Running removeAllPackagesManual for policy ID:\(policyID)")
        print("Url is set as:\(server)")
        
        xml = """
    <?xml version="1.0" encoding="utf-8"?>
    <policy>
        <package_configuration>
            <packages>
                <size>0</size>
            </packages>
        </package_configuration>
    </policy>
    """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/").appendingPathComponent(policyID)
                print("Running removeAllPackagesManual sendRequestAsXML - url is set as:\(url)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
    }
    
    func removeAllScriptsManual(server: String, authToken: String, policyID: String ) {
        //  Alternative method for removing all packages
        var xml:String
        self.separationLine()
        print("DEBUGGING")
        self.separationLine()
        print("Running removeAllScriptsManual for policy ID:\(policyID)")
        print("Url is set as:\(server)")
        
        xml = """
    <?xml version="1.0" encoding="utf-8"?>
    <policy>
        <scripts>
                <size>0</size>
        </scripts>
    </policy>
    """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/").appendingPathComponent(policyID)
                print("Running removeAllPackagesManual sendRequestAsXML - url is set as:\(url)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
    }
    
    
   // ######################################################################################
   // removeMaintenanceManual
   // ######################################################################################
   
   func removeMaintenanceManual(server: String, authToken: String, policyID: String ) {
       //  Alternative method for removing all packages
       var xml:String
       self.separationLine()
       print("DEBUGGING")
       self.separationLine()
       print("Running removeAllremoveMaintenanceManualScriptsManual for policy ID:\(policyID)")
       print("Url is set as:\(server)")
       
       xml = """
   <?xml version="1.0" encoding="utf-8"?>
   <policy>
     <maintenance>
         <recon>false</recon>
         <reset_name>false</reset_name>
         <install_all_cached_packages>false</install_all_cached_packages>
         <heal>false</heal>
         <prebindings>false</prebindings>
         <permissions>false</permissions>
         <byhost>false</byhost>
         <system_cache>false</system_cache>
         <user_cache>false</user_cache>
         <verify>false</verify>
     </maintenance>
   </policy>
   """
       
       if URL(string: server) != nil {
           if let serverURL = URL(string: server) {
               let url = serverURL.appendingPathComponent("/JSSResource/policies/id/").appendingPathComponent(policyID)
               print("Running removeAllPackagesManual sendRequestAsXML - url is set as:\(url)")
               sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
               print("Set updateXML to true ")
               self.updateXML = true
           }
       }
   }
    //  ################################################################################
    //              Clear - Batch Versions
    //  ################################################################################
    
    
    func clearMaintenanceBatch(selectedPoliciesInt: [Int?], server: String, authToken: String) {
            
            separationLine()
            print("Running: clearMaintenanceBatch")
            print("Set processingComplete to false")
            self.processingComplete = true
            print(String(describing: self.processingComplete))
            print("selection is:\(selectedPoliciesInt)")
                
                for policyID in selectedPoliciesInt {
                    separationLine()
                    print("policyID is:\(String(describing: policyID))")
                    print("Current policyID is:\(String(describing: policyID))")
                    xmlController.removeMaintenanceManual(server: server, authToken: authToken, policyID: String(describing: policyID))
            }
            separationLine()
            print("Finished - Set processingComplete to true")
            self.processingComplete = true
            print(String(describing: self.processingComplete))
        }
    
    func clearExclusionsBatch(selectedPolicies: Set<Policy>, server: String, authToken: String) {
        
        separationLine()
        print("Running: clearExclusionsBatch")
        for eachItem in selectedPolicies {
            let currentPolicyID = (eachItem.jamfId ?? 0)
            print("Updating for \(eachItem.name)")
            print("currentPolicyID is: \(currentPolicyID)")
            self.removeExclusions(server: server, policyID: String(describing: currentPolicyID ), authToken: authToken)
        }
    }
 
    
    func clearScopeBatch(selectedPolicies: Set<Policy>, server: String, authToken: String) {
        
        separationLine()
        print("Running: clearExclusionsBatch")
        for eachItem in selectedPolicies {
            let currentPolicyID = (eachItem.jamfId ?? 0)
            print("Updating for \(eachItem.name)")
            print("currentPolicyID is: \(currentPolicyID)")
            self.clearScope(server: server, resourceType: ResourceType.policyDetail, policyID: String(describing: currentPolicyID ), authToken: authToken)
        }
    }
    
    
    func clearScope(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        var xml: String
        
        xml = """
                       <policy>
                           <scope>
                               <all_computers>false</all_computers>
                               <computers/>
                               <computer_groups/>
                               <buildings/>
                               <departments/>
                           </scope>
                       </policy>
                       """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Making clearScope request")
                print("resourceType is set as:\(resourceType)")
                print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
//                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("clearScope request failed")
        }
    }

    func clearScopeAlt() {
        self.separationLine()
        print("Removing scope")
        let scope = aexmlDoc.root["scope"]
        scope.removeFromParent()
        self.readBackUpdatedXML()
    }
    
    func clearComputers() {
        self.separationLine()
        print("Removing computers")
        let computers = aexmlDoc.root["scope"]["computers"]
        computers.removeFromParent()
        self.readBackUpdatedXML()
    }  
    func clearComputerGroups() {
        self.separationLine()
        print("Removing computer groups")
        let computer_groups = aexmlDoc.root["scope"]["computer_groups"]
        computer_groups.removeFromParent()
        self.readBackUpdatedXML()
    }

    func clearCategory() {
        self.separationLine()
        print("Removing category")
        let category = aexmlDoc.root["general"]["category"]
        category.removeFromParent()
        self.readBackUpdatedXML()
    }
    
    func clearDockItems() {
        self.separationLine()
        print("Removing category")
        let dock_items = aexmlDoc.root["dock_items"]
        dock_items.removeFromParent()
        self.readBackUpdatedXML()
    }
    
    func clearMaintenance(server: String, authToken: String, policyID: String, policyXML: String) {
        self.separationLine()
        print("Removing Maintenance")
        let maintenance = aexmlDoc.root["maintenance"]
        maintenance.removeFromParent()
        self.readBackUpdatedXML()
        self.updatePolicy(server: server, authToken: authToken, policyID: policyID, policyXML: policyXML)
    }
    
    func clearPackage() {
        self.separationLine()
        print("Removing package")
        let package_configuration = aexmlDoc.root["package_configuration"]
        package_configuration.removeFromParent()
        self.readBackUpdatedXML()
    }
        
    func clearPrinters() {
        self.separationLine()
        print("Removing printers")
        let printers = aexmlDoc.root["printers"]
        printers.removeFromParent()
        self.readBackUpdatedXML()
    }
    func clearReboot() {
        self.separationLine()
        print("Removing reboot")
        let reboot = aexmlDoc.root["reboot"]
        reboot.removeFromParent()
        self.readBackUpdatedXML()
    }
    
    func clearScripts() {
        self.separationLine()
        print("Removing scripts")
        let scripts = aexmlDoc.root["scripts"]
        scripts.removeFromParent()
        self.readBackUpdatedXML()
    }
    
    func clearSelfService() {
        self.separationLine()
        print("Removing package")
        let self_service = aexmlDoc.root["self_service"]
        self_service.removeFromParent()
        self.readBackUpdatedXML()
    }
    
    
    
    
    
    
    func addPackageToPolicyXML (xmlString: String, packageName: String, packageId: String) -> String {
        
        let document = try! XMLDocument(xmlString: xmlString) //Change this to a suitable init
        let nodes = try! document.nodes(forXPath: "/policy/package_configuration/packages/package")
        
        for node in nodes {
            if let item = node as? XMLElement {
                self.separationLine()
                print("Node is:\(node)")
                element = XMLNode.element(withName: "name", stringValue: packageName) as! XMLNode
                item.addChild(element)
                element2 = XMLNode.element(withName: "id", stringValue: packageId) as! XMLNode
                item.addChild(element2)
            }
        }
        
        self.separationLine()
        print("element is:\(element)")
        self.separationLine()
        print("all nodes are:\(nodes)")
        self.separationLine()
        print("Updated document is:")
        self.separationLine()
        print((document))
        self.separationLine()
        print(String(describing: document))
        return String(describing: document)
        
    }
    
    
    //   #################################################################################
    //   addSelectedPackagesToPolicy
    //   #################################################################################
    
    func addSelectedPackagesToPolicy(selection: Set<Package>, authToken: String, server: String, xmlContent: AEXMLDocument, policyId: String, action: String, fut: String, feu: String) {
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("/JSSResource/policies/id/\(policyId)")
            //            let xmldata = xml.data(using: .utf8)
            
            let packageCount = selection.count
            self.separationLine()
            print("Running addSelectedPackagesToPolicy")
            print("Adding in structure to xml")
            _ = self.aexmlDoc.root.addChild(name: "package_configuration")
            _ = self.aexmlDoc.root["package_configuration"].addChild(name: "packages")
            
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
                    self.addPackageToPolicy(xmlContent: self.aexmlDoc, xmlContentString: "", authToken: authToken, server: server, packageName: currentPackageNameString, packageId: String(describing: currentPackageIdInt), policyId: policyId, resourceType: ResourceType.policyDetail, newPolicyFlag: true, action: action, fut: fut, feu: feu)
                }
            }
            
            self.separationLine()
            print("Adding packageCount:\(packageCount)")
            let packages = self.aexmlDoc.root["package_configuration"]["packages"].addChild(name: "size", value: String(describing: packageCount))
            
            //           ################################################################################
            //              DEBUG
            //           ################################################################################
            
            if debugStatus == true {
                self.atSeparationLine()
                print("updated XML after addSelectedPackagesToPolicy has run is:")
                print(self.aexmlDoc.root.xml)
            }
            self.atSeparationLine()
            print("Have finished adding packages to policy - posting xml")
            
            self.sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
        }
    }
    
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
        //      print("username is set as:\(username)")
        //      print("password is set as:\(password)")
        print("Url is set as:\(server)")
        //      print("authToken is set as:\(authToken)")
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
            }
        }
    }
    
    //    #################################################################################
    //    setPolicyTriggers
    //    #################################################################################
    
    
    func setPolicyTriggers(xmlContent: String, server: String, authToken: String, resourceType: ResourceType, itemID: Int, trigger_checkin: Bool,trigger_enrollment_complete: Bool, trigger_login: Bool, trigger_startup: Bool, trigger_other: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let itemIDString = String(itemID)
        
        readXMLDataFromString(xmlContent: xmlContent)
        if self.aexmlDoc.name.isEmpty != true {
            separationLine()
            print("Running setPolicyTriggers - xmlDoc available:\(xmlContent)")
            let wholeDoc = aexmlDoc.root
            let policyGeneral = aexmlDoc.root["general"]
            //            let policyID = policyGeneral["id"].last!
            //            let policyName = policyGeneral["name"].last!
            //    #################################################################################
            //        ADD NEW STRINGS
            //    #################################################################################
            separationLine()
            //            print("Policy name is:\(policyName)")
            print("Policy id is:\(itemIDString)")
            
            if trigger_checkin == true {
                self.separationLine()
                print("Remove current trigger_checkin")
                let _trigger_checkin = policyGeneral["trigger_checkin"].last!
                print("Removing:\(_trigger_checkin.xml)")
                _trigger_checkin.removeFromParent()
                policyGeneral.addChild(name: "trigger_checkin", value: String(describing: trigger_checkin))
                print("Setting trigger_checkin as:\(trigger_checkin)")
            } else {
                print("trigger_checkin is set as false")
            }
            
            if trigger_login == true {
                self.separationLine()
                print("Remove current trigger_login")
                let _trigger_login = policyGeneral["trigger_login"].last!
                print("Removing:\(_trigger_login.xml)")
                _trigger_login.removeFromParent()
                policyGeneral.addChild(name: "trigger_login", value: String(describing: trigger_login))
                print("Setting trigger_login as:\(trigger_login)")
            } else {
                print("trigger_login is set as false")
            }
            
            if trigger_startup == true {
                self.separationLine()
                print("Remove current trigger_startup")
                let _trigger_startup = policyGeneral["trigger_startup"].last!
                print("Removing:\(_trigger_startup.xml)")
                _trigger_startup.removeFromParent()
                policyGeneral.addChild(name: "trigger_startup", value: String(describing: trigger_startup))
                print("Setting trigger_startup as:\(trigger_startup)")
            } else {
                print("trigger_startup is set as false")
            }
            
            if trigger_enrollment_complete == true {
                self.separationLine()
                print("Remove current trigger_enrollment_complete")
                let _trigger_enrollment_complete = policyGeneral["trigger_enrollment_complete"].last!
                print("Removing:\(_trigger_enrollment_complete.xml)")
                _trigger_enrollment_complete.removeFromParent()
                policyGeneral.addChild(name: "trigger_enrollment_complete", value: String(describing: trigger_enrollment_complete))
                print("Setting trigger_enrollment_complete as:\(trigger_enrollment_complete)")
            } else {
                print("trigger_enrollment_complete is set as false")
            }
            
            if trigger_other != "" {
                self.separationLine()
                print("Remove current trigger_other")
                let _trigger_other = policyGeneral["trigger_other"].last!
                print("Removing:\(_trigger_other.xml)")
                _trigger_other.removeFromParent()
                policyGeneral.addChild(name: "trigger_other", value: String(describing: trigger_other))
                print("Setting trigger_other as:\(trigger_other)")
            } else {
                print("trigger_other is set as false")
                print("Remove current trigger_other")
                let _trigger_other = policyGeneral["trigger_other"].last!
                print("Removing:\(_trigger_other.xml)")
                _trigger_other.removeFromParent()
            }
            
            //    #################################################################################
            //        REMOVE LAST STRINGS
            //    #################################################################################
            //            separationLine()
            //            print("lastID ID IS:\(policyID.xml)")
            //            print("Removing:\(policyID.xml)")
            //            policyID.removeFromParent()
            //            print("Removing:\(policyName.xml)")
            //            policyName.removeFromParent()
            //
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running setPolicyTriggers function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: aexmlDoc.root.xml, httpMethod: "PUT")
                    //                                appendStatus("Connecting to \(url)...")
                }
            }
        }
    }
    
    
    //    #################################################################################
    //    updatePolicyScopeMultipleGroups - batch
    //    #################################################################################
    
    func updatePolicyScopeMultipleGroups(selectedPolicy: Int, server: String, authToken: String, groupSelection: Set<ComputerGroup>, xmlString: String) {
        
        //    #################################################################################
        //    Update a single policy with one or more groups - selected
        //    #################################################################################
        
        layout.separationLine()
        print("Running: updatePolicyScopeMultipleGroups")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        print("selectedPolicy is:\(selectedPolicy)")
        
        xmlController.getPolicyAsXML(server: server, policyID: selectedPolicy, authToken: authToken)
        
        for eachItem in groupSelection {
            layout.separationLine()
            print("Items as Dictionary is \(eachItem)")
            let groupID = String(describing:eachItem.id)
            let groupName: String = String(describing:eachItem.name)
            print("Current groupID is:\(groupID)")
            print("Current groupName is:\(String(describing: groupName))")
            print("Run:getPolicyAsXML")
            //          self.updateScopeAddCompGroup(xmlString: xmlString, groupName: groupName, groupId: groupId)
        }
        layout.separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    
    //    #################################################################################
    //    updatePolicy
    //    #################################################################################
    
    func updatePolicy(server: String, authToken: String, policyID: String, policyXML: String) {
  
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running updatePolicy for policy: \(policyID)")
        print("url is:\(url)")
//        print("authToken is:\(authToken)")
        
        //    #################################################################################
        //    STANDARD
        //    #################################################################################
        self.separationLine()
        print("Read main XML doc - updated")
        print(aexmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: ResourceType.policyDetail, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
        
    }
    
    
    
    
    
    //    #################################################################################
    //    readXMLDataFromStringScopingBrain
    //    #################################################################################
    
    
    func readXMLDataFromStringScopingBrain(xmlContent: String) {
        //        Reads xml and stores in a variable
        self.separationLine()
        print("Running readXMLDataFromStringScopingBrain")
        //        DEBUG readXMLDataFromStringScopingBrain
        if debugStatus == true {
            self.separationLine()
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
            self.aexmlDoc = try AEXMLDocument(xml: data)
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
            
            let currentComputerGroups = aexmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
            currentComputerGroups.addChild(name: "name", value: groupName)
            currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
            currentComputerGroups.addChild(name: "isSmart", value: "false")
            let scope = aexmlDoc.root["scope"].addChild(name: "scope")
            let allComputers = aexmlDoc.root["scope"]["all_computers"]
            allComputers.removeFromParent()
            scope.addChild(name: "all_computers", value: "false")
            self.separationLine()
            print("Read main XML doc - updated")
            print(aexmlDoc.xml)
            print("Submit updated doc")
            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
        
        let currentComputerGroups = aexmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
        currentComputerGroups.addChild(name: "name", value: groupName)
        currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
        currentComputerGroups.addChild(name: "isSmart", value: "false")
        let scope = aexmlDoc.root["scope"].addChild(name: "scope")
        let allComputers = aexmlDoc.root["scope"]["all_computers"]
        allComputers.removeFromParent()
        scope.addChild(name: "all_computers", value: "false")
        self.separationLine()
        print("Read main XML doc - updated")
        print(aexmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
//            print("Code not 200 - Response is:\(String(describing: responseCode))")
            throw JamfAPIError.badResponseCode
        }
        self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
//        return self.currentPolicyAsXML
//        DEBUG
//                    print("Policy as XML is:\(self.currentPolicyAsXML ?? ""))")

        return (String(data: data, encoding: .utf8)!)

    }
    
    
    
    //   #################################################################################
    //   getPolicyAsXML
    //   #################################################################################
    
    func getPolicyAsXML(server: String, policyID: Int, authToken: String) {

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
        separationLine()
        print("Running: xmlController.getPolicyAsXML")
        print("policyID set as: \(policyID)")
        print("jamfURLQuery set as: \(jamfURLQuery)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                //                separationLine()
                print("getPolicyAsXML failed")
                print(String(describing: error))
                return
            }

            //            #########################################################################
            //            DEBUG - CHECK XML
            //            self.separationLine()
            //                        print("xmlController.getPolicyAsXML data is:")
            //                        print(String(data: data, encoding: .utf8)!)
            //            #########################################################################

            DispatchQueue.main.async {
                self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
                print("Set updateXML to false")
                self.updateXML = false
            }
        }
        task.resume()
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
            print("Xml data is present - reading")
            let currentComputerGroups = aexmlDoc.root["scope"]["computer_groups"].addChild(name: "computer_group")
            currentComputerGroups.addChild(name: "name", value: groupName)
            currentComputerGroups.addChild(name: "id", value: String(describing: groupId))
            currentComputerGroups.addChild(name: "isSmart", value: "false")
            let scope = aexmlDoc.root["scope"].addChild(name: "scope")
            scope.addChild(name: "all_computers", value: "false")
            self.separationLine()
            print("Read main XML doc - updated")
            print(aexmlDoc.xml)
            print("Submit updated doc")
            
            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
            print("The string is not empty")
        }
    }
    
    
    //    #################################################################################
    //    addComputerToComputerGroup - requires policy as XML
    //    #################################################################################
    
    //    func addComputerToGroup(xmlContent: String, computerName: String, authToken: String, computerId: String,groupId: String, resourceType: ResourceType, server: String) {
    //
    //        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
    //
    //        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
    //        let url = URL(string: jamfURLQuery)!
    //        self.separationLine()
    //        print("Running addComputerToGroup")
    //        print("xmlContent is:\(xmlContent)")
    //        print("url is:\(url)")
    //        print("computerName is:\(computerId)")
    //        print("computerId is:\(computerId)")
    //        let computers = self.aexmlDoc.root["computers"].addChild(name: "computer")
    //        computers.addChild(name: "id", value: computerId)
    //        computers.addChild(name: "name", value: computerName)
    //        print("updatedContent is:\(self.aexmlDoc.root.xml)")
    //        let jamfCount = computers.count
    //        print("jamfCount is:\(jamfCount)")
    //        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
    //    }
    
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
        let computers = aexmlDoc.root["scope"]["computers"].addChild(name: "computer")
        computers.addChild(name: "id", value: computerId)
        computers.addChild(name: "name", value: computerName)
        let scope = aexmlDoc.root["scope"].addChild(name: "scope")
        scope.addChild(name: "all_computers", value: "false")
        self.separationLine()
        print("Read main XML doc - updated")
        print(aexmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
        let scope = aexmlDoc.root["scope"]
        let currentSettingsAllComps = aexmlDoc.root["scope"]["all_computers"]
        currentSettingsAllComps.removeFromParent()
        scope.addChild(name: "all_computers", value: "true")
        self.separationLine()
        print("Read main XML doc - updated")
        print(aexmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
    }
    
    func disableAllComputersToScope(xmlContent: String, authToken: String, resourceType: ResourceType, server: String, policyId: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyId)"
        let url = URL(string: jamfURLQuery)!
        self.readXMLDataFromStringScopingBrain(xmlContent: xmlContent)
        self.separationLine()
        print("Running addAllComputersToScope")
        let scope = aexmlDoc.root["scope"]
        let currentSettingsAllComps = aexmlDoc.root["scope"]["all_computers"]
        currentSettingsAllComps.removeFromParent()
        scope.addChild(name: "all_computers", value: "false")
        self.separationLine()
        print("Read main XML doc - updated")
        print(aexmlDoc.xml)
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
        let departments = aexmlDoc.root["scope"]["departments"].addChild(name: "department")
        departments.addChild(name: "name", value: departmentName)
        departments.addChild(name: "id", value: departmentId)
        let departmentCount = departments.count
        print("departmentCount is:\(departmentCount)")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
        let buildings = self.aexmlDoc.root["scope"]["buildings"].addChild(name: "building")
        buildings.addChild(name: "name", value: buildingName)
        buildings.addChild(name: "id", value: buildingId)
        print("updatedContent is:\(self.aexmlDoc.root.xml)")
        let buildingCount = buildings.count
        print("buildingCount is:\(buildingCount)")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
                print("policyID is:\(policyID)")
                
                if debugStatus == true {
                    print("policyAsXML is:\(policyAsXML)")
                }
                print("Xml data is present - reading and adding to:self.readXMLDataFromStringScopingBrain ")
                self.readXMLDataFromStringScopingBrain(xmlContent: policyAsXML)
                print("Adding limit_to_users")
                let currentLdapGroups = self.aexmlDoc.root["scope"]["limit_to_users"]["user_groups"]
                currentLdapGroups.addChild(name: "user_group", value: ldapUserGroupName)
                let currentLdapGroupsLimitations = self.aexmlDoc.root["scope"]["limitations"]["user_groups"].addChild(name: "user_group")
                currentLdapGroupsLimitations.addChild(name: "id", value: String(describing: ldapUserGroupID))
                currentLdapGroupsLimitations.addChild(name: "name", value: String(describing: ldapUserGroupName))
                self.separationLine()
                print("Read main XML doc - updated")
                if debugStatus == true {
                    print(self.aexmlDoc.xml)
                }
                print("Submit updated doc")
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
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
        self.readXMLDataFromStringScopingBrain(xmlContent: currentPolicyAsXML)
        self.separationLine()
        self.atSeparationLine()
        if debugStatus == true {
            print("DEBUG")
            print("currentPolicyAsXML is:\n\(currentPolicyAsXML)")
        }
        var currentScopeOverall = aexmlDoc.root["scope"]
        let currentComputers = aexmlDoc.root["scope"]["computers"]
        let currentComputer_groups = aexmlDoc.root["scope"]["computer_groups"]
        let currentBuildings = aexmlDoc.root["scope"]["buildings"]
        let currentDepartments = aexmlDoc.root["scope"]["departments"]
        let currentUserGroups = aexmlDoc.root["scope"]["limit_to_users"]["user_groups"]
        let currentUserLimitationsUsers = aexmlDoc.root["scope"]["limitations"]["users"]
        let currentUserLimitationsUserGroups = aexmlDoc.root["scope"]["limitations"]["user_groups"]
        let currentUserLimitationsNetworkSegments = aexmlDoc.root["scope"]["limitations"]["network_segments"]
        let currentUserLimitationsiBeacons = aexmlDoc.root["scope"]["limitations"]["ibeacons"]
        let currentLimitations = aexmlDoc.root["scope"]["limitations"]
        
        if let computers = aexmlDoc.root["scope"]["computers"].all {
            print("All current computers are:")
            for computer in computers {
                if let name = computer.value {
                    print(name)
                }
            }
        }
        
        if let computer_groups = aexmlDoc.root["scope"]["computer_groups"].all {
            print("All current UserGroups are:")
            for computerGroup in computer_groups {
                if let name = computerGroup.value {
                    print(name)
                }
            }
        }
        
        if let departments = aexmlDoc.root["scope"]["departments"].all {
            print("All current departments are:")
            for department in departments {
                if let name = department.value {
                    print(name)
                }
            }
        }
        
        if let limitations = aexmlDoc.root["scope"]["limitations"].all {
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
        currentScopeOverall = aexmlDoc.root["scope"]
        currentScopeOverall.addChild(currentComputers)
        currentScopeOverall.addChild(currentComputer_groups)
        currentScopeOverall.addChild(currentBuildings)
        currentScopeOverall.addChild(currentDepartments)
        separationLine()
        print("Scope overall updated is:\n\(currentScopeOverall.xml)")
        self.currentPolicyScopeXML = currentScopeOverall.xml
        self.separationLine()
        print("Read main XML doc - updated")
        print(aexmlDoc.xml)
        separationLine()
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
        print("The string is not empty")
    }
    
    
    
    //    ##################################################
    //    replaceScriptParameter
    //    ##################################################
    
    func replaceScriptParameter(authToken: String, resourceType: ResourceType, server: String, policyID: String, currentPolicyAsXML: String, selectedScriptNumber: Int, parameter4: String,parameter5: String,parameter6: String,parameter7: String,parameter8: String,parameter9: String,parameter10: String, priority: String) {
        
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyID)"
        let url = URL(string: jamfURLQuery)!
        self.readXMLDataFromStringScopingBrain(xmlContent: currentPolicyAsXML)
        self.separationLine()
        print("Running: replaceScriptParameter")
        self.separationLine()
        print("Script number is set as:\(selectedScriptNumber)")
        print("Select the script and attribute")
        let scripts = self.aexmlDoc.root["scripts"]
        let currentScript = self.aexmlDoc.root
        let selectedScript = self.aexmlDoc.root["scripts"].children[selectedScriptNumber]
        let priorityValue = self.aexmlDoc.root["scripts"]["priority"]

        self.separationLine()
        
        if parameter4.isEmpty != true {
            
            let selectedScriptParameter4 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter4"]
            self.separationLine()
            print("Parameter4 is set - Remove selectedScriptParameter4")
            let removeSelectedScriptParameter4: () = selectedScriptParameter4.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter4)")
            _ = selectedScript.addChild(name: "parameter4", value: parameter4)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
        
        if parameter5.isEmpty != true {
            let selectedScriptParameter5 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter5"]
            self.separationLine()
            print("Parameter5 is set - Remove selectedScriptParameter5")
            let removeSelectedScriptParameter5: () = selectedScriptParameter5.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter5)")
            _ = selectedScript.addChild(name: "parameter5", value: parameter5)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
        
        if parameter6.isEmpty != true {
            let selectedScriptParameter6 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter6"]
            self.separationLine()
            print("Parameter6 is set - Remove selectedScriptParameter6")
            let removeSelectedScriptParameter6: () = selectedScriptParameter6.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter6)")
            _ = selectedScript.addChild(name: "parameter6", value: parameter6)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
      
        if parameter7.isEmpty != true {
            let selectedScriptParameter7 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter7"]
            self.separationLine()
            print("Parameter7 is set - Remove selectedScriptParameter7")
            let removeSelectedScriptParameter7: () = selectedScriptParameter7.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter7)")
            _ = selectedScript.addChild(name: "parameter7", value: parameter7)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
        if parameter8.isEmpty != true {
            let selectedScriptParameter8 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter8"]
            self.separationLine()
            print("Parameter8 is set - Remove selectedScriptParameter8")
            let removeSelectedScriptParameter8: () = selectedScriptParameter8.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter8)")
            _ = selectedScript.addChild(name: "parameter8", value: parameter8)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
        if parameter9.isEmpty != true {
            let selectedScriptParameter9 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter9"]
            self.separationLine()
            print("Parameter9 is set - Remove selectedScriptParameter9")
            let removeSelectedScriptParameter9: () = selectedScriptParameter9.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter9)")
            _ = selectedScript.addChild(name: "parameter9", value: parameter9)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
        if parameter10.isEmpty != true {
            let selectedScriptParameter10 = self.aexmlDoc.root["scripts"].children[Int(selectedScriptNumber)]["parameter10"]
            self.separationLine()
            print("Parameter10 is set - Remove selectedScriptParameter10")
            let removeSelectedScriptParameter10: () = selectedScriptParameter10.removeFromParent()
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
            print("Replace the attribute with parameter:\(parameter10)")
            _ = selectedScript.addChild(name: "parameter10", value: parameter10)
            self.separationLine()
            print("currentScript is set as:\(currentScript.xml)")
        }
        
        if priority.isEmpty != true {
            self.separationLine()
            print("priority is set - Remove priority")
            let removePriority: () = priorityValue.removeFromParent()
            self.separationLine()
            print("priorityValue is set as:\(priorityValue.xml)")
            print("Replace the attribute with priority:\(priority)")
            _ = priorityValue.addChild(name: "priority", value: priority)
            self.separationLine()
            print("priorityValue is set as:\(priorityValue.xml)")
        }
        
        
        self.separationLine()
        print("Listing scripts after edit")
        print(self.aexmlDoc.root["scripts"].children.description.utf8)
        
        let numberOfScripts = self.aexmlDoc.root["scripts"]["script"].count
        //      ----------------------------------------------------
        //        Fix count
        //      ----------------------------------------------------
        self.separationLine()
        print("Counting scripts - number is:\(numberOfScripts)")
        let _: () = self.aexmlDoc.root["scripts"]["size"].removeFromParent()
        _ = scripts.addChild(name: "size", value: String(describing: numberOfScripts))
        
        self.separationLine()
        print("Read main XML doc - updated")
        print(self.aexmlDoc.xml)
        separationLine()
        print("Submit updated doc")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
        print("The string is not empty")
    }
    
    
//    ICONS
    
    func updateIconBatch(selectedPoliciesInt: [Int?], server: String,authToken: String, iconFilename: String, iconID: String, iconURI: String) {
        self.separationLine()
        print("Running updateIconBatch")
        for eachItem in selectedPoliciesInt {
            let currentPolicyID = (eachItem ?? 0)
            self.separationLine()
            print("currentPolicyID is: \(String(describing: currentPolicyID))")
            Task {
                do {
                    let policyAsXML = try await getPolicyAsXMLaSync(server: server, policyID: currentPolicyID, authToken: authToken)
                    updateIcon(server: server, authToken: authToken, policyID: String(describing: currentPolicyID), iconFilename: iconFilename, iconID: iconID, iconURI: iconURI)
                }
            }
        }
    }
    
    
    
     //    #################################################################################
    //    updateIcon
    //    #################################################################################
    
    
    func updateIcon(server: String,authToken: String, policyID: String, iconFilename: String, iconID: String, iconURI: String) {
        let resourceType: ResourceType = ResourceType.policyDetail
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        self.separationLine()
        print("Running updateIcon")
        print("iconID is set as:\(iconID)")
        print("policyID is set as:\(policyID)")
        print("iconFilename is set as:\(iconFilename)")
        print("iconURI is set as:\(iconURI)")
        
        xml = """
                <?xml version="1.0" encoding="utf-8"?>
                    <policy>
                        <general>
                            <id>\(policyID)</id>
                        </general>
                        <self_service>
                            <self_service_icon>
                                <id>\(iconID)</id>
                                <filename>\(iconFilename)</filename>
                                <uri>\(iconURI)</uri>
                            </self_service_icon>
                        </self_service>
                    </policy>
                """
                
//        #################################################################################
//        <use_for_self_service>false</use_for_self_service>
//        <self_service_display_name/>
//        <install_button_text>Install</install_button_text>
//        <reinstall_button_text>Reinstall</reinstall_button_text>
//        <self_service_description/>
//        <force_users_to_view_description>false</force_users_to_view_description>
//        #################################################################################
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    //    ##################################################
    //    addComputerToGroup
    //    ##################################################
        
    func addComputerToGroup(xmlContent: String, computerName: String,  computerId: String,groupId: String, resourceType: ResourceType, server: String, authToken: String) {
        readXMLDataFromString(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running addComputerToGroup XmlBrain")
        print("xmlContent is:\(xmlContent)")
        print("url is:\(url)")
        print("computerName is:\(computerId)")
        print("computerId is:\(computerId)")
        
        let computers = self.aexmlDoc.root["computers"].addChild(name: "computer")
        computers.addChild(name: "id", value: computerId)
        computers.addChild(name: "name", value: computerName)
        print("updatedContent is:\(self.aexmlDoc.root.xml)")
        let jamfCount = computers.count
        print("jamfCount is:\(jamfCount)")
        
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
        
    }
    
    
    //    #################################################################################
    //    removeFromGroup
    //    #################################################################################
    
    
    
    
    func removeComputerFromGroup(server: String, authToken: String, resourceType: ResourceType, groupID: String, computerID: Int, computerName: String) {
        
        var xml: String
        
        print("Running removeComputerFromGroup - updating via xml")
        print("computerID is set as:\(computerID)")
        print("computerName is set as:\(computerName)")
        print("groupID is set as:\(groupID)")
        
        xml = """
                   <computer_group>
                       <computer_deletions>
                               <computer>
                               <name>﻿\(computerName)</name>
                               </computer>
                       </computer_deletions>
                   </computer_group>
               """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
                print("Running removeComputerFromGroup function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                // self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
//                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
    //    #################################################################################
    //    removeLastComputer
    //    #################################################################################
    
    
    
    
    func removeLastComputer(xmlContent: String, computerName: String,  computerId: String,groupId: String, resourceType: ResourceType, server: String, authToken: String) {
        readXMLDataFromString(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running removeLastComputer")
        print("xmlContent is:\(xmlContent)")
        print("url is:\(url)")
        //        print("computerName is:\(computerId)")
        //        print("computerId is:\(computerId)")
        let computers = self.aexmlDoc.root["computers"]
        let lastcomputer = computers["computer"].last!
        lastcomputer.removeFromParent()
        print("updatedContent is:\(self.aexmlDoc.root.xml)")
        let jamfCount = computers.count
        print("jamfCount is:\(jamfCount)")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.aexmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    #############################################################################
    //   getGroupMembersXML - getAsXML
    //    #############################################################################
    
//    func getGroupMembersXML(server: String, groupId: Int) {
//
//        let groupIdString = String(describing: groupId )
//        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupIdString)"
//        let url = URL(string: jamfURLQuery)!
//        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
//        request.addValue("application/xml", forHTTPHeaderField: "Accept")
//        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//        request.httpMethod = "GET"
//        separationLine()
//        print("Running: getGroupMembersXML")
//        print("groupId set as: \(groupId)")
//        print("jamfURLQuery set as: \(jamfURLQuery)")
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else {
//                //                self.separationLine()
//                print("getGroupMembersXML failed")
//                print(String(describing: error))
//                return
//            }
//            //            self.separationLine()
//            print("getGroupMembersXML data is:")
//            print(String(data: data, encoding: .utf8)!)
//            DispatchQueue.main.async {
//                self.computerGroupMembersXML = (String(data: data, encoding: .utf8)!)
//            }
//        }
//        task.resume()
//    }
    
    
    //    #################################################################################
    //    Remove Exclusions
    //    #################################################################################
    
    func removeExclusions(server: String, policyID: String, authToken: String) {
        
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
        
        var xml: String
        
        xml = """
                       <policy>
                           <scope>
                               <exclusions>
                                   <computers/>
                                   <computer_groups/>
                                   <buildings/>
                                   <departments/>
                                   <users/>
                                   <user_groups/>
                                   <network_segments/>
                                   <ibeacons/>
                               </exclusions>
                           </scope>
                       </policy>
                       """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Making removeExclusions request")
                print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
//                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("removeExclusions request failed")
        }
    }
    
    
}
