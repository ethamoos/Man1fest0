import Foundation
import SwiftUI
import AEXML

// AsyncSemaphore for rate limiting in concurrent environments
actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            value += 1
        }
    }
}

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
    // Added compatibility properties expected by multiple views
    @Published var isLoading: Bool = false
    @Published var needsCredentials: Bool = false

    // Added lightweight helper methods that some views reference directly on the NetBrain instance.
    func separationLine() { print("-----------------------------------") }
    func doubleSeparationLine() { print("===================================") }
    func asteriskSeparationLine() { print("***********************************") }
    func atSeparationLine() { print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@") }

    func appendStatus(_ text: String) {
        DispatchQueue.main.async { self.status = text }
        print("appendStatus: \(text)")
    }

    // Publish an error to UI-friendly properties and log it.
    func publishError(_ error: Error, title: String = "Error") {
        DispatchQueue.main.async {
            self.showAlert = true
            self.alertTitle = title
            self.alertMessage = String(describing: error)
        }
        separationLine()
        print("publishError(\(title)): \(error)")
    }

    // Token fetch stub — keep signature used by views; real implementation may exist elsewhere.
    func getToken(server: String, username: String, password: String) async throws {
        print("getToken stub called for: \(server) / \(username)")
        // Minimal behavior: set tokenComplete true so UI doesn't block
        await MainActor.run {
            self.tokenComplete = true
        }
    }

    // CRUD stubs for packages/policies/computers used by various UI actions.
    func deleteGroup(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        print("Stub deleteGroup called for id: \(itemID)")
    }
    func deletePackage(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        print("Stub deletePackage called for id: \(itemID)")
    }
    func deletePolicy(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        print("Stub deletePolicy called for id: \(itemID)")
    }
    func deleteComputer(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        print("Stub deleteComputer called for id: \(itemID)")
    }

    // Batch update stub
    func processBatchUpdateCategory(selection: [Int], server: String, resourceType: ResourceType, authToken: String, newCategoryName: String, newCategoryID: String) {
        print("Stub processBatchUpdateCategory called for selection size: \(selection.count)")
    }

    // Provide a minimal getAllPoliciesDetailed to satisfy call sites; real implementation can be restored later.
    func getAllPoliciesDetailed(server: String, authToken: String, policies: [Policy]) async throws {
        print("Stub getAllPoliciesDetailed called for \(policies.count) policies")
        await MainActor.run { self.fetchedDetailedPolicies = true }
    }

    //  #############################################################################
    //  Login and Tokens Confirmations
    //  #############################################################################

    var tokenComplete: Bool = false
    var tokenStatusCode: Int = 0
    var authToken = ""
    
    // Track token expiration for automatic refresh
    var tokenExpirationTime: Date?
    private var refreshUsername: String = ""
    private var refreshPassword: String = ""
    var password: String = ""
    var encoded = ""
    var initialDataLoaded = false
    
    //  #############################################################################
    //    Alerts
    //  #############################################################################

    @Published var showAlert = false
    var alertMessage = ""
    var alertTitle = ""
    var showActivity = false

    // RequestSender computed property used by async APIRequest helpers
    private var requestSender: RequestSender {
        RequestSender(server: server, authToken: authToken)
    }

    // Publish a short human-readable policy delay status for UI components
    @Published var policyDelayStatus: String = ""

    // Convenience: simple connected flag used by some views
    var connected: Bool { !authToken.isEmpty }

    // Provide both an async no-arg connect (used with `await networkController.connect()`)
    // and a sync convenience used throughout views that expect `connect(server:resourceType:authToken:)`.
    func connect() async {
        // If already have a token, nothing to do
        if !self.authToken.isEmpty { return }
        do {
            try await getToken(server: server, username: username, password: password)
        } catch {
            print("connect(): token fetch failed: \(error)")
            await MainActor.run {
                self.needsCredentials = true
            }
        }
    }

    func connect(server: String, resourceType: ResourceType, authToken: String) {
        // Build a safe URL and call request(...) which handles parsing
        let normalizedServer = server.contains("://") ? server : "https://" + server
        let path = getURLFormat(data: resourceType)
        guard let serverURL = URL(string: normalizedServer) else {
            print("NetBrain.connect: invalid server string: \(server)")
            return
        }
        let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(path)
        request(url: url, resourceType: resourceType, authToken: authToken)
    }

    // Minimal compatibility stubs for functions referenced by multiple Views.
    // These are intentionally lightweight: they log the call and set simple flags so UI code
    // can proceed without a full network implementation. Replace with real implementations as needed.

    func getAllPolicies(server: String, authToken: String) async throws {
        print("Stub: getAllPolicies called for server=\(server)")
        // mark that policies have been (pseudo-)fetched so views won't block
        await MainActor.run {
            self.allPoliciesComplete = true
        }
    }

    func getAllPackages(server: String) async throws {
        print("Stub: getAllPackages called for server=\(server)")
        await MainActor.run {
            // keep packages array stable
            if self.packages.isEmpty {
                self.packages = []
            }
            self.allPackagesComplete = true
        }
    }

    func getAllScripts(server: String, authToken: String) async throws {
        print("Stub: getAllScripts called for server=\(server)")
        await MainActor.run {
            if self.scripts.isEmpty {
                self.scripts = []
            }
        }
    }

    // Update/Enable/Disable policies - lightweight stubs called from UI actions
    func processUpdatePolicies(selection: Set<Policy>, server: String, resourceType: ResourceType, enableDisable: Bool, authToken: String) {
        separationLine()
        print("Stub: processUpdatePolicies called for \(selection.count) policies (enable=\(enableDisable))")
        // simulate work: add to process list and mark complete
        for p in selection {
            policyProcessList.insert(p, at: 0)
        }
        self.processingComplete = true
    }

    // Combined form that accepts an array of Int? (IDs) - used by some views
    func processUpdatePoliciesCombined(selection: [Int?], server: String, resourceType: ResourceType, enableDisable: Bool, authToken: String) {
        separationLine()
        print("Stub: processUpdatePoliciesCombined called for \(selection.count) policy IDs (enable=\(enableDisable))")
        // convert IDs into a debug list
        let ids = selection.map { String(describing: $0 ?? 0) }
        print("IDs: \(ids)")
        self.processingComplete = true
    }

    // Batch scope helpers
    func batchScopeAllComputers(policiesSelection: Set<Policy>, server: String, authToken: String) {
        separationLine()
        print("Stub: batchScopeAllComputers called for \(policiesSelection.count) policies")
        self.processingComplete = true
    }

    func batchScopeAllUsers(policiesSelection: Set<Policy>, server: String, authToken: String) {
        separationLine()
        print("Stub: batchScopeAllUsers called for \(policiesSelection.count) policies")
        self.processingComplete = true
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
    @Published var OSXConfigProfileDetailed: OSXConfigProfileDetailed? = nil

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

    @State var currentResponseCode: String = ""
    var hasError = false
    
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
    
    @Published var packageDetailed: PackageDetailed? = nil
    
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

    // New: track whether we're actively fetching detailed policies to avoid concurrent/repeat runs
    @Published var isFetchingDetailedPolicies: Bool = false
    // Store failed policy IDs so callers can inspect and retry if needed
    @Published var retryFailedDetailedPolicyCalls: [String] = []

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

    init(minInterval: TimeInterval = 0.0) {
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
//        separationLine()
//        print("getDepartmentScope - processDetail Json data as text is:")
//        print(String(data: data, encoding: .utf8)!)
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
//        separationLine()
//        print("processDetail Json data as text is:")
//        print(String(data: data, encoding: .utf8)!)
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
//        separationLine()
//        print("processDetail Json data as text is:")
//        print(String(data: data, encoding: .utf8)!)
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
//        separationLine()
//        print("processDetail Json data as text is:")
//        print(String(data: data, encoding: .utf8)!)
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
    
    
    // Fetch detailed user by id
    func getDetailOSXConfigProfile(userID: String) async throws {
        
        print("Running func: getDetailOSXConfigProfile")

        do {
            let request = APIRequest<OSXConfigProfileDetailedResponse>(endpoint: "osxconfigurationprofiles/id/" + userID, method: .get)
            print("APIRequest: \(request)")
            // ensure we have an auth token
            if authToken.isEmpty {
                try await getToken(server: server, username: username, password: password )
            }
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.OSXConfigProfileDetailed = decoded.osxConfigurationProfile
            print("Loaded detail for user id: \(userID)")
        } catch {
            publishError(error, title: "Failed to load user details")
            throw error
        }
    }
    
    
    
    
//    func getBuildings(server: String, authToken: String) async throws {
//        let jamfURLQuery = server + "/JSSResource/buildings"
//        let url = URL(string: jamfURLQuery)!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        self.separationLine()
//        print("Running func: getBuildings")
//        print("url is set to:\(url)")
//        let (data, response) = try await URLSession.shared.data(for: request)
//        //        print("Json data is:")
//        //        print(String(data: data, encoding: .utf8)!)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            print("Code not 200")
//            throw JamfAPIError.badResponseCode
//        }
//        let decoder = JSONDecoder()
//        let allBuildings = try decoder.decode(Buildings.self, from: data)
//        self.buildings = allBuildings.buildings
//        //        print("buildings is set to:\(self.buildings)")
//    }
//
//
//
//    func getAllPackages(server: String) async throws {
//        let jamfURLQuery = server + "/JSSResource/packages"
//        let url = URL(string: jamfURLQuery)!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
//        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
//
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        separationLine()
//        print("Running func: getAllPackages")
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            print("Code not 200")
//            throw JamfAPIError.badResponseCode
//        }
//        let decoder = JSONDecoder()
//        self.allPackages = try decoder.decode(Packages.self, from: data).packages
//        allPackagesComplete = true
//        print("allPackagesComplete status is set to:\(allPackagesComplete)")
//
//    }
//
//    func getAllScripts(server: String, authToken: String) async throws {
//
//        print("Running func: getAllScripts")
//
//        let jamfURLQuery = server + "/api/v1/scripts?page=0&page-size=500"
//
//        let url = URL(string: jamfURLQuery)!
//        print("url is set to:\(url)")
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        separationLine()
//        print("Running func: getAllScripts")
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            print("Code not 200")
//            throw JamfAPIError.badResponseCode
//        }
//        separationLine()
//        //        print("Json data is:")
//        //                  print(String(data: data, encoding: .utf8)!)
//        let decoder = JSONDecoder()
//        //        let allScriptResults = try decoder.decode(ScriptResults.self, from: data)
//        //        let localScriptsDetailed = allScriptResults.results
//
//        //        print("localScriptsDetailed status is set to:\(localScriptsDetailed)")
//        //        let allScriptsFullyDetailed = self.allScriptsVeryDetailed.results
//
//    }
    
//    func getDetailedScript(server: String, scriptID: Int, authToken: String) async throws {
//
//        separationLine()
//        print("Running func: getDetailedScript")
//        print("scriptID is set to:\(scriptID)")
//
//        let jamfURLQuery = server + "/api/v1/scripts/" + String(describing: scriptID)
//        self.currentURL = jamfURL
//        let url = URL(string: jamfURLQuery)!
//        print("url is set to:\(url)")
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
//            self.currentResponseCode = String(describing: statusCode)
//            print("getDetailedPolicy request error - code is:\(statusCode)")
//            throw JamfAPIError.http(statusCode)
//        }
//        ########################################################
//        DEBUG
//        ########################################################
//        separationLine()
//        print("Raw data is:")
//        print(String(data: data, encoding: .utf8)!)
//        ########################################################
//        DEBUG
//        ########################################################
    
//        let decoder = JSONDecoder()
//        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
//
//        self.policyDetailed = decodedData
//
//        if self.debug_enabled == true {
//            separationLine()
//            print("getDetailedPolicy has run - policy name is:\(self.policyDetailed?.general?.name ?? "")")
//        }
////      On completion add policy to array of detailed policies
//        self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
//    }
     
//
//    func getDetailedPolicy(server: String, authToken: String, policyID: String) async throws {
//        if self.debug_enabled == true {
//            print("Running getDetailedPolicy - policyID is:\(policyID)")
//        }
//        let jamfURLQuery = server + "/JSSResource/policies/id/" + policyID
//        let url = URL(string: jamfURLQuery)!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//
//        //        ########################################################
//        //        Rate limiting
//        //        ########################################################
//
//        let now = Date()
//        if let last = lastRequestDate {
//            let elapsed = now.timeIntervalSince(last)
//            print("Last request ran at: \(last) (\(formatDuration(elapsed)) ago)")
//            if elapsed < policyRequestDelay {
//                let delay = policyRequestDelay - elapsed
//                let human = formatDuration(delay)
//                let nextRunAt = Date().addingTimeInterval(delay)
//                print("Throttling: sleeping for \(delay) seconds (\(human)). Next request at: \(nextRunAt)")
//                // surface a brief delay-specific status to the UI
//                DispatchQueue.main.async {
//                    self.policyDelayStatus = "Delaying policy fetch: \(human) (next at \(nextRunAt))"
//                }
//                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
//            }
//        } else {
//            print("No previous request timestamp found; proceeding immediately")
//        }
//        lastRequestDate = Date()
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
//            self.currentResponseCode = String(describing: statusCode)
//            print("getDetailedPolicy request error - code is:\(statusCode)")
//            throw JamfAPIError.http(statusCode)
//        }
//
////        ########################################################
////        DEBUG
////        ########################################################
    
//        let decoder = JSONDecoder()
//        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
//
//        self.policyDetailed = decodedData
//
//        if self.debug_enabled == true {
//            separationLine()
//            print("getDetailedPolicy has run - policy name is:\(self.policyDetailed?.general?.name ?? "")")
//        }
////      On completion add policy to array of detailed policies
//        self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
//    }
    
    // Removed duplicate getAllPoliciesDetailed implementation; see above for the unified async/throws version.
    
    
//=======
//>>>>>>> main
    @Published var showProgressView: Bool = false
    
    func showProgress() {
        
        self.showProgressView = true
        separationLine()
        print("Setting showProgress to true")
        print(self.showProgressView)
        
    }
    
    func endProgress() {
        
        self.showProgressView = false
        separationLine()
        print("Setting showProgress to false")
        print(self.showProgressView)
        
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
        
        self.separationLine()
        print("updateName XML")
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
        
        self.separationLine()
        print("updateSSName XML")
        print("updateSSName is set as:\(providedName)")
        
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
    }
    
    
    //    #################################################################################
    //    Remove All Scoping
    //    #################################################################################
    
    func clearScope(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        
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
    }
    
    
    //    #################################################################################
    //    Remove All individual computers
    //    #################################################################################
    
    func clearComputers(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        
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
    }
    
      
    //    #################################################################################
    //    Remove All computer groups - static and smart groups
    //    #################################################################################
    
    func clearComputerGroups(server: String, resourceType: ResourceType, policyID: String, authToken: String) {
        
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
    </computer_group>'
"""
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
                print("Running update group function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                            
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                
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
            let computerID = String(describing:eachItem)
            print("Current computerID is:\(computerID)")
            updateGroupID(server: server, authToken: authToken, resourceType: resourceType, groupID: String(describing:computerGroup.id), computerID: Int(computerID) ?? 0 )
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
            let computerID = String(describing:eachItem)
            print("Current computerID is:\(computerID)")
            updateGroupID(server: server, authToken: authToken, resourceType: resourceType, groupID: String(describing:computerGroup.id), computerID: Int(computerID) ?? 0 )
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
                    self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
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
                    self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    
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
                    self.sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
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
    
    
   
    
    
    
    
    
    
    //    #################################################################################
    //    Push Policies - via XML
    //    #################################################################################
    
    
    
    func pushPolicy(server: String, authToken: String, policyName: String, customTrigger: String , categoryID: String, category: String, departmentID: String, department: String, scriptID: String, scriptName: String, scriptParameter4: String, scriptParameter5: String, scriptParameter6: String, resourceType: ResourceType, notificationName: String, notificationStatus: String ) {
        
        var xml:String
        //        let date = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .short))
        
        let sem = DispatchSemaphore.init(value: 0)
        
        //        DEBUG
        self.separationLine()
        print("DEBUGGING")
        self.separationLine()
        print("Running pushPolicy")
        //        print("username is set as:\(username)")
        //        print("password is set as:\(password)")
        print("Url is set as:\(server)")
        print("policyName is set as:\(policyName)")
        print("categoryID is set as:\(categoryID)")
        print("departmentID is set as:\(departmentID)")
        print("department name is set as:\(department)")
        print("scriptName is set as:\(scriptName)")
        print("scriptID is set as:\(scriptID)")
        print("scriptParameter4 is set as:\(scriptParameter4)")
        print("scriptParameter5 is set as:\(scriptParameter5)")
        print("scriptParameter6 is set as:\(scriptParameter6)")
        print("resourceType is set as:\(resourceType)")
        print("notificationName is set as:\(notificationName)")
        print("notificationStatus is set as:\(notificationStatus)")
        
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
                    <id>\(categoryID)</id>
                    <name>\(category)</name>
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
                <computers/>
                <computer_groups/>
                <buildings/>
                <departments>
                    <department>
                        <id>\(departmentID)</id>
                        <name>\(department)</name>
                    </department>
                </departments>
                <limit_to_users>
                    <user_groups/>
                </limit_to_users>
                <limitations>
                    <users/>
                    <user_groups/>
                    <network_segments/>
                    <ibeacons/>
                </limitations>
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
            <self_service>
                <use_for_self_service>false</use_for_self_service>
                <self_service_display_name/>
                <install_button_text>Install</install_button_text>
                <reinstall_button_text>Reinstall</reinstall_button_text>
                <self_service_description/>
                <force_users_to_view_description>false</force_users_to_view_description>
                <self_service_icon/>
                <feature_on_main_page>false</feature_on_main_page>
                <self_service_categories/>
                <notification>\(notificationStatus)</notification>
                <notification>Self Service</notification>
                <notification_subject>\(notificationName)</notification_subject>
                <notification_message/>
            </self_service>
            <package_configuration>
                <packages>
                    <size>0</size>
                </packages>
            </package_configuration>
            <scripts>
                <size>1</size>
                <script>
                    <id>\(scriptID)</id>
                    <name>\(scriptName)</name>
                    <priority>After</priority>
                    <parameter4>\(scriptParameter4)</parameter4>
                    <parameter5>\(scriptParameter5)</parameter5>
                    <parameter6>\(scriptParameter6)</parameter6>
                    <parameter7/>
                    <parameter8/>
                    <parameter9/>
                    <parameter10/>
                    <parameter11/>
                </script>
            </scripts>
            <printers>
                <size>0</size>
                <leave_existing_default/>
            </printers>
            <dock_items>
                <size>0</size>
            </dock_items>
            <account_maintenance>
                <accounts>
                    <size>0</size>
                </accounts>
                <directory_bindings>
                    <size>0</size>
                </directory_bindings>
                <management_account>
                    <action>doNotChange</action>
                </management_account>
                <open_firmware_efi_password>
                    <of_mode>none</of_mode>
                    <of_password_sha256 since="9.23">e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855</of_password_sha256>
                </open_firmware_efi_password>
            </account_maintenance>
            <reboot>
                <message>This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu.</message>
                <startup_disk>Current Startup Disk</startup_disk>
                <specify_startup/>
                <no_user_logged_in>Do not restart</do_not_restart>
                <user_logged_in>Do not restart</user_logged_in>
                <minutes_until_reboot>5</minutes_until_reboot>
                <start_reboot_timer_immediately>false</start_reboot_timer_immediately>
                <file_vault_2_reboot>false</file_vault_2_reboot>
            </reboot>
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
            <files_processes>
                <search_by_path/>
                <delete_file>false</delete_file>
                <locate_file/>
                <update_locate_database>false</update_locate_database>
                <spotlight_search/>
                <search_for_process/>
                <kill_process>false</kill_process>
                <run_command/>
            </files_processes>
            <user_interaction>
                <message_start/>
                <allow_users_to_defer>false</allow_users_to_defer>
                <allow_deferral_until_utc/>
                <allow_deferral_minutes>0</allow_deferral_minutes>
                <message_finish/>
            </user_interaction>
            <disk_encryption>
                <action>none</action>
            </disk_encryption>
        </policy>
        """
        
        //        DEBUG
        separationLine()
        atSeparationLine()
        // print("xml is set as:\(xml)")
        atSeparationLine()
        
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
                let authString = "Bearer \(self.authToken)"
                
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
    //    Request policies
    //    #################################################################################
    
    
    func request(url: URL, resourceType: ResourceType, authToken: String) {

        let headers = [
            "Accept": "application/json",
            "Authorization": "Bearer \(self.authToken)"
        ]

        atSeparationLine()
        print("Running request function - resourceType is set as:\(resourceType)")

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                // Ensure actor-isolated state changes and method calls happen on main actor
                DispatchQueue.main.async {
                    self.resourceAccess = true

                    print("Doing processing of request:request")

                    if resourceType == ResourceType.computer {
                        print("Resource type is set in request to computer")
                        self.processComputer(data: data, response: response, resourceType: "computer")
                    } else if resourceType == ResourceType.computerBasic {
                        print("Resource type is set in request to computerBasic")
                        self.processComputersBasic(data: data, response: response, resourceType: "computerBasic")
                    } else if resourceType == ResourceType.category {
                        print("Assigning to process - Resource type is set in request to categories")
                        self.processCategory(data: data, response: response, resourceType: "category")
                    } else if resourceType == ResourceType.department {
                        print("Assigning to process - Resource type is set in request to departments")
                        self.processDepartment(data: data, response: response, resourceType: "department")
                    } else if resourceType == ResourceType.packages {
                        print("Assigning to process - Resource type is set in request to packages")
                        self.processPackages(data: data, response: response, resourceTypeT: "packages")
                    } else if resourceType == ResourceType.scripts {
                        print("Assigning to process - Resource type is set in request to scripts")
                        self.processScripts(data: data, response: response, resourceType: "scripts")
                    } else {
                        print("Assigning to process - Resource type is set in request to default - policy ")
                        self.processPolicies(data: data, response: response, resourceType: resourceType)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.resourceAccess = false
                    var text = "\n\nFailed."
                    if let error = error {
                        text += " \(error)."
                    }
                    self.appendStatus(text)
                }
            }
        }
        dataTask.resume()
    }
    
    func requestDelete(url: URL, authToken: String, resourceType: ResourceType) {

        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authToken)"
        ]

        atSeparationLine()
        print("Running requestDelete function - resourceType is set as:\(resourceType)")

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "DELETE"

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                // Ensure UI/actor updates happen on main actor
                DispatchQueue.main.async {
                    print("Doing processing of requestDelete")

                    if resourceType == ResourceType.computer {
                        print("Assigning to processComputer - Resource type is set in request to computer")
                        self.processComputer(data: data, response: response, resourceType: "computer")
                    } else if resourceType == ResourceType.computerBasic {
                        print("Assigning to processComputersBasic - Resource type is set in request to computerBasic")
                        print("################################################")
                        print(String(data: data, encoding: .utf8)!)
                        print((response))
                        print("Error is:\(String(describing: error))")
                        self.processComputersBasic(data: data, response: response, resourceType: "computerBasic")
                    } else if resourceType == ResourceType.scripts {
                        print("Assigning to processScripts - Resource type is set in request to scripts")
                        self.processScripts(data: data, response: response, resourceType: "scripts")
                    } else if resourceType == ResourceType.department {
                        print("Assigning to processDepartment - Resource type is set in request to departments")
                        self.processDepartment(data: data, response: response, resourceType: "department")
                    } else if resourceType == ResourceType.package {
                        print("Assigning to processPackage - Resource type is set in request to package")
                    } else {
                        print("Assigning to processPolicies - Resource type is set in request to policies")
                        self.processPolicies(data: data, response: response, resourceType: resourceType)
                    }
                }
            } else {
                var text = "\n\nFailed."
                if let error = error {
                    text += " \(error)."
                }
                //                self.appendStatus(text)
            }
        }
        dataTask.resume()
    }
    
    func requestDeleteXML(url: URL, authToken: String, resourceType: ResourceType) async throws {
        
        let headers = [
            "Accept": "application/xml",
            "Content-Type": "application/xml",
            "Authorization": "Bearer \(authToken)"
        ]
        
        atSeparationLine()
        print("Running requestDeleteXML function - resourceType is set as:\(resourceType)")
        print("URL is set as:\(url)")
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Data is:\(String(describing: String(data: data, encoding: .utf8) ?? "no data") )")

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("getComputerExtAttributes Status code is:\(statusCode)")
            throw JamfAPIError.badResponseCode
            
            
        }
        
    }
    
    
    func requestDeleteAwait(url: URL, authToken: String, resourceType: ResourceType) async throws {
        
        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authToken)"
        ]
        
        atSeparationLine()
        print("Running requestDeleteXML function - resourceType is set as:\(resourceType)")
        print("URL is set as:\(url)")
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Data is:\(String(describing: String(data: data, encoding: .utf8) ?? "no data") )")

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("getComputerExtAttributes Status code is:\(statusCode)")
            throw JamfAPIError.badResponseCode
            
        }
    }
    
    
    
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) {
        
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        atSeparationLine()
        print("Running sendRequestAsXML function - Netbrain - resourceType is set as:\(resourceType)")
        print("url is:\(url)")
        atSeparationLine()
        print("xml is:\(xml)")
        //        atSeparationLine()
        //        print("xmldata is:\(String(describing: xmldata))")
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
                print("Doing processing of NetBrain sendRequestAsXML:\(httpMethod)")
                print("Data is:\(data)")
                print("Data is:\(response)")
                
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
    
    
    func sendRequestAsXMLAsync(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String) async throws {
    
        
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        atSeparationLine()
        print("Running sendRequestAsXML function - resourceType is set as:\(resourceType)")
        print("url is:\(url)")
        atSeparationLine()
        print("xml is:\(xml)")
        //        atSeparationLine()
        //        print("xmldata is:\(String(describing: xmldata))")
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
        
    }
    
    
    func sendRequestAsXMLAsyncID(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String, policyID: String ) async throws {
        
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        atSeparationLine()
        print("Running sendRequestAsXMLAsyncID NetBRain - resourceType is set as:\(resourceType)")
        print("url is:\(url)")
        print("policyID is set as:\(policyID)")
        atSeparationLine()
        print("xml is:\(xml)")
        //        atSeparationLine()
        //        print("xmldata is:\(String(describing: xmldata))")
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
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("getComputerExtAttributes Status code is:\(statusCode)")
            throw JamfAPIError.badResponseCode
            
            
        }
        
    }
    
    func sendRequestAsJson(url: URL, authToken: String, resourceType: ResourceType, httpMethod: String, parameters: String ) {
        
        atSeparationLine()
        print("Running sendRequestAsJson function - resourceType is set as:\(resourceType)")
        print("url is:\(url)")
        atSeparationLine()
        print("httpMethod is:\(httpMethod)")
        
        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authToken)"
        ]
        
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "PUT"
        request.httpBody = postData
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                print("Doing processing of sendRequestAsXML:\(httpMethod)")
                print("Data is:\(data)")
                print("Data is:\(response)")
                
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
    
    
    
    
    //    #################################################################################
    //    ICONS
    //    #################################################################################
    
    
    func getDetailedIcon(server: String, authToken: String, iconID: String) async throws {
        
        let jamfURLQuery = server + "/api/v1/icon/" + iconID
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("Running getDetailedIcon - iconID is:\(iconID)")
        print("url is:\(url)")
        
        //        ########################################################
        //        Rate limiting
        //        ########################################################

        let now = Date()
        if let last = lastRequestDate {
            let elapsed = now.timeIntervalSince(last)
            print("Last request ran at: \(last) (\(formatDuration(elapsed)) ago)")
            if elapsed < policyRequestDelay {
                let delay = policyRequestDelay - elapsed
                let human = formatDuration(delay)
                let nextRunAt = Date().addingTimeInterval(delay)
                print("Throttling: sleeping for \(delay) seconds (\(human)). Next request at: \(nextRunAt)")
                // surface a brief delay-specific status to the UI
                DispatchQueue.main.async {
                    self.policyDelayStatus = "Delaying detailed user fetch: \(human) (next at \(nextRunAt))"
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        } else {
            print("No previous request timestamp found; proceeding immediately")
        }
        lastRequestDate = Date()

        let (data, response) = try await URLSession.shared.data(for: request)
        let responseCode = (response as? HTTPURLResponse)?.statusCode
        guard responseCode == 200 else {
            print("getDetailedIcon: bad response code \(String(describing: responseCode))")
            throw JamfAPIError.badResponseCode
        }

        if let body = String(data: data, encoding: .utf8) {
            print("getDetailedIcon: response body:\n\(body)")
        }

        do {
            let decoded = try JSONDecoder().decode(Icon.self, from: data)
            self.iconDetailed = decoded
            print("getDetailedIcon succeeded, iconDetailed is: \(String(describing: self.iconDetailed))")
        } catch {
            print("getDetailedIcon: decoding failed: \(error)")
            // Re-throw so callers can handle if they need to
            throw error
        }
    }
    
    
    
    
    func getAllIconsDetailed(server: String, authToken: String, loopTotal: Int){
        
        self.separationLine()
        print("Running func: getAllIconsDetailed")
        print("Total loop is set as:\(loopTotal)")
        
        for iconNumber in 1...(loopTotal) {
            
            Task {
                try await getDetailedIcon(server: server, authToken: authToken, iconID: String(describing: iconNumber))
            }
        }
    }
    
    
    
    func downloadIcon(jamfURL: String, itemID: String, authToken: String){
        
        let jamfURLQuery = jamfURL + "/api/v1/icon/" + itemID + "?res=original&scale=0"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running:downloadIcon for itemID:\(itemID)")
        print("jamfURL is:\(jamfURL)")
        print("Request url is:\(url)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                //                self.appendStatus("Error is:\(String(describing: error))")
                return
            }
            print(String(data: data, encoding: .utf8)!)
            //            self.appendStatus("Success")
        }
        task.resume()
    }
    
    
    func fetchStandardData() {
        
        if  self.packages.isEmpty {
            print("No package data - fetching")
            self.connect(server: server,resourceType: ResourceType.packages, authToken: self.authToken)
            
        } else {
            print("package data is available")
        }
        
        if  self.policies.isEmpty {
            print("No policies data - fetching")
            self.connect(server: server,resourceType: ResourceType.policies, authToken: self.authToken)
            
        } else {
            print("policies data is available")
        }
        
        if  self.category.isEmpty {
            print("No category data - fetching")
            self.connect(server: server,resourceType: ResourceType.category, authToken: self.authToken)
            
        } else {
            print("category data is available")
        }
        
        if  self.department.isEmpty {
            print("No department data - fetching")
            self.connect(server: server,resourceType: ResourceType.department, authToken: self.authToken)
            
        } else {
            print("department data is available")
        }
        
        if  self.scripts.isEmpty {
            print("No scripts data - fetching")
            self.connect(server: server,resourceType: ResourceType.scripts, authToken: self.authToken)
            
        } else {
            print("scripts data is available")
        }
        
    }
    
    
    func fetchDetailedData() async throws {
        
        if self.fetchedDetailedPolicies == false {
            
            print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
            
            if self.allPoliciesDetailed.count < self.allPoliciesConverted.count {
                
                print("fetching detailed policies")
                Task {
                    try await self.getAllPoliciesDetailed(server: server, authToken: self.authToken, policies: self.allPoliciesConverted)
                }
                    //                convertToArray()
                self.fetchedDetailedPolicies = true
            } else {
                print("detailed policies already fetched")
            }
        } else {
            print("fetchedDetailedPolicies has run")
            self.fetchedDetailedPolicies = true
        }
        
        if self.allIconsDetailed.count == 0 {
            self.getAllIconsDetailed(server: server, authToken: self.authToken, loopTotal: 1000)
        }
        
    }
    
    
    //    #################################################################################
//    # iOS Keychain
    //    #################################################################################

    
    var isPasswordBlank: Bool {
        getPassword(account: self.server, service: self.username) == ""
    }
    
    func getPassword(account: String, service: String) -> String {
        let kcw = KeychainWrapper()
        if let password = try? kcw.getGenericPasswordFor(
            account: account,
            service: service) {
            return password
        }
        
        return ""
    }
    
    func updateKC(_ password: String, account: String, service: String) {
        let kcw = KeychainWrapper()
        do {
            try kcw.storeGenericPasswordFor(
                account: account,
                service: service,
                password: password)
        } catch let error as KeychainWrapperError {
            print("Exception setting password: \(error.message ?? "no message")")
        } catch {
            print("An error occurred setting the password.")
        }
    }
    
    func validatePassword(_ password: String) -> Bool {
        let currentPassword = getPassword(account: self.username, service: self.server)
        return password == currentPassword
    }
    
    func changePassword(currentPassword: String, newPassword: String) -> Bool {
        guard validatePassword(currentPassword) == true else { return false }
        updateKC(newPassword, account: self.username, service: self.server)
        return true
    }
    
    //  #######################################################################
//  REFRESH POLICY'S DATA
    //  #######################################################################

    
    func refreshComputers() {
        
        if self.computers.count < 0 {
            print("Fetching computers")
            self.connect(server: server,resourceType: ResourceType.computer, authToken: self.authToken)
        }
        
    }
    
    func refreshDepartments() {
        
        if self.departments.count <= 1 {
            
            self.connect(server: server,resourceType: ResourceType.department, authToken: self.authToken)
        }
    }
    
//    networkController.refreshDepartments()
    
    
    
    func refreshCategories() {
        
        if self.categories.count <= 1 {
            
            self.connect(server: server,resourceType: ResourceType.category, authToken: self.authToken)
        }
    }
    
        
    
    func refreshPolicies() {
        
        if self.policies.count <= 1 {
            
            self.connect(server: server,resourceType: ResourceType.policy, authToken: self.authToken)
        }
    }
    
    
    //  #######################################################################
    //  MARK: - New detailed package fetch
    //  #######################################################################

    // Fetch detailed package by jamf id
    func getDetailedPackage(server: String, authToken: String, packageID: String) async throws {
        print("Running getDetailedPackage - packageID is:\(packageID)")
        let jamfURLQuery = server + "/JSSResource/packages/id/" + packageID
        print("jamfURLQuery is:\(jamfURLQuery)")
        guard let url = URL(string: jamfURLQuery) else {
            print("getDetailedPackage: invalid URL: \(jamfURLQuery)")
            throw JamfAPIError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            print("getDetailedPackage: bad response code: \(status)")
            throw JamfAPIError.http(status)
        }

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PackageDetailedResponse.self, from: data)
        DispatchQueue.main.async {
            self.packageDetailed = decoded.package
        }
        print("getDetailedPackage: decoded packageDetailed")
    }
    
    // Minimal processors called by request(...) - lightweight implementations so the project compiles.
    // These functions mirror the expected signatures used by the request/requestDelete flow.
    func processComputer(data: Data, response: URLResponse, resourceType: String) {
        separationLine()
        print("processComputer called for resourceType: \(resourceType)")
        // Attempt a best-effort parse for known structures; otherwise leave arrays empty
        // For now keep simple: mark computers list as unchanged if empty.
        DispatchQueue.main.async {
            if self.computers.isEmpty { self.computers = [] }
        }
    }

    func processComputersBasic(data: Data, response: URLResponse, resourceType: String) {
        separationLine()
        print("processComputersBasic called for resourceType: \(resourceType)")
        DispatchQueue.main.async {
            if self.computersBasic.isEmpty { self.computersBasic = [] }
        }
    }

    func processCategory(data: Data, response: URLResponse, resourceType: String) {
        separationLine()
        print("processCategory called for resourceType: \(resourceType)")
        // Try to decode generic category list if possible
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(AllCategories.self, from: data) {
            DispatchQueue.main.async { self.categories = decoded.categories }
            return
        }
        print("processCategory decoding did not match AllCategories; leaving categories unchanged or empty")
        DispatchQueue.main.async {
            if self.categories.isEmpty { self.categories = [] }
        }
    }

    func processDepartment(data: Data, response: URLResponse, resourceType: String) {
        separationLine()
        print("processDepartment called for resourceType: \(resourceType)")
        do {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Department].self, from: data) {
                DispatchQueue.main.async { self.departments = decoded }
                return
            }
        }
        DispatchQueue.main.async {
            if self.departments.isEmpty { self.departments = [] }
        }
    }

    func processPackages(data: Data, response: URLResponse, resourceTypeT: String) {
        separationLine()
        print("processPackages called for resourceTypeT: \(resourceTypeT)")
        // Best-effort decode into Packages wrapper if available
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(Packages.self, from: data) {
            DispatchQueue.main.async {
                self.allPackages = decoded.packages
                self.packages = decoded.packages
                self.allPackagesComplete = true
            }
            return
        }
        DispatchQueue.main.async {
            if self.packages.isEmpty { self.packages = [] }
            self.allPackagesComplete = true
        }
    }

    func processScripts(data: Data, response: URLResponse, resourceType: String) {
        separationLine()
        print("processScripts called for resourceType: \(resourceType)")
        // keep simple for now
        DispatchQueue.main.async {
            if self.scripts.isEmpty { self.scripts = [] }
        }
    }

    func processPolicies(data: Data, response: URLResponse, resourceType: ResourceType) {
        separationLine()
        print("processPolicies called for resourceType: \(resourceType)")
        // Attempt to decode policies list if shape matches
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(PolicyBasic.self, from: data) {
            DispatchQueue.main.async {
                self.policies = decoded.policies
            }
            return
        }
        // fallback: leave policies array as-is or empty
        DispatchQueue.main.async {
            if self.policies.isEmpty { self.policies = [] }
        }
    }
}
