import Foundation
import SwiftUI
import AEXML


@MainActor class NetBrain: ObservableObject {
    
    // #########################################################################
    // Global Variables
    // #########################################################################
    let debug_enabled = false
    // #########################################################################
    //  Build identifiers
    // #########################################################################
        let product_name = Bundle.main.infoDictionary!["CFBundleName"] as? String
        let product_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let build_version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    //    let buildString = "Version: \(appVersion ?? "").\(build ?? "")"
    //  #############################################################################
    //  Login
    //  #############################################################################
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var currentURL: String = ""
    //  #############################################################################
    //  Login and Tokens Confirmations
    //  #############################################################################

    @Published var status: String = ""
    // Published separate status for policy delay messages so UI can show it without
    // being clobbered by other status updates.
    @Published var policyDelayStatus: String = ""
    var tokenComplete: Bool = false
    var tokenStatusCode: Int = 0
    var authToken = ""
    var encoded = ""
    var initialDataLoaded = false
    
    //  #############################################################################
    //    Alerts
    //  #############################################################################

    @Published var showAlert = false
    var alertMessage = ""
    var alertTitle = ""
    var showActivity = false
    
    
    //  #############################################################################
    //    RequestSender
    //  #############################################################################

    // Construct a RequestSender using the current AppStorage `server` and the runtime `authToken`.
        // Use a computed property so the latest values are always used when making requests.
        private var requestSender: RequestSender {
            RequestSender(server: server, authToken: authToken)
        }

//        enum NetError: Error {
//            case couldntEncodeNamePass
//            case badResponseCode
//        }
//
//        struct JamfProAuth: Decodable {
//            let token: String
//            let expires: String
//        }
        
    
    //  #############################################################################
    //    ############ Category
    //  #############################################################################

    @Published var category: [Category] = []
    @Published var categories: [Category] = []
    
    //  #############################################################################
    //    ############ Buildings
    //  #############################################################################

    @Published var buildings: [Building] = []
    
    //  #############################################################################
    //    ############ Config Profiles
    //  #############################################################################

    @Published var allConfigProfiles: ConfigurationProfiles = ConfigurationProfiles()
    
    //  #############################################################################
    //    ############ Department
    //  #############################################################################

    @Published var department: [Department] = []
    @Published var departments: [Department] = []
    //  #############################################################################
    //    Icons
    //  #############################################################################
    //  #################################################################################
    @Published var allIconsDetailed: [Icon] = []
    @Published var iconDetailed: Icon = Icon(id: 0, url: "", name: "")
    
    
    //  #############################################################################
    //    Error Codes
    //  #############################################################################

    @Published var currentResponseCode: String = ""
    @Published var hasError: Bool = false
    // Compatibility shims used by legacy Views
    @Published var needsCredentials: Bool = false
    @Published var connected: Bool = false
    @Published var isLoading: Bool = false
    @Published var password: String = ""
    @Published var showErrorAlert: Bool = false
    
    //  #############################################################################
    //    ############ Screen Access
    //  #############################################################################

    var showLoginScreen = true
    var allComputersComplete = false
    var allPoliciesComplete = false
    var allPackagesComplete = false
    var allPoliciesStatusCode: Int = 0
    var resourceAccess = true
    @Published var showingWarning = false
    
    //  #############################################################################
    //    ############ Computers
    //  #############################################################################

    @Published var computers: [Computer] = []
    @Published var computersBasic: [Computers.ComputerResponse] = []
    @Published var allComputersBasic: ComputerBasic = ComputerBasic(computers: [])
    @Published var allComputersBasicDict = [ComputerBasicRecord]()
    
    //  #############################################################################
    //    ############ GROUPS
    //  #############################################################################

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
    
    //  #############################################################################
    //    ############ Packages
    //  #############################################################################

    @Published var currentPackages: [Package] = []
    @Published var allPackagesAssignedToAPolicyGlobal: [Package?] = []
    @Published var packages: [Package] = []
    @Published var packagesAssignedToPolicy: [ Package ] = []
    @Published var allPackages: [Package] = []
    
    @Published var packageDetailed: PackageDetailed? = PackageDetailed(id: 0, name: "", category: "", filename: "" , info: "", notes: "", priority: 0, rebootRequired: false,fillUserTemplate: false, fillExistingUsers: false, allowUninstalled: false,
                                                                       osRequirements: "", requiredProcessor: "", hashType: "", hashValue: "", switchWithPackage: "",
                                                                       installIfReportedAvailable: "", reinstallOption: "", sendNotification: false  )
    
    //  #############################################################################
    //    ############ Policies
    //  #############################################################################

    @Published var policies: [Policy] = []
    @Published var fetchedDetailedPolicies: Bool = false
    @Published var currentPolicyID: Int = 0
    @Published var currentPolicyName: String = ""
    @Published var currentPolicyIDIString: String = ""
    
    @Published var allPolicies: PolicyBasic? = nil
    @Published var allPoliciesConverted: [Policy] = []
    @Published var currentDetailedPolicy: PoliciesDetailed? = nil
    @Published var currentDetailedPolicy2: PolicyDetailed? = nil
    @Published var policyDetailed: PolicyDetailed? = nil
    @Published var allPoliciesDetailed: [PolicyDetailed?] = []
    @Published var allPoliciesDetailedGeneral: [General] = []
    
    var singlePolicyDetailedGeneral: General? = nil
    
    //    var imageA1: UIImage? = nil
    //    var imageA2: UIImage!
    //    var imageA3: UIImage = UIImage()
    //    var imageA4: UIImage? = UIImage()
    
    //  #############################################################################
    //    XML data
    //  #############################################################################

    @Published var aexmlDoc: AEXMLDocument = AEXMLDocument()
    @Published var computerGroupMembersXML: String = ""
//    @Published var currentPolicyAsXML: String = ""
    @Published var updateXML: Bool = false
    
    //  #############################################################################
    //    ############ Scripts
    //  #############################################################################

    @Published var scripts: [ScriptClassic] = []
    @Published var allScripts: [ScriptClassic] = []
    @Published var allScriptsVeryDetailed: [Scripts] = []
    @Published var allScriptsDetailed: [Script] = []
    @Published var scriptDetailed: Script = Script(id: "")
    @Published var allPolicyScripts: [PolicyScripts] = []
    
    //  #############################################################################
    //    ############  Search properties
    //  #############################################################################

    @Published var policiesMissingItems: [Int] = []
    @Published var policiesMatchingItems: [Int] = [0]
    //  #############################################################################
    //    ############ SELECTIONS
    //  #############################################################################

    @Published var selectedSimpleComputer: Computer = Computer(id: 0, name: "")
    @Published var selectedCategory: Category = Category(jamfId: 0, name: "")

    
    //  #############################################################################
    //    ############ BOOLEAN - TOGGLES
    //  #############################################################################

    //    @Published var enableDisable: Bool = true
    //    @State var currentSelection: Category = Category(jamfId: 0, name: "")
    
    //  #############################################################################
    //    ############ Process lists - for batch operations
    //  #############################################################################

    @Published var computerProcessList: [Computer] = []
    @Published var policyProcessList: [Policy] = []
    @Published var policiesProcessList: [Policy] = []
    @Published var packageProcessList: [Package] = []
    @Published var genericProcessList: [Any] = []
    @Published var processingComplete: Bool = true
    
    //  #######################################################################
    //  Example Resource types
    //  #######################################################################
    //
    // ResourceType.category
    // ResourceType.computer
    // ResourceType.computerBasic
    // ResourceType.computerDetailed
    // ResourceType.computerGroup
    // ResourceType.configProfileMacOS
    // ResourceType.configProfileDetailedMacOS
    // ResourceType.department
    // ResourceType.mobile
    // ResourceType.account
    // ResourceType.command
    // ResourceType.package
    // ResourceType.packages
    // ResourceType.policy
    // ResourceType.policies
    // ResourceType.policyDetail
    // ResourceType.script
    // ResourceType.scripts
    //
    
//    #################################################################################
//    Initialisers
//    #################################################################################

    // Configurable minimum interval between detailed policy requests (seconds).
    // This value is persisted to UserDefaults under the key "policyRequestDelay" so it can be
    // adjusted by the user via preferences (or programmatically by the UI).
    @Published var policyRequestDelay: TimeInterval
    private var lastRequestDate: Date?

    init(minInterval: TimeInterval = 3.0) {
        // look for a persisted setting first
        let persisted = UserDefaults.standard.double(forKey: "policyRequestDelay")
        if persisted > 0 {
            self.policyRequestDelay = persisted
        } else {
            self.policyRequestDelay = minInterval
        }
        print("NetBrain initialized: policyRequestDelay = \(self.policyRequestDelay) seconds (\(formatDuration(self.policyRequestDelay)))")
    }

    // Public setter to update and persist the delay. Call from a preferences view or programmatically.
    func setPolicyRequestDelay(_ seconds: TimeInterval) {
        guard seconds >= 0 else { return }
        self.policyRequestDelay = seconds
        UserDefaults.standard.set(seconds, forKey: "policyRequestDelay")
        separationLine()
        let human = formatDuration(seconds)
        print("Policy request delay updated to \(seconds) seconds (\(human)). Persisted to UserDefaults key 'policyRequestDelay'.")
        // update the separate policyDelayStatus so UI components can display the delay without
        // having their general status overwritten elsewhere.
        DispatchQueue.main.async {
            self.policyDelayStatus = "Policy request delay: \(human)"
        }
    }

    func getPolicyRequestDelay() -> TimeInterval { self.policyRequestDelay }

    // Public helper so views can display a duration consistently.
    func humanReadableDuration(_ seconds: TimeInterval) -> String {
        return formatDuration(seconds)
    }

    // Helper to render a TimeInterval in a human readable form
    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 0.001 { return "0s" }
        if seconds < 1 { return String(format: "%.0f ms", seconds * 1000) }
        if seconds < 60 { return String(format: "%.2f s", seconds) }
        let total = Int(seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 { return String(format: "%dh %02dm %02ds", hours, mins, secs) }
        return String(format: "%dm %02ds", mins, secs)
    }
    
    //    #################################################################################
    //    Functions
    //    #################################################################################
    
    func getComputersBasic(server: String, authToken: String) async throws {
        
        print("Running getComputersBasic")
        let jamfURLQuery = server + "/JSSResource/computers/subset/basic"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        //        separationLine()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
        
        let decoder = JSONDecoder()
        
        self.allComputersBasic = try decoder.decode(ComputerBasic.self, from: data)
        
        
        self.allComputersBasicDict = self.allComputersBasic.computers
        
        self.initialDataLoaded = true
        
    }
    
    
    //    #################################################################################
    //    try await functions
    //    #################################################################################
    
    
    //   #################################################################################
    //    try await getAllGroups
    //    #################################################################################
    
    func getAllGroups(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/computergroups"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getAllGroups")
        print("jamfURLQuery is: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        //        DEBUG
        //        separationLine()
        //        print("getAllGroups - processDetail Json data as text is:")
        //        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        
        //        DispatchQueue.main.async {
        self.allComputerGroups = try decoder.decode(Man1fest0.allComputerGroups.self, from: data).computerGroups
        //        }
    }
    
    //    #################################################################################
    //    try await get Group Members - simple auth
    //    #################################################################################
    
    func getGroupMembers(server: String,  name: String) async throws {
        let jamfURLQuery = server + "/JSSResource/computergroups/name/" + name
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        separationLine()
        print("Running func: getGroupMembers")
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
    
    
    func getDepartmentScope(server: String, id: String) async throws {
        
        let jamfURLQuery = server + "/v1/departments/" + id
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getDepartments")
        print("jamfURLQuery is: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        separationLine()
        print("getDepartmentScope - processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.departments = try decoder.decode([Department].self, from: data)
        //        print("Decoded departments are:\(allDepartments)")
        //        for department in allDepartments {
        //            print("- \(department)")
        //        }
    }
    
    func receivedCategory(categories: [Category]) {
        DispatchQueue.main.async {
            self.categories = categories
            // self.status = "Computers retrieved"
            //        self.status = "Categories retrieved"
        }
    }
    func getCategoryScope(server: String, id: String) async throws {
        
        let jamfURLQuery = server + "/v1/categories/" + id
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("\(String(describing: product_name))/\(String(describing: product_version))", forHTTPHeaderField: "User-Agent")
        separationLine()
        print("User-Agent is: \(String(describing: product_name))/\(String(describing: product_version))")
        
        separationLine()
        print("Running func: getDepartments")
        print("jamfURLQuery is: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        separationLine()
        print("processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.categories = try decoder.decode([Category].self, from: data)
    }
    
    func getCategories(server: String, authToken: String) async throws {
        
        let jamfURLQuery = server + "/JSSResource/categories"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getCategories")
        print("jamfURLQuery is: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        separationLine()
        print("processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
            
           do {
               let response = try decoder.decode(AllCategories.self, from: data)
               self.categories = response.categories
               self.separationLine()
               print("getCategories Decoding succeeded")
               
           } catch {
               self.separationLine()
               print("getCategories Decoding failed - error is:")
               print(error)
           }
           
    }
    
    func getDepartments(server: String) async throws {
        
        let jamfURLQuery = server + "/JSSResource/departments"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getDepartments")
        print("jamfURLQuery is: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        separationLine()
        print("processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.departments = try decoder.decode([Department].self, from: data)
        
    }
    
    func getOSXConfigProfiles(server: String, authToken: String) async throws {
        
        let jamfURLQuery = server + "/JSSResource/osxconfigurationprofiles"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getOSXConfigProfiles")
        print("Url is:\(url)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        print("Decoding without array - using ConfigurationProfiles")
        self.allConfigProfiles = try decoder.decode(ConfigurationProfiles.self, from: data)
    }
    
    
    
    
    func getAllPackages(server: String) async throws {
        let jamfURLQuery = server.hasSuffix("/") ? server + "JSSResource/packages" : server + "/JSSResource/packages"
        guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getAllPackages")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        self.allPackages = try decoder.decode(Packages.self, from: data).packages
        allPackagesComplete = true
        print("allPackagesComplete status is set to:\(allPackagesComplete)")
    }

    // Process enabling/disabling and category update for a set of Policy objects (legacy wrapper)
    func processUpdatePolicies(selection: Set<Policy>, server: String, resourceType: ResourceType, enableDisable: Bool, authToken: String) {
        separationLine()
        print("Running: processUpdatePolicies")
        // Use the NetBrain.selectedCategory as the category to apply if present
        let cat = self.selectedCategory
        let categoryID = String(describing: cat.jamfId)
        let categoryName = cat.name
        let enableString = enableDisable ? "true" : "false"

        for each in selection {
            let policyID = String(describing: each.jamfId ?? 0)
            updateCategoryEnDisable(server: server, resourceType: resourceType, policyEnDisable: enableString, categoryID: categoryID, categoryName: categoryName, updatePressed: true, policyID: policyID, authToken: authToken)
        }
        self.processingComplete = true
    }

    // Similar wrapper for the integer-array style selection used elsewhere
    func processUpdatePoliciesCombined(selection: [Int?], server: String, resourceType: ResourceType, enableDisable: Bool, authToken: String) {
        separationLine()
        print("Running: processUpdatePoliciesCombined")
        let cat = self.selectedCategory
        let categoryID = String(describing: cat.jamfId)
        let categoryName = cat.name
        let enableString = enableDisable ? "true" : "false"

        for each in selection {
            let policyID = String(describing: each ?? 0)
            updateCategoryEnDisable(server: server, resourceType: resourceType, policyEnDisable: enableString, categoryID: categoryID, categoryName: categoryName, updatePressed: true, policyID: policyID, authToken: authToken)
        }
        self.processingComplete = true
    }
    
    //    #################################################################################
    //    run operation - processPoliciesSelected - pass in function
    //    #################################################################################
    
    
    func processPoliciesSelected(selectionConverted: [Policy], operation:(String)->Void) {
        
        //    #################################################################################
        //    Operation is a function passed in as a parameter - policies are supplied as an array
        //    #################################################################################
        
        print("Doing stuff with selection")
        
        for eachItem in selectionConverted {
            
            print("Current policyID is:\(currentPolicyID)")
                        
            policyProcessList.insert(eachItem, at: 0)
            
            print("Doing function for item:\(currentPolicyID)")
            
            operation(String (describing: currentPolicyID))
        }
    }
    
    
    //    #################################################################################
    //    processComputersSelected
    //    #################################################################################
    
    
    func processComputersSelected(selection: Set<Computer>,  server: String, resourceType: ResourceType, url: String) {
        print("Running processComputersSelected")
        
        for eachItem in selection {
            
            print("Item is \(eachItem)")
            //            let computerID = String(eachItem.id)
            let computerIDInt = eachItem.id
            print("Current computerID is:\(computerIDInt)")
            print("Adding computer:\(eachItem.name) to list")
            computerProcessList.insert(eachItem, at: 0)
            print("Doing function for item:\(computerIDInt)")
            
            //            self.downloadFileAsync(objectID: computerIDInt.description, resourceType: resourceType, server: server, url: url) { (path, error) in}
            
        }
    }
    
    
    
    //    #################################################################################
    //    Run function on selected computers
    //    #################################################################################
    
    
//    func processAllComputers(computers: [Computer],  server: String, resourceType: ResourceType, url: String) {
//
//        print("Running processAllComputers")
//        for eachItem in computers {
//            self.separationLine()
//            print("Item is \(eachItem)")
//            let computerIDInt = eachItem.id
//            print("Current computerID is:\(computerIDInt)")
//            print("Adding computer:\(eachItem.name) to list")
//            computerProcessList.insert(eachItem, at: 0)
//            print("Doing function for item:\(computerIDInt)")
//
//
//            //    #################################################################################
//            //      run operation - download file
//            //    #################################################################################
//
//            //            self.downloadFileAsync(objectID: String(describing: computerIDInt), resourceType: resourceType, server: server, url: url) { (path, error) in}
//        }
//    }
    
    
    
    
    //    #################################################################################
    //      delete package selection
    //    #################################################################################
    
    
    func processUpdatePackagesCategory(selection:  Set<Package>, server: String,  resourceType: ResourceType, authToken: String, selectedCategory: Category) {
        
        separationLine()
        print("Running: processUpdatePackagesCategory")
        print("Doing stuff with selection")
        print("Current selectedCategory is:\(String(describing: selectedCategory.name))")
        
        for eachItem in selection {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let packageID: String = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.jamfId )
            print("Current packageID is:\(packageID)")
            print("Current jamfID is:\(String(describing: jamfID))")
            
            self.updateCategory(server: server,authToken: authToken, resourceType: ResourceType.package, categoryID: String(describing: selectedCategory.jamfId), categoryName: String(describing: selectedCategory.name), updatePressed: true, resourceID: jamfID)
            
        }
    }
    
    
    
    //    #################################################################################
    //      delete package selection
    //    #################################################################################
    
    
    func processDeletePackages(selection: Set<Package>, server: String,  resourceType: ResourceType, authToken: String) {
        
        separationLine()
        print("Running: processDeletePackages3")
        print("Doing stuff with selection")
        
        for eachItem in selection {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let packageID: String = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.jamfId )
            print("Current packageID is:\(packageID)")
            print("Current jamfID is:\(String(describing: jamfID))")
            deletePackage(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken )
            print("Adding package:\(String(describing: eachItem.name)) to list")
            packageProcessList.insert(eachItem, at: 0)
            print("List is:\(packageProcessList)")
        }
    }
    
    //    #################################################################################
    //    Delete polcies selection
    //    #################################################################################
    
    
    func processDeletePolicies(selection: Set<Policy>, server: String,  resourceType: ResourceType, authToken: String) {
        
        separationLine()
        print("Running: processDeletePolicies")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
//        print("selection is:\(selection)")

        for eachItem in selection {
            separationLine()
//            print("Processing items from Dictionary:\(eachItem)")
            let policyID = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.jamfId ?? 0)
//            print("Current policyID is:\(policyID)")
            print("processDeletePolicies jamfID is:\(String(describing: jamfID))")
            deletePolicy(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken )
//            print("List is:\(packageProcessList)")
        }
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    //    #################################################################################
    //    Delete polcies selection General
    //    #################################################################################
    
    
    func processDeletePoliciesGeneral(selection: [Int?], server: String, authToken: String,  resourceType: ResourceType) {
        
        separationLine()
        print("Running: processDeletePoliciesGeneral")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        print("selection is:\(selection)")

        for eachItem in selection {
            separationLine()
            print("Running deletePolicy - processing items from Dictionary:\(String(describing: eachItem ?? 0))")
            let policyID = String(describing:eachItem ?? 0)
            print("Current policyID is:\(policyID)")
            deletePolicy(server: server, resourceType: resourceType, itemID: policyID, authToken: authToken )
        }
        
        
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    //    #################################################################################
    //    delete computers selection
    //    #################################################################################
    
    
    func processDeleteComputers(selection:  Set<Computer>, server: String, authToken: String, resourceType: ResourceType) {
        
        separationLine()
        print("Running: processDeleteComputers")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
        for eachItem in selection {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let computerID = String(describing:eachItem.id)
            print("Current computerID is:\(computerID)")
            deleteComputer(server: server, authToken: authToken, resourceType: resourceType, itemID: computerID )
            print("List is:\(computerProcessList)")
        }
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    func processDeleteComputersBasic(selection:  Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType) {
        
        separationLine()
        print("Running: processDeleteComputers")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
        for eachItem in selection {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let computerID = String(describing:eachItem)
            print("Current computerID is:\(computerID)")
            deleteComputer(server: server, authToken: authToken, resourceType: resourceType, itemID: computerID )
            print("List is:\(computerProcessList)")
        }
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    //    #################################################################################
    //    updateComputerName -edit Name
    //    #################################################################################
    
    
    func updateComputerName(server: String,authToken: String, resourceType: ResourceType, computerName: String, computerID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        //        let computerID = computerID
        var xml: String
        
        print("Running updateComputerName")
        
        print("Updating XML")
        print("computerName is set as:\(computerName)")
        print("computerID is set as:\(computerID)")
        
        xml = """
                <computer>
                    <general>
                        <name>\(computerName)</name>
                    </general>
                </computer>
                """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(computerID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
                
            }
        }
    }
    
    
    //    #################################################################################
    //    updateName -editName - rename
    //    #################################################################################
    
    
    func updateName(server: String,authToken: String, resourceType: ResourceType, policyName: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        self.separationLine()
        print("updateName XML")
        print("policyName is set as:\(policyName)")
        
        xml = """
                <policy>
                    <general>
                        <name>\(policyName)</name>
                    </general>
                </policy>
                """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
                
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }
        
    //    #################################################################################
    //    updatePackageName -editName - rename
    //    #################################################################################
    
    
    func updatePackageName(server: String,authToken: String, resourceType: ResourceType, packageName: String, packageID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let packageID = packageID
        var xml: String
        self.separationLine()
        print("updateName XML")
        print("packageName is set as:\(packageName)")
        xml = """
                <package>
                        <name>\(packageName)</name>
                </package>
                """
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(packageID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    //    #################################################################################
    //    updatePackageFileName -editName - rename
    //    #################################################################################
    
    func updatePackageFileName(server: String,authToken: String, resourceType: ResourceType, packageFileName: String, packageID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let packageID = packageID
        var xml: String
        self.separationLine()
        print("updateName XML")
        print("packageName is set as:\(packageFileName)")
        xml = """
                <package>
                        <filename>\(packageFileName)</filename>
                </package>
                """
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(packageID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    
    //    #################################################################################
    //    updatePackageNotes
    //    #################################################################################
    
    func updatePackageNotes(server: String,authToken: String, resourceType: ResourceType, packageNotes: String, packageID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let packageID = packageID
        var xml: String
        self.separationLine()
        print("updatePackageNotes XML")
        print("packageNotes is set as:\(packageNotes)")
        xml = """
                <package>
                        <notes>\(packageNotes)</notes>
                </package>
                """
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(packageID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    //    #################################################################################
    //    updatePackageInfo
    //    #################################################################################
    
    func updatePackageInfo(server: String,authToken: String, resourceType: ResourceType, packageInfo: String, packageID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let packageID = packageID
        var xml: String
        self.separationLine()
        print("updatePackageInfo XML")
        print("packageInfo is set as:\(packageInfo)")
        xml = """
                <package>
                        <info>\(packageInfo)</info>
                </package>
                """
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(packageID)
                print("Running update policy name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    func updateSSName(server: String, authToken: String, resourceType: ResourceType, providedName: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        
        print("Updating XML")
        print("policySSName is set as:\(providedName)")
        
        xml = """
                <policy>
                    <self_service>
                        <self_service_display_name>\(providedName)</self_service_display_name>
                    </self_service>
                </policy>
                """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running updateSSName name function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                //                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }
    
    
    
    
    func updateCustomTrigger(server: String,authToken: String, resourceType: ResourceType, policyCustomTrigger: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        
        
        print("Updating XML")
        print("policyCustomTrigger is set as:\(policyCustomTrigger)")
        
        xml = """
                <policy>
                    <general>
                        <trigger_other>\(policyCustomTrigger)</trigger_other>
                    </general>
                </policy>
                """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running update policy trigger function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                //                sendRequestAsXML(url: url, as: username, password: password, resourceType: resourceType, xml: xml, httpMethod: "PUT" , authToken: authToken)
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                
                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    //    #################################################################################
    //    updateCategory - policy
    //    #################################################################################
    
    
    func updateCategory(server: String, authToken: String, resourceType: ResourceType, categoryID: String, categoryName: String, updatePressed: Bool, resourceID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        print("resourcePath is:\(resourcePath)")
        //        let resourceID = policyID
        var xml: String = ""
        
        print("Running updateCategory")
        if updatePressed == true {
            print("Updating XML")
            print("categoryID is set as:\(categoryID)")
            print("categoryName is set as:\(categoryName)")
            
            if URL(string: server) != nil {
                
                if let serverURL = URL(string: server) {
                    
                    if resourceType == ResourceType.package {
                        
                        print("resourceType is:\(resourceType)")
                        
                        xml = """
                <package>
                    <category>\(categoryName)</category>
                </package>
                """
                        let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(resourceID)
                        print("Running update category function - url is set as:\(url)")
                        print("resourceType is set as:\(resourceType)")
                        sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                        
                    } else {
                        
                        print("resourceType is:\(resourceType)")
                        
                        xml = """
                <policy>
                    <general>
                        <category>
                            <id>\(categoryID)</id>
                            <name>\(categoryName)</name>
                        </category>
                    </general>
                </policy>
                """
                        let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(resourceID)
                        print("Running update category function - url is set as:\(url)")
                        print("resourceType is set as:\(resourceType)")
                        sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                        
                    }
                    
                    print("xml is set as:\(xml)")
                    //                    appendStatus("Connecting to \(url)...")
                }
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }
    
    //    #################################################################################
    //    updateCategoryName
    //    #################################################################################
    
    func updateCategoryName(server: String, authToken: String, resourceType: ResourceType, categoryID: String, categoryName: String, updatePressed: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        print("resourcePath is:\(resourcePath)")
        var xml: String = ""
        
        print("Running updateCategoryName")
        if updatePressed == true {
            print("Updating XML")
            print("categoryID is set as:\(categoryID)")
            print("categoryName is set as:\(categoryName)")
            
            if URL(string: server) != nil {
                
                if let serverURL = URL(string: server) {
                    
                    xml = """
                <root>
                    <category>\(categoryName)</category>
                </root>                
                """
                    let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(categoryID)
                    print("Running update category name function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                }
                print("xml is set as:\(xml)")
                //                    appendStatus("Connecting to \(url)...")
                //            }
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }
    //    #################################################################################
    //    updateDepartmentName
    //    #################################################################################
    
    func updateDepartmentName(server: String, authToken: String, resourceType: ResourceType, departmentID: String, departmentName: String, updatePressed: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        print("resourcePath is:\(resourcePath)")
        
        print("Running updateDepartmentName")
        if updatePressed == true {
            print("Updating XML")
            print("departmentID is set as:\(departmentID)")
            print("departmentName is set as:\(departmentName)")
            
            if URL(string: server) != nil {
                
                if let serverURL = URL(string: server) {
                    
                    let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(departmentID)
                    print("Running update department function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    let parameters = "{\n  \"name\": \"\(departmentName)\",\n  \"id\": \"\(departmentID)\"\n}"
                    
                    sendRequestAsJson(url: url, authToken: authToken, resourceType: resourceType, httpMethod: "PUT", parameters: parameters)
                    print("parameters are set as:\(parameters)")
                }
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }
    //    #################################################################################
    //    updateBuildingName
    //    #################################################################################
    
    func updateBuildingName(server: String, authToken: String, resourceType: ResourceType, buildingID: String, buildingName: String, updatePressed: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        print("resourcePath is:\(resourcePath)")
        
        print("Running updateBuildingName")
        if updatePressed == true {
            print("Updating XML")
            print("buildingID is set as:\(buildingID)")
            print("buildingName is set as:\(buildingName)")
            
            if URL(string: server) != nil {
                
                if let serverURL = URL(string: server) {
                    
                    let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(buildingID)
                    print("Running update department function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    let parameters = "{\n  \"name\": \"\(buildingName)\",\n  \"id\": \"\(buildingID)\"\n}"
                    
                    sendRequestAsJson(url: url, authToken: authToken, resourceType: resourceType, httpMethod: "PUT", parameters: parameters)
                    print("parameters are set as:\(parameters)")
                }
            }
        }
        
        else {
            print("Nothing to do")
            
        }
    }
    //    #################################################################################
    //    updateCategory - computer
    //    #################################################################################
    
    
    func updateComputerDepartment(server: String, authToken: String, resourceType: ResourceType, departmentName: String, computerID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        //        let computerID = computerID
        var xml: String
        
        print("Running updateComputerDepartment")
        
        print("Updating XML")
        //            print("categoryID is set as:\(categoryID)")
        print("categoryName is set as:\(departmentName)")
        print("ResourceType is set as:\(resourceType)")
        //        print("buildingName is set as:\(buildingName)")
        
        xml = """
                <computer>
                    <location>
                        <department>\(departmentName)</department>
                    </location>
                </computer>
                """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(computerID)
                print("Running update computer department function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                //                appendStatus("Connecting to \(url)...")
                
            } else {
                print("Error making serverURL")
            }
            
        } else {
            print("error encountered with server:\(server)")
        }
    }
    
    
    //    #################################################################################
    //    updateCategoryEnDisable - update Category and enable/disable policy
    //    #################################################################################
    
    func updateCategoryEnDisable(server: String, resourceType: ResourceType, policyEnDisable: String, categoryID: String, categoryName: String, updatePressed: Bool, policyID: String, authToken: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        
        print("Running updateCategoryEnDisable")
        if updatePressed == true {
            print("Updating XML")
            print("categoryID is set as:\(categoryID)")
            print("categoryName is set as:\(categoryName)")
            
            xml = """
                       <policy>
                           <general>
                               <enabled>\(policyEnDisable)</enabled>
                               <category>
                                   <id>\(categoryID)</id>
                                   <name>\(categoryName)</name>
                               </category>
                           </general>
                       </policy>
                       """
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                    print("Running update updateCategoryEnDisable function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    print("xml is set as:\(xml)")
                    self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    appendStatus("Connecting to \(url)...")
                }
            }
        }
        else {
            print("Nothing to do")
        }
    }
    
    
    //    #################################################################################
    //    Remove Limitations
    //    #################################################################################
    
    func removeLimitations(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        var xml: String
        
        xml = """
                       <policy>
                           <scope>
                               <limitations>
                                   <users/>
                                   <user_groups/>
                                   <network_segments/>
                                   <ibeacons/>
                               </limitations>
                           </scope>
                       </policy>
                       """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Making removeLimitations request")
                print("resourceType is set as:\(resourceType)")
                print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("removeLimitations request failed")
        }
    }
    
    
    //    #################################################################################
    //    Remove All Scoping
    //    #################################################################################
    
    func clearScope(server: String, resourceType: ResourceType, authToken: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        var xml: String
        
        xml = """
                       <policy>
                           <scope>
                               <all_computers>false</all_computers>
                               <all_jss_users>false</all_jss_users>
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
                print("Running clearScope ")
                print("resourceType is set as:\(resourceType)")
                print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("clearScope request failed")
        }
    }
    
    
    //    #################################################################################
    //    Remove All individual computers
    //    #################################################################################
    
    func clearComputers(server: String, resourceType: ResourceType, authToken: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        var xml: String
        
        xml = """
                       <policy>
                           <scope>
                               <computers/>
                           </scope>
                       </policy>
                       """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Making clearComputers request")
                print("resourceType is set as:\(resourceType)")
                print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("clearComputers request failed")
        }
    }
    
      
    //    #################################################################################
    //    Remove All computer groups - static and smart groups
    //    #################################################################################
    
    func clearComputerGroups(server: String, resourceType: ResourceType, authToken: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        var xml: String
        
        xml = """
                       <policy>
                           <scope>
                               <computer_groups/>
                           </scope>
                       </policy>
                       """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Making clearComputerGroups request")
                print("resourceType is set as:\(resourceType)")
                print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
        else {
            print("clearComputerGroups request failed")
        }
    }
    
    
    //    #################################################################################
    //    updateGroup - addToGroup
    //    #################################################################################
    
    
    func updateGroup(server: String,authToken: String, resourceType: ResourceType, groupID: String, computerID: Int, computerName: String) {
        
        var xml: String
        
        print("Running updateGroup - updating via xml")
        print("computerID is set as:\(computerID)")
        print("computerName is set as:\(computerName)")
        print("groupID is set as:\(groupID)")
        
        xml = """
                   <computer_group>
                       <computers>
                               <computer>
                               <name>﻿\(computerName)</name>
                               </computer>
                       </computers>
                   </computer_group>
                   """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
                print("Running update group function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    func updateGroupID(server: String,authToken: String, resourceType: ResourceType, groupID: String, computerID: Int) {
        
        var xml: String
        
        print("Running updateGroupID - updating via xml")
        print("computerID is set as:\(computerID)")
        print("groupID is set as:\(groupID)")
        
        
xml = """
    <computer_group>
        <computer_additions>
            <computer>
                <id>\(computerID)</id>
            </computer>
        </computer_additions>
    </computer_group>
"""
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
                print("Running create group function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                            
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
     func updateGroupNameID(server: String,authToken: String, resourceType: ResourceType, groupID: String, computerID: Int, computerName: String) {
        

        var xml: String
        
        print("Running updateGroup - updating via xml")
        print("computerID is set as:\(computerID)")
        print("computerName is set as:\(computerName)")
        print("groupID is set as:\(groupID)")
        
        xml = """
                   <computer_group>
                       <computers>
                               <computer>
                               <name>﻿\(computerName)</name>
                               <id>\(computerID)</id>
                               </computer>
                       </computers>
                   </computer_group>
                   """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
                print("Running update group function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    //    #################################################################################
    //    processAddComputersToGroup
    //    #################################################################################
    
    
    func processAddComputersToGroup(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String,resourceType: ResourceType, computerGroup: ComputerGroup) {
        
        separationLine()
        print("Running: processAddComputersToGroup")
        print("Set is:\(selection)")
//        print("Set processingComplete to false")
//        self.processingComplete = true
//        print(String(describing: self.processingComplete))
        var count = 1
        
        for eachItem in selection {
            
            //        ########################################################
            //        Rate limiting
            //        ########################################################

//            let now = Date()
//            Task {
//                if let last = lastRequestDate {
//                    print("Last request ran at:\(String(describing: last))")
//                    let elapsed = now.timeIntervalSince(last)
//                    if elapsed < minInterval {
//                        let delay = minInterval - elapsed
//                        print("Waiting:\(String(describing: delay))")
//                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
//                    }
//                }
//            }
//            lastRequestDate = Date()
            
            separationLine()
            print("Count is currently:\(count)")
            print("Items as Dictionary is \(eachItem)")
            let computerID = String(describing: eachItem)
            print("Current computerID is:\(computerID)")
            updateGroupID(server: server, authToken: authToken, resourceType: resourceType, groupID: String(describing: computerGroup.id), computerID: Int(computerID) ?? 0 )
            print("List is:\(computerProcessList)")
            count = count + 1
            print("Count is now:\(count)")
        }
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    func processAddComputersToGroupAsync(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String,resourceType: ResourceType, computerGroup: ComputerGroup) async {
        
        separationLine()
        print("Running: processAddComputersToGroup")
        print("Set is:\(selection)")
//        print("Set processingComplete to false")
//        self.processingComplete = true
//        print(String(describing: self.processingComplete))
        var count = 1
        
        for eachItem in selection {
            
            //        ########################################################
            //        Rate limiting
            //        ########################################################

//            let now = Date()
//            Task {
//                if let last = lastRequestDate {
//                    print("Last request ran at:\(String(describing: last))")
//                    let elapsed = now.timeIntervalSince(last)
//                    if elapsed < minInterval {
//                        let delay = minInterval - elapsed
//                        print("Waiting:\(String(describing: delay))")
//                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
//                    }
//                }
//            }
//            lastRequestDate = Date()
            
            separationLine()
            print("Count is currently:\(count)")
            print("Items as Dictionary is \(eachItem)")
            let computerID = String(describing: eachItem)
            print("Current computerID is:\(computerID)")
            updateGroupID(server: server, authToken: authToken, resourceType: resourceType, groupID: String(describing: computerGroup.id), computerID: Int(computerID) ?? 0 )
            print("List is:\(computerProcessList)")
            count = count + 1
            print("Count is now:\(count)")
        }
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
    }
    
    
    
    
    //    #################################################################################
    //    togglePolicyOnOff - enable/disable policy
    //    #################################################################################
    
    func togglePolicyOnOff(server: String, authToken: String, resourceType: ResourceType, itemID: Int, policyToggle: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let itemIDString = String(itemID)
        var xml: String
        
        print("Running togglePolicyOnOff")
        if policyToggle == false {
            print("Enabling")
            xml = "<policy><general><enabled>false</enabled></general></policy>"
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running togglePolicyOnOff policy function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    print("xml is set as:\(xml)")
                    sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    appendStatus("Connecting to \(url)...")
                }
            }
        }
        
        else {
            print("Disabling")
            xml = "<policy><general><enabled>true</enabled></general></policy>"
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running togglePolicyOnOff policy function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    print("xml is set as:\(xml)")
                    self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    appendStatus("Connecting to \(url)...")
                }
            }
        }
    }
    
    //    #################################################################################
    //    toggleSelfServiceOnOff - enable/disable SelfService
    //    #################################################################################
    
    func toggleSelfServiceOnOff(server: String, authToken: String, resourceType: ResourceType, itemID: Int, selfServiceToggle: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let itemIDString = String(itemID)
        var xml: String
        
        print("Running toggleSelfServiceOnOff")
        print("selfServiceToggle is currently\(selfServiceToggle)")
        
        
        if selfServiceToggle == true {
            print("Enabling")
            xml = "<policy><self_service><use_for_self_service>true</use_for_self_service></self_service></policy>"
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running toggleSelfServiceOnOff policy function - url is set as:\(url)")
                    print("ItemID is set as:\(itemIDString)")
                    print("resourceType is set as:\(resourceType)")
                    self.separationLine()
                    print("xml is set as:\(xml)")
                    sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                }
            }
        }
        
        else {
            print("Disabling")
            xml = "<policy><self_service><use_for_self_service>false</use_for_self_service></self_service></policy>"
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running togglePolicyOnOff policy function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    self.separationLine()
                    print("xml is set as:\(xml)")
                    self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    
                    appendStatus("Connecting to \(url)...")
                }
            }
        }
    }
    
    
    //    #################################################################################
    //    enableSelfService - enable SelfService
    //    #################################################################################
    
    func enableSelfService(server: String, authToken: String, resourceType: ResourceType, itemID: Int, selfServiceToggle: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let itemIDString = String(itemID)
        var xml: String
        print("Running enableSelfService")
        xml = "<policy><self_service><use_for_self_service>true</use_for_self_service></self_service></policy>"
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                print("policyID is set as:\(itemIDString)")
                print("resourceType is set as:\(resourceType)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    //    #################################################################################
    //    scopeAllComputers - enable AllComputers
    //    #################################################################################
    
    func scopeAllComputers(server: String, authToken: String, policyID: String) {
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
//        let policyIDString = String(policyID)
        var xml: String
        print("Running scopeAllComputers")
        xml = "<policy><scope><all_computers>true</all_computers></scope></policy>"
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    //    #################################################################################
    //    scopeDisableAllComputers - disable All Computers
    //    #################################################################################
    
    func scopeDisableAllComputers(server: String, authToken: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
        var xml: String
        print("Running scopeDisableAllComputers")
        xml = "<policy><scope><all_computers>false</all_computers></scope></policy>"
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
    //    #################################################################################
    //    scopeAllUsers - enable All Users
    //    #################################################################################
    
    func scopeAllUsers(server: String, authToken: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
        var xml: String
        print("Running scopeAllUsers")
        xml = "<policy><scope><all_jss_users>true</all_jss_users></scope></policy>"
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
    //    #################################################################################
    //    scopeDisableAllUsers - disable All Users
    //    #################################################################################
    
    func scopeDisableAllUsers(server: String, authToken: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
        var xml: String
        print("Running scopeDisableAllUsers")
        xml = "<policy><scope><all_jss_users>false</all_jss_users></scope></policy>"
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
    //    #################################################################################
    //    scopeAllComputersAndUsers  - enable AllComputers and Allsers
    //    #################################################################################
    
    func scopeAllComputersAndUsers(server: String, authToken: String, policyID: String) {
        let resourcePath = getURLFormat(data: (ResourceType.policyDetail))
//        let policyIDString = String(policyID)
        var xml: String
        print("Running scopeAllComputersAndUsers")
        
                xml = """
                        <policy>
                            <scope>
                                <all_computers>true</all_computers>
                                <all_jss_users>true</all_jss_users>
                            </scope>
                        </policy>
                    """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("policyID is set as:\(policyID)")
                print("resourceType is set as:\(ResourceType.policyDetail)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    

    //    #################################################################################
    //    togglePolicyAllComputers - yes/no
    //    #################################################################################
    
    func toggleScopeAllComputers(server: String, authToken: String, resourceType: ResourceType, itemID: Int, policyToggle: Bool) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let itemIDString = String(itemID)
        var xml: String
        print("Running toggleScopeAllComputers")
        if policyToggle == false {
            
            xml = "<policy><scope><all_computers>true</all_computers></scope></policy>"
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running toggleScopeAllComputers policy function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    print("xml is set as:\(xml)")
                    sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    appendStatus("Connecting to \(url)...")
                }
            }
        }
        
        else {
            xml = "<policy><scope><all_computers>false</all_computers></scope></policy>"
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running toggleScopeAllComputers policy function - url is set as:\(url)")
                    print("resourceType is set as:\(resourceType)")
                    print("xml is set as:\(xml)")
                    self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    appendStatus("Connecting to \(url)...")
                }
            }
        }
    }
    
    //    #################################################################################
    //    EDITING POLICIES - via XML - END
    //    #################################################################################
    
    //    Create department objects via data
    
    func createDepartment(name: String, server: String, authToken: String) {
        
        let id = "0"
        let parameters = "{\n  \"name\": \"\(name)\",\n  \"id\": \"\(id)\"\n}"
        let postData = parameters.data(using: .utf8)
        var request = URLRequest(url: URL(string: "\(server)/api/v1/departments")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.httpMethod = "POST"
        request.httpBody = postData
        
        print("Creating department with name:\(name)")
        print("Url is:\(server)/api/v1/departments")
        print("Parameters are:\(parameters)")
        //  print("authToken is:\(authToken)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
    
    //    #################################################################################
    //    Create building objects via data
    //    #################################################################################
    
    func createBuilding(name: String, server: String, authToken: String) {
        
        let id = "16"
        
        separationLine()
        print("Creating building with name:\(name)")
        print("Url is:\(server)/JSSResource/buildings/id/\(id)")
//        print("Token is:\(self.authToken)")
        
        
        let parameters = "<building>\n\t<name>\(name)</name>\n</building>"
        
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "\(server)/JSSResource/buildings/id/\(id)")!,timeoutInterval: Double.infinity)
        
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
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
    
    
    //    #################################################################################
    //    Create category objects via data
    //    #################################################################################
    
    func createCategory(name: String, server: String, authToken: String) {
        
        //        let id = "0"
        let priority = "9"
        
        let parameters = "{\n  \"name\": \"\(name)\",\n  \"priority\": \"\(priority)\"\n}"
        
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "\(server)/api/v1/categories")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.httpMethod = "POST"
        request.httpBody = postData
        
        separationLine()
        print("Creating category with name:\(name)")
        print("Url is:\(server)/api/v1/categories")
        print("Parameters are:\(parameters)")
        //  print("authToken is:\(authToken)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard let data = data else {
                
                print("Error encountered:\(String(describing: error))")
                
                DispatchQueue.main.async {
                    
                    self.currentResponseCode = String(describing: statusCode)
                    
                }
                    return
            }
            print(String(data: data, encoding: .utf8)!)
            print("statusCode is:\(String(describing: statusCode))")
            if statusCode != 200 {
                print("Code not 200")
                
                DispatchQueue.main.async {
                    
                    self.hasError = true
                    self.currentResponseCode = String(describing: statusCode)
                }
                
            }

        }
        
        task.resume()
        
    }
    
    //    #################################################################################
    //    Create Static Group objects via data
    //    #################################################################################
    
    func createSmartGroup(name: String, smart: Bool, server: String, authToken: String) {
        
        let id = "0"
        
        let parameters = "<computer_group>\n\t<name>\(name)</name>\n\t<is_smart>\(smart)</is_smart>\n\t<site>\n\t\t<id>\(id)</id>\n\t\t<name>None</name>\n\t</site>\n\t<criteria>\n\t\t<criterion>\n\t\t\t<name>Last Inventory Update</name>\n\t\t\t<priority>0</priority>\n\t\t\t<and_or>and</and_or>\n\t\t\t<search_type>more than x days ago</search_type>\n\t\t\t<value>7</value>\n\t\t\t<opening_paren>false</opening_paren>\n\t\t\t<closing_paren>false</closing_paren>\n\t\t</criterion>\n\t</criteria>\n</computer_group>"
        
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "\(server)/Resources/computergroups/id/\(id)")!,timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.httpMethod = "POST"
        request.httpBody = postData
        
        separationLine()
        print("Running createSmartGroup")
        print("Creating group with name:\(name)")
        print("Url is:\(server)/Resources/computergroups/id/\(id)")
        print("Parameters are:\(parameters)")
        //  print("authToken is:\(authToken)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
    
    
    //    #################################################################################
    //    Create Static Group objects via data
    //    #################################################################################
    
    func createStaticGroup(name: String,  smart: Bool, server: String, resourceType: ResourceType, authToken: String) {
        
        let id = "0"
        var xml: String
        
        separationLine()
        print("Running createStaticGroup - updating via xml")
        print("Group name is set as:\(name)")
        //        print("authToken is set as:\(authToken)")
        
        xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <computer_group>
            <name>\(name)</name>
            <is_smart>false</is_smart>
            <site>
                <id>\(id)</id>
                <name>None</name>
            </site>
            <criteria>
                <criterion>
                    <name>Last Inventory Update</name>
                    <priority>0</priority>
                    <and_or>and</and_or>
                    <search_type>more than x days ago</search_type>
                    <value>7</value>
                    <opening_paren>false</opening_paren>
                    <closing_paren>false</closing_paren>
                </criterion>
            </criteria>
        </computer_group>
        """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(id)
                print("Running create group function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "POST")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    //    #################################################################################
    //    Create Package Record
    //    #################################################################################
    
    func createPackageRecord(name: String, server: String,authToken: String) {

        let id = "0"
//        var xml: String
        
        separationLine()
        print("Running createPackageName - updating via xml")
        print("Package name is set as:\(name)")
        //        print("authToken is set as:\(authToken)")
        
       let xml = """
        <package>
         <name>\(name)</name>
         <filename>\(name)</filename>
         <priority>10</priority>
         <reboot_required>false</reboot_required>
         <boot_volume_required>true</boot_volume_required>
        </package>
        """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/packages/id/").appendingPathComponent(id)
                print("Running create group function - url is set as:\(url)")
//                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.package, xml: xml, httpMethod: "POST")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
   
    
    
    
    
    
    
    // MARK: - Small compatibility helpers and network helpers
    func appendStatus(_ text: String) {
        DispatchQueue.main.async { self.status = text }
    }

    func separationLine() { Man1fest0.separationLine() }
    func atSeparationLine() { Man1fest0.atSeparationLine() }

    // MARK: - Compatibility shims used by legacy Views
    // Minimal implementations that forward to existing methods where available.
    func load() async {
        // no-op compatibility; ensure loading flag is cleared
        await MainActor.run { self.isLoading = false }
    }
    
    func connect() async {
        await MainActor.run { self.needsCredentials = false; self.connected = true }
    }
    
    func connect(server: String, resourceType: ResourceType, authToken: String) {
        // Store token and perform a lightweight request for common resource types
        self.authToken = authToken
        Task {
            await MainActor.run { self.connected = true }
            switch resourceType {
            case .policy, .policies:
                try? await self.getAllPolicies(server: server, authToken: authToken)
            case .category:
                try? await self.getCategories(server: server, authToken: authToken)
            case .packages, .package:
                try? await self.getAllPackages(server: server)
            case .computerBasic:
                try? await self.getComputersBasic(server: server, authToken: authToken)
            default:
                break
            }
        }
    }
    
    func connect(to server: String, as username: String, password: String, resourceType: ResourceType) {
        Task {
            await MainActor.run {
                self.password = password
                self.connected = true
            }
        }
    }
    
    func processUpdateComputerName(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, computerName: String) {
        for eachItem in selection {
            let computerID = String(describing: eachItem)
            updateComputerName(server: server, authToken: authToken, resourceType: resourceType, computerName: computerName, computerID: computerID)
        }
    }
    
    func processUpdateComputerDepartmentBasic(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, department: String) {
        for eachItem in selection {
            let computerID = String(describing: eachItem)
            updateComputerDepartment(server: server, authToken: authToken, resourceType: resourceType, departmentName: department, computerID: computerID)
        }
    }
    
    func deleteGroup(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }
    
    func deleteScript(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }
    
    func refreshDepartments() {
        Task { try? await self.getDepartments(server: self.server) }
    }
    
    func getToken(server: String, username: String, password: String) async throws {
        await MainActor.run {
            self.password = password
            self.connected = true
            if self.authToken.isEmpty { self.authToken = "" }
        }
    }
    
    func processBatchUpdateCategory(selection: [Int?], server: String, resourceType: ResourceType, authToken: String, newCategoryName: String, newCategoryID: String) {
        for each in selection {
            let policyID = String(describing: each ?? 0)
            updateCategory(server: server, authToken: authToken, resourceType: resourceType, categoryID: newCategoryID, categoryName: newCategoryName, updatePressed: true, resourceID: policyID)
        }
    }
    
    func clearScope(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        clearScope(server: server, resourceType: resourceType, authToken: authToken, policyID: policyID)
    }

    func deletePolicy(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        guard let serverURL = URL(string: server) else { return }
        let resourcePath = getURLFormat(data: resourceType)
        let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
        requestDelete(url: url, authToken: authToken, resourceType: resourceType)
    }

    func deletePackage(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }

    func deleteComputer(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
    }

    // Synchronous-style XML sender used across the codebase
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) {
        let headers = ["Accept": "application/xml", "Content-Type": "application/xml", "Authorization": "Bearer \(authToken)"]
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = httpMethod
        request.httpBody = xml.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Task { await MainActor.run { self.appendStatus("XML request failed: \(error)") } }
                return
            }
            if let response = response as? HTTPURLResponse {
                Task { await MainActor.run { self.appendStatus("XML request completed: \(response.statusCode)") } }
            }
        }
        task.resume()
    }

    func sendRequestAsJson(url: URL, authToken: String, resourceType: ResourceType, httpMethod: String, parameters: String) {
        var request = URLRequest(url: url, timeoutInterval: 30.0)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = httpMethod
        request.httpBody = parameters.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Task { await MainActor.run { self.appendStatus("JSON request failed: \(error)") } }
                return
            }
            if let response = response as? HTTPURLResponse {
                Task { await MainActor.run { self.appendStatus("JSON request completed: \(response.statusCode)") } }
            }
        }
        task.resume()
    }

    // Async XML sender that callers sometimes await
    func sendRequestAsXMLAsyncID(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String, policyID: String) async throws {
        try await sendRequestAsXMLAsync(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: httpMethod)
    }

    func sendRequestAsXMLAsync(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) async throws {
        var request = URLRequest(url: url, timeoutInterval: 60.0)
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = httpMethod
        request.httpBody = xml.data(using: .utf8)
        let (_, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status < 200 || status >= 300 { throw JamfAPIError.http(status) }
    }

    // Used by concurrent detailed policy fetcher
    func fetchPolicyDetailed(server: String, authToken: String, policyID: String) async throws -> PolicyDetailed? {
        let jamfURLQuery = server.hasSuffix("/") ? server + "JSSResource/policies/id/" + policyID : server + "/JSSResource/policies/id/" + policyID
        guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw JamfAPIError.http(status) }
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PoliciesDetailed.self, from: data).policy
        return decoded
    }
    
    // Fetch list of policies (shallow) and populate `allPolicies`/`allPoliciesConverted`.
    func getAllPolicies(server: String, authToken: String) async throws {
        separationLine()
        print("Running getAllPolicies (compat)")
        let jamfURLQuery = server.hasSuffix("/") ? server + "JSSResource/policies" : server + "/JSSResource/policies"
        guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw JamfAPIError.http(status) }

        // Try to decode into known types. If decoding fails, leave lists empty but don't crash.
        do {
            let decoder = JSONDecoder()
            // There are a few possible shapes for policies responses in this codebase; try broad decode
            if let decoded = try? decoder.decode(PolicyBasic.self, from: data) {
                await MainActor.run {
                    self.allPolicies = decoded
                    self.allPoliciesConverted = decoded.policies
                    self.allPoliciesComplete = true
                }
            } else if let decoded = try? decoder.decode(Man1fest0.PolicyBasic.self, from: data) {
                await MainActor.run {
                    self.allPolicies = decoded
                    self.allPoliciesConverted = decoded.policies
                    self.allPoliciesComplete = true
                }
            } else {
                // Attempt generic decode of Policies wrapper if present
                struct PoliciesWrapper: Codable { var policies: [Policy] }
                if let wrapped = try? decoder.decode(PoliciesWrapper.self, from: data) {
                    await MainActor.run {
                        self.allPoliciesConverted = wrapped.policies
                        self.allPoliciesComplete = true
                    }
                } else {
                    print("getAllPolicies: unable to decode policy list; raw body:\n\(String(data: data, encoding: .utf8) ?? "")")
                }
            }
        } catch {
            print("getAllPolicies decoding error: \(error)")
            throw error
        }
    }

    // Convenience overload used in some call sites
    func getAllPolicies(server: String) async throws {
        try await getAllPolicies(server: server, authToken: self.authToken)
    }

    // Fetch detailed policies (one-per-policy) and populate allPoliciesDetailed.
    // This implementation is intentionally simple: it requests each detailed policy using
    // the existing `fetchPolicyDetailed` helper and appends the result. It updates
    // published properties on the MainActor.
    func getAllPoliciesDetailed(server: String, authToken: String, policies: [Policy]) async throws {
        separationLine()
        print("Running getAllPoliciesDetailed (compat)")
        // Reset
        await MainActor.run {
            self.allPoliciesDetailed = []
            self.fetchedDetailedPolicies = false
        }

        for policy in policies {
            let id = String(describing: policy.jamfId ?? 0)
            do {
                if let detailed = try await fetchPolicyDetailed(server: server, authToken: authToken, policyID: id) {
                    await MainActor.run {
                        self.allPoliciesDetailed.append(detailed)
                    }
                }
                // Respect a small delay between calls if configured
                if policyRequestDelay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(policyRequestDelay * 1_000_000_000))
                }
            } catch {
                print("fetchPolicyDetailed failed for id=\(id): \(error)")
            }
        }

        await MainActor.run {
            self.fetchedDetailedPolicies = true
        }
    }
}
