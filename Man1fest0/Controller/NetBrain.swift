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
    // Published separate status for policy delay messages so UI can show it without
    // being clobbered by other status updates.
    @Published var policyDelayStatus: String = ""
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
    @Published var OSXConfigProfileDetailed: OSXConfigProfileDetailed? = nil

    //  #############################################################################
    //    ############ Advanced Computer Searches
    //  #############################################################################

    @Published var allAdvancedComputerSearches: [AdvancedComputerSearch] = []

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
    // Published single detailed computer mapped to ComputerBasicRecord for legacy UI
    @Published var computerDetailed: ComputerBasicRecord? = nil
    // Full decoded ComputerFull published for detailed UI views
    @Published var computerDetailedFull: ComputerFull? = nil
    
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
    @Published var isFetchingDetailedPolicies: Bool = false
    @Published var retryFailedDetailedPolicyCalls: [String] = []
    // New: track whether we're actively fetching detailed policies to avoid concurrent/repeat runs
//    @Published var isFetchingDetailedPolicies: Bool = false
    // Store failed policy IDs so callers can inspect and retry if needed
//    @Published var retryFailedDetailedPolicyCalls: [String] = []

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
//        separationLine()
//        print("processDetail getGroupMembers Json data as text is:")
//        print(String(data: data, encoding: .utf8)!)
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
                _ = try await getToken(server: server, username: username, password: password )
            }
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.OSXConfigProfileDetailed = decoded.osxConfigurationProfile
            print("Loaded detail for user id: \(userID)")
        } catch {
            publishError(error, title: "Failed to load user details")
            throw error
        }
    }
    // Fetch advanced computer searches
    func getAdvancedComputerSearch(userID: String) async throws {

        print("Running func: getAdvancedComputerSearch")

        do {
            let request = APIRequest<ComputerSearches>(endpoint: "advancedcomputersearches", method: .get)
            print("APIRequest: \(request)")
            // ensure we have an auth token
            if authToken.isEmpty {
                _ = try await getToken(server: server, username: username, password: password )
            }
            let decoded = try await requestSender.resultFor(apiRequest: request)
            // Store the advanced computer searches properly
            self.allAdvancedComputerSearches = decoded.advancedComputerSearches.advancedComputerSearch
            print("Loaded \(self.allAdvancedComputerSearches.count) advanced computer searches")
        } catch {
            publishError(error, title: "Failed to load computer searches")
            throw error
        }
    }
    
    
    
    
    
    func getAllPolicies(server: String) async throws {
        let jamfURLQuery = server + "/JSSResource/policies"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getAllPolicies")
        let (data, response) = try await URLSession.shared.data(for: request)
        self.allPoliciesStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            print(response)
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        self.allPolicies = try decoder.decode(PolicyBasic.self, from: data)
        let decodedData = try decoder.decode(PolicyBasic.self, from: data).policies
        self.allPoliciesConverted = decodedData
        allPoliciesComplete = true
        self.resourceAccess = true
        separationLine()
        //        atSeparationLine()
        print("getAllPolicies status is set to:\(allPoliciesComplete)")
        print("allPolicies status code is:\(String(describing: self.allPoliciesStatusCode))")
        print("allPoliciesConverted count is:\(String(describing: self.allPoliciesConverted.count))")
    }
    
     
  
    func getDetailedPolicy(server: String, authToken: String, policyID: String) async throws {
//        if self.debug_enabled == true {
            print("Running getDetailedPolicy - policyID is:\(policyID)")
//        }
        let jamfURLQuery = server + "/JSSResource/policies/id/" + policyID
        self.currentURL = jamfURLQuery
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
                    self.policyDelayStatus = "Delaying policy fetch: \(human) (next at \(nextRunAt))"
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        } else {
            print("No previous request timestamp found; proceeding immediately")
        }
        lastRequestDate = Date()

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("getDetailedPolicy request error - code is:\(statusCode)")
            throw JamfAPIError.http(statusCode)
        }
//        ########################################################
//        DEBUG
//        ########################################################
//        separationLine()
//        print("Raw data is:")
//        print(String(data: data, encoding: .utf8)!)
//        ########################################################
//        DEBUG
//        ########################################################
    
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
        
        self.policyDetailed = decodedData

//        if self.debug_enabled == true {
            separationLine()
            print("getDetailedPolicy has run - policy name is:\(self.policyDetailed?.general?.name ?? "")")
//        print("Policy Trigger:\t\t\t\(self.policyDetailed?.general?.triggerOther ?? "")\n")

//        }
        //      On completion add policy to array of detailed policies
        self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
      
    }
    
    func getAllPoliciesDetailed(server: String, authToken: String, policies: [Policy]) async throws {
        // Avoid re-entrancy: if a fetch is already running, skip
        if isFetchingDetailedPolicies {
            print("getAllPoliciesDetailed called while a fetch is already in progress; skipping")
            return
        }
        await MainActor.run { self.isFetchingDetailedPolicies = true; self.retryFailedDetailedPolicyCalls = [] }

        // Ignore passed authToken and use managed token instead
        let validToken = try await getValidToken(server: server)
        // Print visual separator for debugging logs
        self.separationLine()
        // Log that we're running the concurrent version of this function
        print("Running func: getAllPoliciesDetailed (bounded concurrency)")

        // Filter out policies without a valid jamfId (must be > 0 to be fetchable)
        let validPolicies = policies.filter { ($0.jamfId ?? 0) > 0 }
        // Log the filtering results for debugging
        print("Total policies provided: \(policies.count) -> valid policies with jamfId>0: \(validPolicies.count)")

        // Set maximum number of tasks that can run simultaneously
        let maxConcurrentTasks = 4
        // Initialize array to track which policy fetches failed
        var failedCalls: [String] = []

        // Sequentially fetch each policy detail to avoid MainActor reentrancy issues
        for policy in validPolicies {
            let jamfIdVal = policy.jamfId ?? 0
            let policyID = String(describing: jamfIdVal)
            do {
                // Rate limiting: ensure minimum delay between requests
                let now = Date()
                let last = await MainActor.run { self.lastRequestDate }
                let delayNeeded: TimeInterval = await MainActor.run { () -> TimeInterval in
                    if let last = last {
                        let elapsed = now.timeIntervalSince(last)
                        return elapsed < self.policyRequestDelay ? (self.policyRequestDelay - elapsed) : 0
                    } else {
                        return 0
                    }
                }

                if delayNeeded > 0 {
                    let human = await MainActor.run { self.formatDuration(delayNeeded) }
                    let nextRunAt = Date().addingTimeInterval(delayNeeded)
                    print("Throttling: sleeping for \(delayNeeded) seconds (\(human)) before requesting policy \(policyID). Next at: \(nextRunAt)")
                    await MainActor.run { self.policyDelayStatus = "Delaying policy fetch: \(human) (next at \(nextRunAt))" }
                    try await Task.sleep(nanoseconds: UInt64(delayNeeded * 1_000_000_000))
                }

                // Update last request time
                await MainActor.run { self.lastRequestDate = Date() }

                // Perform the network request for the detailed policy
                try await self.getDetailedPolicy(server: server, authToken: validToken, policyID: policyID)

                let name = policy.name
                if !name.isEmpty {
                    print("Fetched policy detail for: \(name) (ID: \(policyID))")
                } else {
                    print("Fetched policy detail for ID: \(policyID)")
                }
            } catch {
                print("Error fetching detailed policy ID \(policyID): \(error)")
                await MainActor.run { failedCalls.append(policyID) }
            }
        }

        // On completion, record failures but mark detailed fetch as completed so callers don't retry infinitely
        if !failedCalls.isEmpty {
            print("getAllPoliciesDetailed completed with failures for IDs: \(failedCalls)")
            await MainActor.run {
                self.retryFailedDetailedPolicyCalls = failedCalls
                self.fetchedDetailedPolicies = true
                self.isFetchingDetailedPolicies = false
            }
        } else {
            print("getAllPoliciesDetailed completed successfully for all policies")
            await MainActor.run {
                self.fetchedDetailedPolicies = true
                self.isFetchingDetailedPolicies = false
            }
        }
    }
    //    #################################################################################
    //    FUNCTIONS
    //    #################################################################################
    
    func getPackagesAssignedToPolicy() {
        
        if let detailed = self.policyDetailed {
            if let policyPackages = detailed.package_configuration?.packages {
                self.separationLine()
                print("Running: getPackagesAssignedToPolicy")
                print("Adding currently assigned packages to packagesAssignedToPolicy:")
                for package in policyPackages {
                    self.separationLine()
                    print("Package is:\(package)")
                    packagesAssignedToPolicy.insert(package, at: 0)
                }
            }
        } else {
            self.separationLine()
            print("No getPackagesAssignedToPolicy response yet")
        }
    }
    
    
    func getDetailedPackage(server: String, authToken: String, packageID: String) async throws {
        print("Running getDetailedPackage - packageID is:\(packageID)")
        let jamfURLQuery = server + "/JSSResource/packages/id/" + packageID
        print("jamfURLQuery is:\(jamfURLQuery)")
        let url = URL(string: jamfURLQuery)!
        print("url is:\(url)")
//        print("authToken is:\(authToken)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Request data is:")
        print(String(data: data, encoding: .utf8)!)
        
        let responseCode = (response as? HTTPURLResponse)?.statusCode
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            print("Code not 200 - Response is:\(String(describing: responseCode))")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(PackageDetailedResponse.self, from: data) {
            self.packageDetailed = decodedData.package
            let packageName = String(describing: decodedData.package.name)
            separationLine()
            print("Response code is:\(String(describing: responseCode ?? 0))")
            print("packageDetailed is:\(String(describing: self.packageDetailed))")
        } else {
            print("Decoding failed")
        }
        
        self.packageDetailed = try decoder.decode(Man1fest0.PackageDetailedResponse.self, from: data).package
        print("packageDetailed is:\(String(describing: self.packageDetailed))")
        
    }
    
    
    
    
    
    
    
    
    
    
    enum NetError: Error {
        case couldntEncodeNamePass
        case badResponseCode
    }
    
    struct JamfProAuth: Decodable {
        let token: String
        let expires: String
    }
    
    //    #################################################################################
    //    REPLY STRUCTS
    //    #################################################################################
    
    struct CategoryReply: Codable {
        
        let categories: [Category]
        static func decode(_ data: Data) -> Result<[Category],Error> {
            let decoder = JSONDecoder()
            
            do {
                let response = try decoder.decode(CategoryReply.self, from: data)
                print("CategoryReply Decoding succeeded")
                return .success(response.categories)
            } catch {
                return .failure(error)
            }
        }
    }
    
    
    struct ComputersReply: Codable {
        
        let computers: [Computer]
        static func decode(_ data: Data) -> Result<[Computer],Error> {
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(ComputersReply.self, from: data)
                print("ComputersReply Decoding succeeded")
                return .success(response.computers)
            } catch {
                print("ComputersReply Decoding failed")
                return .failure(error)
            }
        }
    }
    
    struct ComputersBasicReply: Codable {
        
        let computersBasic: [Computers.ComputerResponse]
        static func decode(_ data: Data) -> Result<[Computers.ComputerResponse],Error> {
            //             separationLine()
            print("ComputersBasicReply data is:")
            print(String(data: data, encoding: .utf8)!)
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(ComputersBasicReply.self, from: data)
                print("ComputersBasicReply Decoding succeeded")
                return .success(response.computersBasic)
            } catch {
                print("ComputersBasicReply Decoding failed")
                return .failure(error)
            }
        }
    }
    
    
    struct ComputersDetailReply: Codable {
        
        let computersBasic: [Computers.ComputerResponse]
        static func decode(_ data: Data) -> Result<[Computers.ComputerResponse],Error> {
            //             separationLine()
            print("ComputersBasicReply data is:")
            //            print(String(data: data, encoding: .utf8)!)
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(ComputersBasicReply.self, from: data)
                print("ComputersBasicReply Decoding succeeded")
                return .success(response.computersBasic)
            } catch {
                print("ComputersBasicReply Decoding failed")
                return .failure(error)
            }
        }
    }
    
    
    struct DepartmentReply: Codable {
        
        let departments: [Department]
        static func decode(_ data: Data) -> Result<[Department],Error> {
            let decoder = JSONDecoder()
            
            do {
                let response = try decoder.decode(DepartmentReply.self, from: data)
                print("DepartmentReply Decoding succeeded")
                return .success(response.departments)
            } catch {
                return .failure(error)
            }
        }
    }
    
    
    struct PackagesReply: Codable {
        
        let packages: [Package]
        static func decode(_ data: Data) -> Result<[Package],Error> {
            let decoder = JSONDecoder()
            
            do {
                let response = try decoder.decode(PackagesReply.self, from: data)
                print("PackagesReply Decoding succeeded")
                //                print("DEBUG --------------------------")
                //                print(response.packages)
                return .success(response.packages)
            } catch {
                return .failure(error)
            }
        }
    }
    
    
    struct PoliciesReply: Codable {
        
        let policies: [Policy]
        static func decode(_ data: Data) -> Result<[Policy],Error> {
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(PoliciesReply.self, from: data)
                print("PoliciesReply Decoding succeeded")
                return .success(response.policies)
            } catch {
                return .failure(error)
            }
        }
    }
    
    
    struct PoliciesDetailReply: Codable {
        
        let policyDetailed: PoliciesDetailed
        
        static func decode(_ data: Data) -> Result<PoliciesDetailed,Error> {
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(PoliciesDetailed.self, from: data)
                print("PoliciesDetailReply Decoding succeeded")
                return .success(response)
            } catch {
                print("PoliciesDetailReply Failed - Decoding errror")
                return .failure(error)
            }
        }
    }
    
    struct ScriptsReply: Codable {
        
        let scripts: [ScriptClassic]
        static func decode(_ data: Data) -> Result<[ScriptClassic],Error> {
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(ScriptsReply.self, from: data)
                print("ScriptsReply Decoding succeeded")
                return .success(response.scripts)
            } catch {
                return .failure(error)
            }
        }
    }
    
    
    
    
    //    #################################################################################
    //    Process functions
    //    #################################################################################
    
    
    func processPolicies(data: Data, response: URLResponse, resourceType: ResourceType) {
        
        separationLine()
        let decoded = PoliciesReply.decode(data)
        switch decoded {
        case .success(let policies):
            receivedPolicies(policies: policies)
            //            DEBUG
            //            print("Policies are:\(policies)")
            
        case .failure(let error):
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    func processComputer(data: Data, response: URLResponse, resourceType: String) {
        
        separationLine()
        let decoded = ComputersReply.decode(data)
        separationLine()
        
        //        DEBUG
        //        print("Unprocessed computers data is:")
        //        print(String(data: data, encoding: .utf8)!)
        //        print("Decoded is:\(decoded)")
        //        print("resourceType is:\(String(resourceType))")
        
        switch decoded {
        case .success(let computers):
            receivedComputers(computers: computers)
            
            //            DEBUG
            //            print("Computers are:\(computers)")
            
        case .failure(let error):
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    func processCategory(data: Data, response: URLResponse, resourceType: String) {
        
        let decoded = CategoryReply.decode(data)
        
        //         print("Processed: \(resourceType) data is:")
        //         print(String(data: data, encoding: .utf8)!)
        //         print("Decoded is:\(decoded)")
        //         print("resourceType is:\(String(resourceType))")
        
        switch decoded {
        case .success(let categories):
            print("Decoding success")
            receivedCategory(categories: categories)
            
        case .failure(let error):
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    
    func processComputersBasic(data: Data, response: URLResponse, resourceType: String) {
        
        separationLine()
        print("Running:processComputersBasic")
        
        //        DEBUG
        //        print("Unprocessed computersBasic data is:")
        //        print(data)
        //        print(String(data: data, encoding: .utf8)!)
        
        let decoded = ComputersBasicReply.decode(data)
        
        //        DEBUG
        //        separationLine()
        //        print("Processed computersBasic data is:")
        //        print(String(data: data, encoding: .utf8)!)
        //        print("Decoded computersBasic is:\(decoded)")
        //        print("resourceType is:\(String(resourceType))")
        //        separationLine()
        
        switch decoded {
        case .success(let computers):
            receivedComputersBasic(computers: computersBasic)
            
        case .failure(let error):
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    func processDepartment(data: Data, response: URLResponse, resourceType: String) {
        
        let decoded = DepartmentReply.decode(data)
        
        print("Running:processDepartment")
        //        DEBUG
        //        print("Processed: \(resourceType) data is:")
        //        print(String(data: data, encoding: .utf8)!)
        //        print("Decoded is:\(decoded)")
        //         print("resourceType is:\(String(resourceType))")
        
        switch decoded {
        case .success(let departments):
            print("Decoding success")
            receivedDepartment(departments: departments)
            //             print("resourceType: \(resourceType) is:\(scripts)")
            
        case .failure(let error):
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    
    func processScripts(data: Data, response: URLResponse, resourceType: String) {
        
        let decoded = ScriptsReply.decode(data)
        print("Running:processScripts")
        //        DEBUG
        //        print("Processed: \(resourceType) data is:")
        //        print(String(data: data, encoding: .utf8)!)
        //        print("Decoded is:\(decoded)")
        //        print("resourceType is:\(String(resourceType))")
        
        switch decoded {
        case .success(let scripts):
            print("Decoding success")
            receivedScripts(scripts: scripts)
            print("resourceType: is \(resourceType)")
            //            DEBUG
            //            print("Printing scripts:\(scripts)")
            
        case .failure(let error):
            print("Decoding failure")
            print("Response is:\(response)")
            print("Error is:\(error)")
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    func processPackages(data: Data, response: URLResponse, resourceType: String) {
        
        let decoded = PackagesReply.decode(data)
        
        switch decoded {
        case .success(let packages):
            print("Decoding packages success")
            receivedPackages(packages: packages)
            
        case .failure(let error):
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    //
    
    
    //    #################################################################################
    //    RECEIVED - funcs to send to main queue
    //    #################################################################################
    
    
    
    func receivedComputers(computers: [Computer]) {
        print("Running receivedComputers")
        DispatchQueue.main.async {
            self.computers = computers
            // self.status = "Computers retrieved"
            //        self.status = "Computers retrieved"
        }
    }
    
    func receivedComputersBasic(computers: [Computers.ComputerResponse]) {
        //        DEBUG
        print("Running ComputersBasic Received")
        //        print("ComputersBasic Received are:\(computers)")
        DispatchQueue.main.async {
            self.computersBasic = computers
            // self.status = "Computers retrieved"
            //        self.status = "ComputersBasic retrieved"
        }
    }
    
    func receivedDepartment(departments: [Department]) {
        DispatchQueue.main.async {
            self.departments = departments
            // self.status = "Computers retrieved"
            //        self.status = "Departments retrieved"
        }
    }
    
    func receivedPackages(packages: [Package]) {
        DispatchQueue.main.async {
            self.packages = packages
            // self.status = "Computers retrieved"
            //        self.status = "Packages retrieved"
        }
    }
    
    func receivedPolicies(policies: [Policy]) {
        DispatchQueue.main.async {
            self.policies = policies
            // self.status = "Computers retrieved"
            //        self.status = "Policies retrieved"
        }
    }
    
    func receivedScripts(scripts: [ScriptClassic]) {
        DispatchQueue.main.async {
            self.scripts = scripts
            // self.status = "Computers retrieved"
            //        self.status = "Scripts retrieved"
        }
    }
    
//    func receivedPolicyDetail(policyDetailed: PoliciesDetailed) {
//        DispatchQueue.main.async {
//            self.policyDetailed = policyDetailed
//            // self.status = "Computers retrieved"
//            //        self.status = ""
//            print("Adding:policyDetailed to: allPoliciesDetailed ")
//            self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
//
//        }
//    }
    
    
    
    
    
    
    
    
    
    
    
    func appendStatus(_ string: String) {
        doubleSeparationLine()
        print("Appending status")
        DispatchQueue.main.async { // need to modify status on the main queue
            self.status += string
            self.status = "Connected"
            self.status += "\n\n"
        }
    }
    
    
    //    #################################################################################
    //    SEPARATION LINES
    //    #################################################################################
    
    
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
    //    Various
    //    #################################################################################
    
    func debugSomething(dataThing: Any) {
        print("Printing out:\(dataThing)")
    }
    
    
    
    
    
    //    #################################################################################
    //    Delete - functions
    //    #################################################################################
    
    func deleteComputer(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running deleteComputer - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
            print("deleteComputer has finished")
            print("Set processingComplete to true")
            self.processingComplete = true
            print(String(describing: self.processingComplete))
        }
    }
    
    func deleteConfigProfile(server: String,authToken: String, resourceType: ResourceType, itemID: String) {
        
        let resourcePath = getURLFormat(data: (ResourceType.configProfileDetailedMacOS))
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running delete computer function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
            
            print("deleteComputer has finished")
            print("Set processingComplete to true")
            self.processingComplete = true
            print(String(describing: self.processingComplete))
        }
    }
    
    func deletePackage(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        
        print("Running deletePackage for item\(itemID)")
        let resourcePath = getURLFormat(data: (resourceType))
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running delete package function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            print("itemID is set as:\(itemID)")
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
        }
    }
    
    func deletePolicy(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running deletePolicy function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
//            appendStatus("Connecting to \(url)...")
            print("deletePolicy has finished for:\(itemID)")
            print("Set processingComplete to true")
            self.processingComplete = true
            print(String(describing: self.processingComplete))
        }
    }
    
    func deleteScript(server: String,resourceType: ResourceType, itemID: String, authToken: String) async throws {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running delete script function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            
            do {
                try await requestDeleteXML(url: url, authToken: authToken, resourceType: resourceType)
            } catch {
                throw JamfAPIError.badURL
            }
            
//            appendStatus("Connecting to \(url)...")
            
            print("deleteScript has finished")
        }
    }
    
    
    
    func deleteScriptAlt(server: String,resourceType: ResourceType, itemID: String, authToken: String) {
        
        print("Running deleteScriptAlt function - server is set as:\(server)")

        let resourcePath = getURLFormat(data: (resourceType))
        print("resourcePath is set as:\(resourcePath)")

        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running deleteScriptAlt function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            atSeparationLine()
            print("Running deleteScriptAlt function - resourceType is set as:\(resourceType)")
            
//            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            var request = URLRequest(url: url)

            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/xml", forHTTPHeaderField: "Accept")
            request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "DELETE"
            
            print("Request is:\(request)")
            
            let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
                  print("Running shared data task")
                        
                if let data = data, let response = response {
                    print("Data is:\(String(describing: String(data: data, encoding: .utf8) ?? "no data") )")
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("deleteScript Status code is:\(statusCode)")
                    
                } else {
                    print("No Response")
                }
            }
        }
    }
    
    func batchDeleteScripts(selection:  Set<ScriptClassic>, server: String, authToken: String, resourceType: ResourceType) {
        self.separationLine()
        print("Running: batchDeleteScripts")
        print("selection is: \(selection)")

        for eachItem in selection {
            self.separationLine()
//            print("Items as Dictionary is \(eachItem)")
            let scriptID = String(describing:eachItem.jamfId)
            print("Current scriptID is:\(scriptID)")
            print("Running: deleteScriptAlt")
            print("resourceType is: \(resourceType)")
            
            Task {
                try await self.deleteScript(server: server, resourceType: resourceType, itemID: scriptID, authToken: authToken )
            }
        }
        self.separationLine()
        print("Finished - batchDeleteScripts")
    }
    
    func batchDeleteAdvancedComputerSearch(selection: Set<AdvancedComputerSearch>, server: String, authToken: String) async throws {
        
        self.separationLine()
        print("Running: batchDeleteAdvancedComputerSearch")
        for eachItem in selection {
            self.separationLine()
            print("Items as Dictionary is \(eachItem)")
            let searchId = String(describing: eachItem.id)
            print("Current searchId is:\(searchId)")
            
            do {
                try await self.deleteAdvancedComputerSearch(server: server, resourceType: ResourceType.computerBasic, itemID: searchId, authToken: authToken)
            } catch {
                throw JamfAPIError.badURL
            }
        }
        self.separationLine()
        print("Finished - batchDeleteAdvancedComputerSearch")
    }
    
    func deleteAdvancedComputerSearch(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
        let resourcePath = "advancedcomputersearches"
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running deleteAdvancedComputerSearch function - url is set as:\(url)")
            var request = URLRequest(url: url, timeoutInterval: Double.infinity)
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/xml", forHTTPHeaderField: "Accept")
            request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "DELETE"
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("Code not 200")
                self.hasError = true
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                self.currentResponseCode = String(describing: statusCode)
                print("deleteAdvancedComputerSearch Status code is:\(statusCode)")
                throw JamfAPIError.http(statusCode)
            }
             print("deleteAdvancedComputerSearch has finished successfully")
         }
     }
     
     func batchDeleteGroup(selection: Set<ComputerGroup>, server: String, authToken: String, resourceType: ResourceType) async throws {
         
         self.separationLine()
         print("Running: batchDeleteGroup")
         for eachItem in selection {
             self.separationLine()
             print("Items as Dictionary is \(eachItem)")
             let groupId = String(describing: eachItem.id)
             print("Current groupId is:\(groupId)")
             
             do {
                 try await self.deleteComputerGroup(server: server, resourceType: resourceType, itemID: groupId, authToken: authToken)
             } catch {
                 throw JamfAPIError.badURL
             }
         }
         self.separationLine()
         print("Finished - batchDeleteGroup")
     }
     
     func deleteComputerGroup(server: String, resourceType: ResourceType, itemID: String, authToken: String) async throws {
         let resourcePath = "computergroups"
         if let serverURL = URL(string: server) {
             let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
             separationLine()
             print("Running deleteComputerGroup function - url is set as:\(url)")
             var request = URLRequest(url: url, timeoutInterval: Double.infinity)
             request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
             request.addValue("application/xml", forHTTPHeaderField: "Accept")
             request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
             request.httpMethod = "DELETE"
             let (data, response) = try await URLSession.shared.data(for: request)
             guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                 print("Code not 200")
                 self.hasError = true
                 let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                 self.currentResponseCode = String(describing: statusCode)
                 print("deleteComputerGroup Status code is:\(statusCode)")
                 throw JamfAPIError.http(statusCode)
             }
             print("deleteComputerGroup has finished successfully")
         }
     }
}
