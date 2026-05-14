
import Foundation
import SwiftUI
import AEXML

// ComputerHistory types are defined in Model/ModelDecodingStructs/ComputerHistory.swift
// Use those definitions to decode computer history responses.

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
    @Published var computerHistory: ComputerHistory? = nil
    // Raw JSON of the last computer history response (useful for debugging/preview in UI)
    @Published var lastComputerHistoryRaw: String? = nil
    
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
    
    @Published var advancedComputerSearches: [AdvancedComputerSearch] = []
    @Published var allAdvancedComputerSearches: [AdvancedComputerSearch] = []
    @Published var advancedComputerSearchDetailed: AdvancedComputerSearchDetailed? = nil

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
    // Configurable number of concurrent detail fetches for policies. Persisted to UserDefaults
    // under the key "policyFetchConcurrency" so the user can adjust it in preferences.
    @Published var policyFetchConcurrency: Int
    private var lastRequestDate: Date?
    // Buffer to coalesce fetched policy details before updating view-backed collections
    private var policyDetailsBuffer: [PolicyDetailed] = []
    private var isPolicyDetailsFlushScheduled: Bool = false
    private let policyDetailsFlushInterval: TimeInterval = 0.20 // 200ms

    init(minInterval: TimeInterval = 0.0) {
        // look for a persisted setting first
        let persisted = UserDefaults.standard.double(forKey: "policyRequestDelay")
        if persisted > 0 {
            self.policyRequestDelay = persisted
        } else {
            self.policyRequestDelay = minInterval
        }
        // load concurrency setting (default to 4)
        let persistedConcurrency = UserDefaults.standard.integer(forKey: "policyFetchConcurrency")
        self.policyFetchConcurrency = persistedConcurrency > 0 ? persistedConcurrency : 4
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

    // Setter and getter for concurrency setting exposed to preferences UI
    func setPolicyFetchConcurrency(_ count: Int) {
        guard count >= 1 else { return }
        self.policyFetchConcurrency = count
        UserDefaults.standard.set(count, forKey: "policyFetchConcurrency")
        separationLine()
        print("Policy fetch concurrency updated to \(count). Persisted to UserDefaults key 'policyFetchConcurrency'.")
    }

    func getPolicyFetchConcurrency() -> Int { self.policyFetchConcurrency }

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

    // Small helper to expose progress info to Views that expect
    // `networkController.detailedPoliciesProgress.expected/loaded/failedIDs`.
    struct DetailedPoliciesProgress {
        var expected: Int
        var loaded: Int
        var failedIDs: [String]
    }

    // Computed property so Views can read progress without needing to access
    // internal implementation details. This is intentionally synchronous and
    // lightweight.
    var detailedPoliciesProgress: DetailedPoliciesProgress {
        return DetailedPoliciesProgress(expected: allPoliciesConverted.count,
                                         loaded: allPoliciesDetailed.compactMap { $0 }.count,
                                         failedIDs: retryFailedDetailedPolicyCalls)
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
        
        // Decode JSON off the main actor to avoid doing heavy work during a UI layout pass
        // Add extra debug logging on failure to help diagnose date/formatting issues.
        let decoded: ComputerBasic = try await Task.detached(priority: .userInitiated) {
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(ComputerBasic.self, from: data)
            } catch let decodingError as DecodingError {
                // Capture raw body for diagnostics
                let body = String(data: data, encoding: .utf8) ?? "<binary>"
                print("--- Decoding error in getComputersBasic ---")
                print("DecodingError: \(decodingError)")
                print("Response body (truncated 2000 chars):\n\(body.prefix(2000))")

                // Print specific DecodingError details
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type: \(type) at codingPath: \(context.codingPath) — \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type: \(type) at codingPath: \(context.codingPath) — \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key) at codingPath: \(context.codingPath) — \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted at codingPath: \(context.codingPath) — \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
                throw decodingError
            } catch {
                // Non-decoding errors
                let body = String(data: data, encoding: .utf8) ?? "<binary>"
                print("Unexpected error decoding ComputerBasic: \(error)\nBody:\n\(body.prefix(2000))")
                throw error
            }
        }.value

        // Assign published properties asynchronously on the main queue to ensure
        // we don't mutate view-backed collections during an active layout pass.
        DispatchQueue.main.async {
            self.allComputersBasic = decoded
            self.allComputersBasicDict = decoded.computers
            self.initialDataLoaded = true
        }
        
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
    
    func getAdvancedComputerSearch(_ userID: String) async throws {
        let jamfURLQuery = server + "/JSSResource/advancedcomputersearches"
        guard let url = URL(string: jamfURLQuery) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        
        separationLine()
        print("Running func: getAdvancedComputerSearch")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
                    print(String(data: data, encoding: .utf8)!)

            throw JamfAPIError.badResponseCode
        }
print("DEBUG - status code is 200, response is:")
        print(String(data: data, encoding: .utf8)!)

        
        let decoder = JSONDecoder()
        let searchesResponse = try decoder.decode(ComputerSearches.self, from: data)
        
        await MainActor.run {
            self.advancedComputerSearches = searchesResponse.advancedComputerSearches.advancedComputerSearch
            self.allAdvancedComputerSearches = searchesResponse.advancedComputerSearches.advancedComputerSearch
        }
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
        

//        if self.debug_enabled == true {
            separationLine()
            print("getDetailedPolicy has run - policy name is:\(self.policyDetailed?.general?.name ?? "")")
//        print("Policy Trigger:\t\t\t\(self.policyDetailed?.general?.triggerOther ?? "")\n")

//        }
        self.policyDetailed = decodedData

        // Buffer the fetched detail and schedule a coalesced flush to update the
        // view-backed collection. This avoids frequent mutations during layout.
        self.policyDetailsBuffer.append(decodedData)
        self.scheduleFlushPolicyDetails()
      
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

        // Use user-configured concurrency (persisted setting). Default to 4 if invalid.
        let concurrency = max(1, self.policyFetchConcurrency)

        var failedCalls: [String] = []

        // Use an AsyncSemaphore to bound concurrent requests and a single TaskGroup to manage
        // all the asynchronous fetch tasks. This approach ensures that increasing
        // `policyFetchConcurrency` will allow more simultaneous requests.
        let semaphore = AsyncSemaphore(value: concurrency)

        await withTaskGroup(of: (String, Result<PolicyDetailed, Error>).self) { group in
            for policy in validPolicies {
                let serverCopy = server
                let tokenCopy = validToken
                let policyID = String(describing: policy.jamfId ?? 0)
                let userAgent = "\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))"

                group.addTask {
                    // Limit concurrency
                    await semaphore.wait()
                    defer { Task { await semaphore.signal() } }

                    // Respect global rate limiting via MainActor-coordinated timestamp
                    let now = Date()
                    let delayNeeded: TimeInterval = await MainActor.run { () -> TimeInterval in
                        if let last = self.lastRequestDate {
                            let elapsed = now.timeIntervalSince(last)
                            return elapsed < self.policyRequestDelay ? (self.policyRequestDelay - elapsed) : 0
                        }
                        return 0
                    }

                    if delayNeeded > 0 {
                        let human = await MainActor.run { self.formatDuration(delayNeeded) }
                        let nextRunAt = Date().addingTimeInterval(delayNeeded)
                        print("Throttling: sleeping for \(delayNeeded) seconds (\(human)) before requesting policy \(policyID). Next at: \(nextRunAt)")
                        await MainActor.run { self.policyDelayStatus = "Delaying policy fetch: \(human) (next at \(nextRunAt))" }
                        try? await Task.sleep(nanoseconds: UInt64(delayNeeded * 1_000_000_000))
                    }

                    // Claim the timestamp before issuing the request so other tasks see it
                    await MainActor.run { self.lastRequestDate = Date() }

                    // Build URL and request locally (avoid MainActor-bound helpers)
                    let jamfURLQuery = serverCopy + "/JSSResource/policies/id/" + policyID
                    guard let url = URL(string: jamfURLQuery) else {
                        return (policyID, .failure(JamfAPIError.badURL))
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("Bearer \(tokenCopy)", forHTTPHeaderField: "Authorization")
                    request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                    request.setValue("application/json", forHTTPHeaderField: "Accept")

                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                        guard status == 200 else {
                            return (policyID, .failure(JamfAPIError.http(status)))
                        }
                        let decoder = JSONDecoder()
                        let detailed = try decoder.decode(PoliciesDetailed.self, from: data).policy
                        return (policyID, .success(detailed))
                    } catch {
                        return (policyID, .failure(error))
                    }
                }
            }

            // Collect results as they complete; buffer successes to minimize UI layout churn
            var successes: [PolicyDetailed] = []
            for await (policyID, result) in group {
                switch result {
                case .success(let detailed):
                    successes.append(detailed)
                    print("Fetched policy detail for ID: \(policyID)")
                case .failure(let err):
                    print("Error fetching detailed policy ID \(policyID): \(err)")
                    failedCalls.append(policyID)
                }
            }

            // Insert buffered successes in one MainActor update to reduce layout thrash
            if !successes.isEmpty {
                // Append buffered successes to the coalescing buffer and schedule a flush
                await MainActor.run {
                    self.policyDetailsBuffer.append(contentsOf: successes)
                    self.scheduleFlushPolicyDetails()
                }
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

    // Schedule a flush of buffered policy details to the published array. This
    // coalesces multiple incoming items and flushes them at most once per
    // `policyDetailsFlushInterval` to avoid layout thrash.
    private func scheduleFlushPolicyDetails() {
        guard !isPolicyDetailsFlushScheduled else { return }
        isPolicyDetailsFlushScheduled = true
        let interval = policyDetailsFlushInterval
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            Task { [weak self] in
                // flushPolicyDetails is @MainActor synchronous; call it directly
                self?.flushPolicyDetails()
            }
        }
    }

    // Flush buffered policy details into `allPoliciesDetailed` in a single
    // atomic update on the main thread.
    @MainActor
    private func flushPolicyDetails() {
        guard !policyDetailsBuffer.isEmpty else { isPolicyDetailsFlushScheduled = false; return }
        // Prepend buffered items while preserving order
        let toInsertOptional = policyDetailsBuffer.map { Optional($0) }
        var newArray: [PolicyDetailed?] = []
        newArray.append(contentsOf: toInsertOptional.reversed())
        newArray.append(contentsOf: self.allPoliciesDetailed)
        self.allPoliciesDetailed = newArray
        // Clear the buffer and reset the scheduled flag
        self.policyDetailsBuffer.removeAll()
        isPolicyDetailsFlushScheduled = false
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
                    // Avoid inserting duplicates: check by jamfId
                    if !packagesAssignedToPolicy.contains(where: { $0.jamfId == package.jamfId }) {
                        packagesAssignedToPolicy.insert(package, at: 0)
                    } else {
                        print("Skipping duplicate package with jamfId: \(package.jamfId)")
                    }
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
            // Keep the converted/basic policies array in sync so UI bindings
            // that observe `allPoliciesConverted` update immediately when the
            // legacy request pipeline returns. This ensures the counts shown in
            // views update in real-time rather than waiting for other fetches.
            self.allPoliciesConverted = policies
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
    
    // Helper: build a well-formed JSSResource URL for a resourcePath and optional itemID.
    // This appends path components safely (avoids double-slashes and preserves escaping).
    private func buildJSSResourceURL(server: String, resourcePath: String, itemID: String? = nil, useAPI: Bool = false) -> URL? {
        // Start from server as URL
        guard var baseURL = URL(string: server) else { return nil }

        // If server URL already contains JSSResource/API/V1, don't add the prefix
        let serverPathLower = baseURL.path.lowercased()
        let needsPrefix = !(serverPathLower.contains("jssresource") || serverPathLower.contains("/api") || serverPathLower.contains("/v1"))

        if needsPrefix {
            baseURL.appendPathComponent(useAPI ? "api" : "JSSResource")
        }

        // Trim leading/trailing slashes from resourcePath then append components
        var trimmed = resourcePath
        if trimmed.hasPrefix("/") { trimmed.removeFirst() }
        if trimmed.hasSuffix("/") { trimmed.removeLast() }

        let components = trimmed.split(separator: "/").map { String($0) }
        for comp in components where !comp.isEmpty {
            baseURL.appendPathComponent(comp)
        }

        // Optionally append the itemID as a final component
        if let id = itemID, !id.isEmpty {
            baseURL.appendPathComponent(id)
        }

        return baseURL
    }
    
    func deleteComputer(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        // Deleting an individual computer requires the "computers/id/<id>" path.
        // Accept callers passing .computer or .computerBasic for convenience and map
        // them to the detailed resource path used for single-item operations.
        let effectiveResourceType: ResourceType = {
            if resourceType == .computer || resourceType == .computerBasic {
                return .computerDetailed
            }
            return resourceType
        }()

        // Use the effective resource type so callers can request the correct URL format
        let resourcePath = getURLFormat(data: effectiveResourceType)

        if let url = buildJSSResourceURL(server: server, resourcePath: resourcePath, itemID: itemID) {
            separationLine()
            print("Running deleteComputer - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")

            // Mark processing as in-progress and kick off the delete. The completion handler
            // in requestDelete will clear processingComplete when the network call finishes.
            self.processingComplete = false
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
            print("deleteComputer request started (async)")
        } else {
            print("deleteComputer: failed to build URL for resourcePath=\(resourcePath) itemID=\(itemID)")
        }
    }
    
    func deleteConfigProfile(server: String,authToken: String, resourceType: ResourceType, itemID: String) {
        let resourcePath = getURLFormat(data: (ResourceType.configProfileDetailedMacOS))
        if let url = buildJSSResourceURL(server: server, resourcePath: resourcePath, itemID: itemID) {
            separationLine()
            print("Running delete config profile - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            self.processingComplete = false
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
        } else {
            print("deleteConfigProfile: failed to build URL")
        }
    }
    
    func deletePackage(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        
        print("Running deletePackage for item\(itemID)")
        let resourcePath = getURLFormat(data: (ResourceType.package))
        
        if let url = buildJSSResourceURL(server: server, resourcePath: resourcePath, itemID: itemID) {
            separationLine()
            print("Running delete package function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            print("itemID is set as:\(itemID)")
            self.processingComplete = false
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
        } else {
            print("deletePackage: failed to build URL")
        }
    }
    
    func deletePolicy(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        // Use the provided resourceType to build the correct single-item URL path
        // callers commonly pass ResourceType.policies which maps to "policies/id/".
        let resourcePath = getURLFormat(data: resourceType)
        if let url = buildJSSResourceURL(server: server, resourcePath: resourcePath, itemID: itemID) {
            separationLine()
            print("Running deletePolicy function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            self.processingComplete = false
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            print("deletePolicy request started for:\(itemID)")
        } else {
            print("deletePolicy: failed to build URL")
        }
    }
    
    func deleteScript(server: String,resourceType: ResourceType, itemID: String, authToken: String) async throws {
        let resourcePath = getURLFormat(data: (ResourceType.script))

        if let url = buildJSSResourceURL(server: server, resourcePath: resourcePath, itemID: itemID, useAPI: true) {
            separationLine()
            print("Running delete script function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")

            do {
                try await requestDeleteXML(url: url, authToken: authToken, resourceType: resourceType)
            } catch {
                throw JamfAPIError.badURL
            }

            print("deleteScript has finished")
        } else {
            print("deleteScript: failed to build URL for resourcePath=\(resourcePath) itemID=\(itemID)")
        }
    }
    
    
    
//    func deleteScriptAlt(server: String,resourceType: ResourceType, itemID: String, authToken: String) {
//
//        print("Running deleteScriptAlt function - server is set as:\(server)")
//
//        let resourcePath = getURLFormat(data: (resourceType))
//        print("resourcePath is set as:\(resourcePath)")
//
//        if let serverURL = URL(string: server) {
//            let url = serverURL.appendingPathComponent("api").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
//            separationLine()
//            print("Running deleteScriptAlt function - url is set as:\(url)")
//            print("resourceType is set as:\(resourceType)")
//            atSeparationLine()
//            print("Running deleteScriptAlt function - resourceType is set as:\(resourceType)")
//
////            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
//            var request = URLRequest(url: url)
//
//            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//            request.setValue("application/xml", forHTTPHeaderField: "Accept")
//            request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
//            request.httpMethod = "DELETE"
//
//            print("Request is:\(request)")
//
//            let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
//                  print("Running shared data task")
//
//                if let data = data, let response = response {
//                    print("Data is:\(String(describing: String(data: data, encoding: .utf8) ?? "no data") )")
//                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
//                    print("deleteScript Status code is:\(statusCode)")
//
//                } else {
//                    print("No Response")
//                }
//            }
//        }
//    }
    
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
                try await self.deleteScript(server: server, resourceType: ResourceType.script, itemID: scriptID, authToken: authToken )
            }
        }
        self.separationLine()
        print("Finished - batchDeleteScripts")
    }
    
    func deleteGroup(server: String,resourceType: ResourceType, itemID: String, authToken: String)  async throws {
        let resourcePath = getURLFormat(data: (ResourceType.computerGroup))
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running deleteGroup function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            var request = URLRequest(url: url,timeoutInterval: Double.infinity)
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
                print("deleteGroup Status code is:\(statusCode)")
                throw JamfAPIError.http(statusCode)
            }
            print("deleteGroup has finished successfully")
        }
    }

    // Helper to remove HTML tags for better user messages
    private func stripHTML(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                   .replacingOccurrences(of: "&nbsp;", with: " ")
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Delete a user by Jamf ID using the Classic API (JSSResource/users/id/<id>)
    func deleteUser(server: String, resourceType: ResourceType = .account, itemID: String, authToken: String) async throws {
        let resourcePath = "users/id"
        guard let serverURL = URL(string: server) else {
            throw JamfAPIError.badURL
        }

        let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
        separationLine()
        print("Running deleteUser function - url is set as:\(url)")
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"

        // Diagnostic: print request method and masked headers (do not log full auth token)
        var printableHeaders: [String: String] = [:]
        for (k, v) in request.allHTTPHeaderFields ?? [:] {
            if k.lowercased() == "authorization" {
                // Mask token leaving last 4 chars if present
                let parts = v.split(separator: " ")
                if parts.count > 1 {
                    let scheme = String(parts[0])
                    let token = String(parts[1])
                    let masked: String
                    if token.count > 6 {
                        let visible = token.suffix(4)
                        masked = String(repeating: "*", count: max(0, token.count - 4)) + visible
                    } else {
                        masked = String(repeating: "*", count: token.count)
                    }
                    printableHeaders[k] = "\(scheme) \(masked)"
                } else {
                    printableHeaders[k] = "****"
                }
            } else {
                printableHeaders[k] = v
            }
        }
        print("Request method: \(request.httpMethod ?? "")")
        print("Request headers: \(printableHeaders)")

        // Perform request and capture body + response for diagnostics
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        // Accept 200 or 204 as successful delete responses (some Jamf endpoints return 204)
        guard statusCode == 200 || statusCode == 204 else {
            print("deleteUser Status code is:\(statusCode)")
            self.hasError = true
            self.currentResponseCode = String(describing: statusCode)

            // Try to print response body (UTF-8), else show length
            var bodyString: String = ""
            if data.count > 0 {
                if let s = String(data: data, encoding: .utf8) {
                    bodyString = s
                    print("Response body:\n\(s)")
                } else {
                    print("Response body: <non-UTF8> (length: \(data.count) bytes)")
                }
            } else {
                print("Response body: <empty>")
            }

            if let httpResp = response as? HTTPURLResponse {
                print("Response headers: \(httpResp.allHeaderFields)")
            }

            // If server returned a 400 (Bad Request) with explanatory HTML, try to extract a friendly message
            if statusCode == 400 {
                var friendlyMessage = "The server rejected the delete request (400)."
                if !bodyString.isEmpty {
                    let stripped = stripHTML(bodyString)
                    // Attempt to extract dependency items like "Computer:Macbook 03" into a structured array
                    var details: [String] = []
                    if let regex = try? NSRegularExpression(pattern: "(Computer|Device|Policy|Package|User):\\s*([^\\n\\r<>]+)", options: .caseInsensitive) {
                        let ns = NSString(string: stripped)
                        let matches = regex.matches(in: stripped, options: [], range: NSRange(location: 0, length: ns.length))
                        for m in matches {
                            if m.numberOfRanges >= 3 {
                                let type = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                                let name = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                                details.append("\(type): \(name)")
                            }
                        }
                    }
                    if !details.isEmpty {
                        // publish structured details for UI
                        DispatchQueue.main.async {
                            self.lastErrorDetails = details
                        }
                    } else {
                        DispatchQueue.main.async { self.lastErrorDetails = [] }
                    }
                     // Look for a line mentioning 'dependent' or a clear reason
                     let lines = stripped.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                     if let depLine = lines.first(where: { $0.localizedCaseInsensitiveContains("dependent") || $0.localizedCaseInsensitiveContains("dependent on this") }) {
                         friendlyMessage = depLine
                     } else if let br = lines.first(where: { $0.localizedCaseInsensitiveContains("bad request") || $0.localizedCaseInsensitiveContains("error") }) {
                         friendlyMessage = br
                     } else {
                         // fallback to a short excerpt of the stripped body
                         friendlyMessage = lines.prefix(3).joined(separator: " ")
                     }
                 }

                 // Publish an explicit user-facing error so UI can show a helpful alert
                 publishError(NSError(domain: "JamfAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: friendlyMessage]), title: "Cannot delete user")
             } else {
                // Generic publish for other error codes: fallback to showing status code / body
                let display = (bodyString.isEmpty ? "HTTP \(statusCode)" : stripHTML(bodyString))
                publishError(NSError(domain: "JamfAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: display]), title: "Failed to delete user")
            }

            throw JamfAPIError.http(statusCode)
        }

        print("deleteUser has finished successfully (status \(statusCode))")
    }
    

    
    //    #################################################################################
    //    Tokens and Authorisation
    //    #################################################################################
    
    func getToken(server: String, username: String, password: String) async throws -> JamfAuthToken {
        
        print("Getting token - Netbrain")
        guard let base64 = encodeBase64(username: username, password: password) else {
            print("Error encoding username/password")
            throw JamfAPIError.couldntEncodeNamePass
        }
        
        guard var components = URLComponents(string: server) else {
            throw JamfAPIError.badURL
        }
        components.path="/api/v1/auth/token"
        guard let url = components.url else {
            throw JamfAPIError.badURL
        }
        
        // create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // send request and get data
        if debug_enabled {
            separationLine()
            print("[DEBUG] Token request URL: \(url.absoluteString)")
            print("[DEBUG] Token request Authorization header (first 16 chars): \(String(base64.prefix(16)))...")
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            if debug_enabled { print("[DEBUG] Token request failed: no response/data") }
            throw JamfAPIError.requestFailed
        }
        
        // check the response code
        self.tokenStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        if self.tokenStatusCode != 200 {
            if debug_enabled {
                let body = String(data: data, encoding: .utf8) ?? "<non-text response>"
                print("[DEBUG] Token response status: \(self.tokenStatusCode)")
                print("[DEBUG] Token response body: \(body)")
            }
            
            //            self.currentResponseCode = authStatusCode
            
            switch self.tokenStatusCode {
                
            case 400:
                print("Bad Request")
                self.showAlert = true
                self.alertMessage = "Bad Request"
                throw JamfAPIError.badRequest
                
            case 401:
                print("Authentication Failed")
                self.showAlert = true
                self.alertMessage = "Authentication Failed"
                throw JamfAPIError.http(self.tokenStatusCode)
                
            case 403:
                print("Access Forbidden")
                self.showAlert = true
                self.alertMessage = "Access Denied"
                
                throw JamfAPIError.forbidden
                
            case 404:
                print("Url not Found")
                self.showAlert = true
                self.alertMessage = "URL Address unknown"
                throw JamfAPIError.badURL
                
            case 409:
                print("Conflict - possible multiple requests")
                self.showAlert = true
                self.status = "Conflict - possible multiple requests"
                throw JamfAPIError.conflict
                
            default:
                print("Unknown error")
                self.showAlert = true
                self.status = "Unknown error:"
                throw JamfAPIError.http(self.tokenStatusCode)
            }
          
        } else {
            if debug_enabled {
                let body = String(data: data, encoding: .utf8) ?? "<non-text response>"
                print("[DEBUG] Token response status: 200")
                print("[DEBUG] Token response body: \(body)")
            }
            print("Authentication success")
            self.status = "Connected"
        }
        
        // MARK: Parse JSON returned
        let decoder = JSONDecoder()
        
        guard let auth = try? decoder.decode(JamfAuthToken.self, from: data)
        else {
            throw JamfAPIError.decode
        }
        
        print("We have a token")
        self.status = "Connected"
        // Persist the received token and mark the controller as connected so
        // callers that invoke `getToken` directly (e.g. the ConnectSheet) don't
        // need to call `connect()` separately.
        self.auth = auth
        self.authToken = auth.token
        self.connected = true
        self.needsCredentials = false
        // Store expiration time and credentials for refresh
        self.tokenExpirationTime = Date().addingTimeInterval(1200) // 20 minutes
        self.refreshUsername = username
        self.refreshPassword = password
        return auth
    }
    
    // MARK: - Token Management
    
    /// Check if current token is valid or needs refresh
    func isTokenValid() -> Bool {
        guard let expirationTime = tokenExpirationTime else { return false }
        // Add 2-minute buffer before expiration
        return Date() < expirationTime.addingTimeInterval(-120)
    }
    
    /// Refresh token if needed, otherwise return current valid token
    func getValidToken(server: String) async throws -> String {
        if !isTokenValid() {
            print("Token expired or invalid, refreshing...")
            try await refreshToken(server: server)
        }
        return authToken
    }

    /// Refresh the authentication token
    private func refreshToken(server: String) async throws {
        guard !refreshUsername.isEmpty && !refreshPassword.isEmpty else {
            print("Cannot refresh token: missing credentials")
            throw JamfAPIError.requestFailed
        }

        let newAuth = try await getToken(server: server, username: refreshUsername, password: refreshPassword)
        self.authToken = newAuth.token
        self.tokenExpirationTime = Date().addingTimeInterval(1200) // 20 minutes
        print("Token refreshed successfully")
    }

    /// Wrapper for API calls that ensures valid token
    func withValidToken<T>(server: String, operation: (String) async throws -> T) async throws -> T {
        let validToken = try await getValidToken(server: server)
        return try await operation(validToken)
    }

    // ------------------------------------------------------------------
    // Concurrency-safe helper to ensure a valid token using stored server
    // and stored refresh credentials. This serializes refresh attempts so
    // multiple callers awaiting a refresh will wait for the same task.
    // ------------------------------------------------------------------
    private var tokenRefreshTask: Task<Void, Error>? = nil

    /// Ensure the current auth token is valid. If expired, attempt a refresh
    /// using cached credentials. Concurrent callers will await the same
    /// refresh task so only one refresh executes at a time.
    func ensureValidToken() async throws {
        // Fast-path: still valid
        if isTokenValid() { return }

        // If a refresh is already in-flight, await it
        if let existing = tokenRefreshTask {
            try await existing.value
            // Another task may have refreshed successfully
            if isTokenValid() { return }
            // Otherwise fall through to start a new attempt
        }

        // Ensure we have credentials available to refresh
        guard !refreshUsername.isEmpty && !refreshPassword.isEmpty else {
            print("ensureValidToken: missing stored credentials, cannot refresh")
            throw JamfAPIError.requestFailed
        }

        // Start a single refresh task that others can await
        let task = Task { () throws -> Void in
            try await self.refreshToken(server: self.server)
        }
        tokenRefreshTask = task

        do {
            try await task.value
        } catch {
            // Clear the task so future calls can try again
            tokenRefreshTask = nil
            throw error
        }

        // Completed successfully
        tokenRefreshTask = nil
    }
    
    // This function generates the base64 from a username name and password
    func encodeBase64(username: String, password: String) -> String? {
        let authString = username + ":" + password
        let encoded = authString.data(using: .utf8)?.base64EncodedString()
        return encoded
    }
    
//    static func get(server: String, username: String, password: String) async throws -> JamfAuthToken {
//
//      // MARK: Prepare Request
//      // encode username name and password
//      let base64 = "\(username):\(password)"
//        .data(using: String.Encoding.utf8)!
//        .base64EncodedString()
//
//      // assemble the URL for the Jamf API
//      guard var components = URLComponents(string: server) else {
//        throw JamfAPIError.badURL
//      }
//      components.path="/api/v1/auth/token"
//      guard let url = components.url else {
//        throw JamfAPIError.badURL
//      }
//
//      // MARK: Send Request and get Data
//
//      // create the request
//      var authRequest = URLRequest(url: url)
//      authRequest.httpMethod = "POST"
//      authRequest.addValue("Basic " + base64, forHTTPHeaderField: "Authorization")
//
//      // send request and get data
//      guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
//      else {
//        throw JamfAPIError.requestFailed
//      }
//
//      // MARK: Handle Errors
//
//      // check the response code
//      let authStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
//      if authStatusCode != 200 {
//        throw JamfAPIError.http(authStatusCode)
//      }
//
//      // print(String(data: data, encoding: .utf8) ?? "no data")
//
//      // MARK: Parse JSON returned
//      let decoder = JSONDecoder()
//
//      guard let auth = try? decoder.decode(JamfAuthToken.self, from: data)
//      else {
//        throw JamfAPIError.decode
//      }
//
//      return auth
//    }
//
    
    //    #################################################################################
    //    Connect functions and handleConnect function
    //    #################################################################################
    
    func connect(server: String, resourceType: ResourceType, authToken: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath)
            print("Running connect function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            request(url: url, resourceType: resourceType, authToken: authToken)
            appendStatus("Connecting to \(url)...")
        }
    }
    
    
    
    func handleConnect(server: String, authToken: String,resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        self.connect(server: server,resourceType: resourceType, authToken: authToken)
    }
    
    
    //    #################################################################################
    //    BATCH PROCESSING
    //    #################################################################################
    
    
    
    func batchDeleteGroup(selection:  Set<ComputerGroup>, server: String, authToken: String, resourceType: ResourceType) async throws {
        
        self.separationLine()
        print("Running: batchDeleteGroup")
        for eachItem in selection {
            self.separationLine()
            print("Items as Dictionary is \(eachItem)")
            let computerSmartGroupId = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.id)
            print("Current computerSmartGroupId is:\(computerSmartGroupId)")
            print("Current jamfID is:\(String(describing: jamfID))")
            
            do {
               try await self.deleteGroup(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken )
            } catch {
                throw JamfAPIError.badURL
            }
        }
        self.separationLine()
        print("Finished - Set processingComplete to true")

    }
    
    
    func addExistingPackages() {

        if let detailed = self.policyDetailed {
            if let policyPackages = detailed.package_configuration?.packages {
                self.separationLine()
                print("Adding currently assigned packages to packagesAssignedToPolicy:")
                for package in policyPackages {
                    self.separationLine()
                    print("Package is:\(package)")
                    // Avoid inserting duplicates: check by jamfId
                    if !packagesAssignedToPolicy.contains(where: { $0.jamfId == package.jamfId }) {
                        packagesAssignedToPolicy.insert(package, at: 0)
                    } else {
                        print("Skipping duplicate package with jamfId: \(package.jamfId)")
                    }
                }
            }
        } else {
            self.separationLine()
            print("No addExistingPackages response yet")
        }
    }
    
    func batchDeleteAdvancedComputerSearch(selection: Set<AdvancedComputerSearch>, server: String, authToken: String, resourceType: ResourceType) async throws {
        for eachItem in selection {
            let jamfID: String = String(eachItem.id)
            let jamfURLQuery = server + "/JSSResource/advancedcomputersearches/id/" + jamfID
            guard let url = URL(string: jamfURLQuery) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("Delete failed for advanced computer search \(jamfID)")
                throw JamfAPIError.badResponseCode
            }
            
            await MainActor.run {
                self.allAdvancedComputerSearches.removeAll { $0.id == eachItem.id }
            }
        }
    }
    
    
    
    //    #################################################################################
    //    batchScopeAllComputers
    //    #################################################################################
    
    
    func batchScopeAllComputers(policiesSelection: Set<Policy>, server: String, authToken: String) {
        self.separationLine()
        print("Running: batchScopeAllComputers")
        for eachItem in policiesSelection {
            self.separationLine()
            let jamfID: Int = eachItem.jamfId ?? 0
            print("Current jamfID is:\(String(describing: jamfID))")
            self.scopeAllComputers(server: server, authToken: authToken, policyID: String(describing: jamfID) )
        }
    }
    
    //    #################################################################################
    //    batchScopeAllUsers
    //    #################################################################################
    
    
    func batchScopeAllUsers(policiesSelection: Set<Policy>, server: String, authToken: String) {
        self.separationLine()
        print("Running: batchScopeAllComputers")
        for eachItem in policiesSelection {
            self.separationLine()
            let jamfID: Int = eachItem.jamfId ?? 0
            print("Current jamfID is:\(String(describing: jamfID))")
            self.scopeAllUsers(server: server, authToken: authToken, policyID: String(describing: jamfID) )
        }
    }
    
    
    
    func getBuildings(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/buildings"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        self.separationLine()
        print("Running func: getBuildings")
        print("url is set to:\(url)")
        let (data, response) = try await URLSession.shared.data(for: request)
        //        print("Json data is:")
        //        print(String(data: data, encoding: .utf8)!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        let allBuildings = try decoder.decode(Buildings.self, from: data)
        self.buildings = allBuildings.buildings
        //        print("buildings is set to:\(self.buildings)")
    }
    
    
    
    func getPackages(server: String) async throws {
        let jamfURLQuery = server + "/JSSResource/packages"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getPackages")
        
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
    
    func getAllScriptsOld(server: String, authToken: String) async throws {
        
        print("Running func: getAllScripts")
        
        let jamfURLQuery = server + "/api/v1/scripts?page=0&page-size=500"
        
        let url = URL(string: jamfURLQuery)!
        print("url is set to:\(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getAllScripts")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        separationLine()
        //        print("Json data is:")
        //                  print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        //        let allScriptResults = try decoder.decode(ScriptResults.self, from: data)
        //        let localScriptsDetailed = allScriptResults.results
        
        //        print("localScriptsDetailed status is set to:\(localScriptsDetailed)")
        //        let allScriptsFullyDetailed = self.allScriptsVeryDetailed.results
        
    }
    
    func getDetailedScript(server: String, scriptID: Int, authToken: String) async throws {
        
        separationLine()
        print("Running func: getDetailedScript")
        print("scriptID is set to:\(scriptID)")
        
        let jamfURLQuery = server + "/api/v1/scripts/" + String(describing: scriptID)
        self.currentURL = jamfURLQuery
        let url = URL(string: jamfURLQuery)!
        print("url is set to:\(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }

        let decoder = JSONDecoder()
        scriptDetailed = try decoder.decode(Script.self, from: data)
        //        print("scriptDetailed is set to:\(scriptDetailed)")
    }
    
    
  
func updateScript(server: String, scriptName: String, scriptContent: String, scriptId: String, authToken: String,category: String,filename: String,info: String, notes: String) async throws {

    // Helper: escape XML reserved characters for element content
    func escapeXML(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\'", with: "&apos;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        return out
    }

    // Ensure any occurrence of the CDATA terminator inside the script is safely handled
    let safeScriptContent = scriptContent.replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>")

    let xml = """
    <?xml version="1.0" encoding="utf-8"?>
    <script>
        <name>
        \(escapeXML(scriptName))
        </name>
        <category>\(escapeXML(category.isEmpty ? "No category assigned" : category))</category>
        <filename>\(escapeXML(filename))</filename>
        <info>\(escapeXML(info))</info>
        <notes>\(escapeXML(notes))</notes>
        <script_contents><![CDATA[\(safeScriptContent)]]></script_contents>
    </script>
    """

    separationLine()
    print("Running func: updateScript")
    print("scriptName is set to:\(scriptName)")
    print("scriptID is set to:\(scriptId)")

    let jamfURLQuery = server + "/JSSResource/scripts/id/" + String(describing: scriptId)
    self.currentURL = jamfURLQuery
    guard let url = URL(string: jamfURLQuery) else {
        print("Invalid URL for updateScript: \(jamfURLQuery)")
        throw JamfAPIError.badURL
    }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    request.addValue("application/xml", forHTTPHeaderField: "Accept")
    request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
    // Provide a helpful User-Agent (matches other requests)
    request.addValue("\(String(describing: product_name ?? "Man1fest0"))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
    request.httpMethod = "PUT"
    request.httpBody = xml.data(using: .utf8)

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        self.separationLine()
        print("updateScript response status: \(status)")
        if status == 200 || status == 201 {
            print("updateScript succeeded for id: \(scriptId)")
            // Optionally refresh the detailed script cache
            Task {
                try? await self.getDetailedScript(server: server, scriptID: Int(scriptId) ?? 0, authToken: authToken)
            }
            return
        } else {
            // Try to show the server response for debugging
            if let body = String(data: data, encoding: .utf8) {
                print("updateScript failed - response body:\n\(body)")
            } else {
                print("updateScript failed - no response body available")
            }
            print("updateScript failed - HTTP status: \(status)")
            throw JamfAPIError.http(status)
        }
    } catch let urlError as URLError {
        print("updateScript network request failed: \(urlError)")
        throw JamfAPIError.requestFailed
    } catch {
        print("updateScript unexpected error: \(error)")
        throw JamfAPIError.unknown
    }
}
    
    
    
    
    
    
    func getAllPolicies(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/policies"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
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
//        self.allPolicies = try decoder.decode(PolicyBasic.self, from: data)
        let decodedData = try decoder.decode(PolicyBasic.self, from: data).policies
//        self.allPoliciesConverted = decodedData
        // Populate both the legacy `policies` array and the `allPoliciesConverted` used by views
        self.policies = decodedData
        self.allPoliciesConverted = decodedData
        allPoliciesComplete = true
        separationLine()
        //        atSeparationLine()
        print("getAllPolicies status is set to:\(allPoliciesComplete)")
        print("allPolicies status code is:\(String(describing: self.allPoliciesStatusCode))")
        print("allPoliciesConverted count is:\(String(describing: self.allPoliciesConverted.count))")
    }
    
     
    
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
////        separationLine()
////        print("Raw data is:")
////        print(String(data: data, encoding: .utf8)!)
////        ########################################################
////        DEBUG
////        ########################################################
//
//        let decoder = JSONDecoder()
//        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
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
//            print("Last request ran at:\(String(describing: last))")
//            let elapsed = now.timeIntervalSince(last)
//            if elapsed < minInterval {
//                let delay = minInterval - elapsed
//                print("Waiting:\(String(describing: delay))")
//                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
//            }
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
////        separationLine()
////        print("Raw data is:")
////        print(String(data: data, encoding: .utf8)!)
////        ########################################################
////        DEBUG
////        ########################################################
//
//        let decoder = JSONDecoder()
//        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
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

    // Async variant that awaits each delete so callers can ensure completion
    func processDeleteComputersBasicAsync(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType) async {
        separationLine()
        print("Running: processDeleteComputersBasicAsync")
        self.processingComplete = false
        var failedDeletes: [String] = []

        for eachItem in selection {
            separationLine()
            let computerID = String(describing: eachItem)
            print("Attempting delete for computerID: \(computerID)")
            do {
                try await deleteComputerAwait(server: server, authToken: authToken, resourceType: resourceType, itemID: computerID)
                print("Delete succeeded for id: \(computerID)")
            } catch {
                print("Delete failed for id: \(computerID) - error: \(error)")
                failedDeletes.append(computerID)
            }
            // brief pause to avoid hammering the server
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        // Refresh basic list after deletes complete
        do {
            try await getComputersBasic(server: server, authToken: authToken)
        } catch {
            print("Failed to refresh computers after delete: \(error)")
        }

        separationLine()
        print("Finished async deletes; failures: \(failedDeletes)")
        self.processingComplete = true
    }
    
    
    //    #################################################################################
    //    processUpdateComputerName
    //    #################################################################################
    
    
    func processUpdateComputerName(selection:  Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, computerName: String) {
        
        separationLine()
        print("Running: processDeleteComputers")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        var count = 1
        
        for eachItem in selection {
            separationLine()
            print("Count is currently:\(count)")
            print("Items as Dictionary is \(eachItem)")
            let computerID = String(describing:eachItem)
            print("Current computerID is:\(computerID)")
            let updatedName = computerName + " \(count)"
            print("UpdatedName is:\(updatedName)")
            updateComputerName(server: server, authToken: authToken, resourceType: resourceType, computerName: updatedName, computerID: computerID )
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
    //    processPolicyDetail EXAMPLE
    //    #################################################################################
    
    
//    func processPolicyDetail(data: Data, response: URLResponse, resourceType: ResourceType) {
//
//        separationLine()
//        print("Running: processPolicyDetail")
//        print("ResourceType is:\(String(describing: ResourceType.self))")
//
//        let decoded = PoliciesDetailReply.decode(data)
//
//        switch decoded {
//        case .success(let policyDetailed):
//            receivedPolicyDetail(policyDetailed: policyDetailed)
//            separationLine()
//
//        case .failure(let error):
//            print("Decoding failed - Corrupt data. \(response) \(error)")
//            separationLine()
//            appendStatus("Corrupt data. \(response) \(error)")
//        }
//    }
    
    
    //    #################################################################################
    //    processUpdatePolicies - run on a selection - update category and enable
    //    #################################################################################
    
    
    func processUpdatePolicies(selection: Set<Policy>, server: String,  resourceType: ResourceType, enableDisable: Bool, authToken: String) {
        
        separationLine()
        print("Running: processUpdatePolicies working for resources:\(resourceType)")
        print("Set processingComplete to false")
        self.processingComplete = false
        print(String(describing: self.processingComplete))
        
        for eachItem in selection {
            separationLine()
            
            let policyID: String = String(describing:eachItem.jamfId ?? 0)
            let policyName: String = String(describing:eachItem.name )
            
            print("Getting detailed policy")
            print("policyID is:\(policyID)")
            print("policyName is:\(policyName)")
            
//            self.connectDetailed(server: server, authToken: authToken, resourceType: resourceType, itemID: Int(policyID) ?? 0)
            
            let newCategoryName: String = self.selectedCategory.name
            let newCategoryID: String = String(describing: self.selectedCategory.jamfId)
            let policyEnDisable: Bool = enableDisable
            
            print("New categoryName is:\(newCategoryName))")
            print("New categoryID is:\(newCategoryID)")
            print("policyEnDisable is:\(policyEnDisable)")
            
            if self.policyDetailed != nil {
                if let categoryName = self.policyDetailed?.general?.category?.name {
                    let categoryID = self.policyDetailed?.general?.category?.jamfId
                    print("Old categoryName is:\(categoryName)")
                    print("Old categoryID is:\(String(describing: categoryID))")
                }
                
            } else {
                print("Getting current detailed policy record failed")
            }
            
            print("Updating the category to \(newCategoryName)")
            
            self.updateCategoryEnDisable(server: server, resourceType: resourceType, policyEnDisable: String(describing: policyEnDisable), categoryID: String(describing: newCategoryID), categoryName: newCategoryName, updatePressed: true, policyID: policyID, authToken: authToken)
            print("Current policyID is:\(policyID)")
            print("policyEnDisable is set as:\(String(describing: policyEnDisable))")
            
        }
        
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
    }
    
    //    #################################################################################
    //    processUpdatePoliciesCombined - run on an Array  - update category and enable
    //    #################################################################################
    
    
    func processUpdatePoliciesCombined(selection: [Int?], server: String,  resourceType: ResourceType, enableDisable: Bool, authToken: String) {
        
        separationLine()
        print("Running: processUpdatePolicies working for resources:\(resourceType)")
        print("Set processingComplete to false")
        self.processingComplete = false
        print(String(describing: self.processingComplete))
        
        for policyID in selection {
            separationLine()
            print("policyID is:\(String(describing: policyID))")
            
//            self.connectDetailed(server: server, authToken: authToken, resourceType: resourceType, itemID: policyID ?? 0 )
            
            let newCategoryName: String = self.selectedCategory.name
            let newCategoryID: String = String(describing: self.selectedCategory.jamfId)
            let policyEnDisable: Bool = enableDisable
            
            print("New categoryName is:\(newCategoryName)")
            print("New categoryID is:\(newCategoryID)")
            print("policyEnDisable is:\(policyEnDisable)")
            print("Updating the category to \(newCategoryName)")
            
            self.updateCategoryEnDisable(server: server, resourceType: resourceType, policyEnDisable: String(describing: policyEnDisable), categoryID: String(describing: newCategoryID), categoryName: newCategoryName, updatePressed: true, policyID: String(describing: policyID ?? 0), authToken: authToken)
            print("Current policyID is:\(String(describing: policyID ?? 0))")
            print("policyEnDisable is set as:\(String(describing: policyEnDisable))")
            
        }
        
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
    }
    
      //    #################################################################################
    //    processUpdateCategory - run on an Array  - update category
    //    #################################################################################
    
    
    func processBatchUpdateCategory(selection: [Int?], server: String,  resourceType: ResourceType, authToken: String, newCategoryName: String, newCategoryID: String ) {
        
        separationLine()
        print("Running: processBatchUpdateCategory working for resources:\(resourceType)")
        print("Set processingComplete to false")
        print("newCategoryName is:\(String(describing: newCategoryName))")
        print("newCategoryID is:\(String(describing: newCategoryID))")

        self.processingComplete = false
        print(String(describing: self.processingComplete))
        
        for policyID in selection {
            separationLine()
            print("policyID is:\(String(describing: policyID))")
            
//            self.connectDetailed(server: server, authToken: authToken, resourceType: resourceType, itemID: policyID ?? 0 )
//            let newCategoryName: String = self.selectedCategory.name
//            let newCategoryID: String = String(describing: self.selectedCategory.jamfId)
            
            print("New categoryName is:\(newCategoryName)")
            print("New categoryID is:\(newCategoryID)")
            print("Updating the category to \(newCategoryName)")
            
            self.updateCategory(server: server,authToken: authToken, resourceType: ResourceType.policyDetail, categoryID: String(describing: newCategoryID), categoryName: String(describing: newCategoryName), updatePressed: true, resourceID: String(describing: policyID ?? 0))

            print("Current policyID is:\(String(describing: policyID ?? 0))")
            
        }
        
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
    }
    
    //    #################################################################################
    //    processUpdateComputerDepartment - update department
    //    #################################################################################
    
    
    func processUpdateComputerDepartment(selection:  Set<ComputerBasicRecord>, server: String, authToken: String, resourceType: ResourceType, department: String ) {
        
        separationLine()
        print("Running: processUpdateComputerDepartment function - working for resourceType:\(resourceType)")
        print("Set processingComplete to false")
        self.processingComplete = false
        print(String(describing: self.processingComplete))
        print("Selection is:\(selection)")
        
        for eachItem in selection {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let computerID: String = String(describing:eachItem.id )
            let computerName: String = String(describing:eachItem.name )
            separationLine()
            print("computerID is:\(computerID)")
            print("computerName is:\(computerName)")
            self.updateComputerDepartment(server: server, authToken: authToken, resourceType: ResourceType.computerDetailed, departmentName: department, computerID: computerID)
            print("Updating the department to \(department)")
        }
        
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
    }
    
    //    #################################################################################
    //    processUpdateComputerDepartmentBasic - update department
    //    #################################################################################
    
    
    func processUpdateComputerDepartmentBasic(selection:  Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, department: String ) {
        
        separationLine()
        print("Running: processUpdateComputerDepartment function - working for resourceType:\(resourceType)")
        print("Set processingComplete to false")
        self.processingComplete = false
        print(String(describing: self.processingComplete))
        print("Selection is:\(selection)")
        
        for eachItem in selection {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let computerID: String = String(describing:eachItem )
            separationLine()
            print("computerID is:\(computerID)")
            self.updateComputerDepartment(server: server, authToken: authToken, resourceType: ResourceType.computerDetailed, departmentName: department, computerID: computerID)
            print("Updating the department to \(department)")
        }
        
        separationLine()
        print("Finished - Set processingComplete to true")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        
    }
    
    
    
    //    #################################################################################
    //    BATCH PROCESSING - END
    //    #################################################################################
    
    
    //    #################################################################################
    //    EDITING POLICIES - via XML
    //    #################################################################################
    
    
    //    #################################################################################
    //    editPolicy - change package
    //    #################################################################################
    
    
    func editPolicy(server: String, authToken: String, resourceType: ResourceType, packageName: String, packageID: String, policyID: Int, action: String,fut: String, feu: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let packageIDString = String(packageID)
        let packageName = packageName
        let policyIDString = String(policyID)
        
        var xml: String
        
        xml = """
            <policy>
            <package_configuration>
            <packages>
                <size>1</size>
                <package>
                    <id>\(packageIDString)</id>
                    <name>\(packageName)</name>
                    <action>\(action)</action>
                    <fut>\(fut)</fut>
                    <feu>\(feu)</feu>
                    <update_autorun>false</update_autorun>
                </package>
            </packages>
            </package_configuration>
            </policy>
            """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/\(policyIDString)")
                
                print("Editing policy function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                print("resourcePath is set as:\(resourcePath)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            } else {
                print("URL not set")
            }
        }
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

    // Update the username attribute for a computer (from a detailed computer record)
    // Example usage: updateComputerUsername(server:server, authToken:token, resourceType:.computerDetailed, computerID: "123", newUsername: "jdoe")
    func updateComputerUsername(server: String, authToken: String, resourceType: ResourceType, computerID: String, newUsername: String) {
        let resourcePath = getURLFormat(data: (resourceType))
        var xml: String

        self.separationLine()
        print("updateComputerUsername XML")
        print("newUsername is set as:\(newUsername)")
        print("computerID is set as:\(computerID)")

        xml = """
                <computer>
                    <general>
                        <username>\(newUsername)</username>
                    </general>
                </computer>
                """

        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(computerID)
                print("Running update computer username function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // send XML PUT to update username
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
            } else {
                print("Error making serverURL for updateComputerUsername")
            }
        } else {
            print("Invalid server string passed to updateComputerUsername: \(server)")
        }
    }

    // Convenience: update username using a decoded ComputerFull (from ComputerDetailedFullResponse)
    // If `overrideUsername` is provided it will be used; otherwise the function uses the value
    // found in `computerFull.general?.username`. The function logs useful diagnostics and
    // returns early when required fields are missing.
    func updateComputerUsername(from computerFull: ComputerFull, overrideUsername: String? = nil, server: String, authToken: String, resourceType: ResourceType = .computerDetailed) {
        // Attempt to get the Jamf ID from the detailed object. Many decoded structs represent
        // the id as a String; if it's numeric elsewhere callers can adapt accordingly.
        guard let general = computerFull.general else {
            print("updateComputerUsername(from:): detailed computer record missing 'general' section")
            return
        }

        // Some 'general.id' implementations are Strings, others may be Int; normalize to String
        let jamfIDString: String = {
            if let idStr = (general as AnyObject).value(forKey: "id") as? String {
                return idStr
            }
            // Fallback: try to use Mirror to read 'id' as Int or other convertible types
            let mirror = Mirror(reflecting: general)
            for child in mirror.children {
                if child.label == "id" {
                    return String(describing: child.value)
                }
            }
            return ""
        }()

        if jamfIDString.isEmpty {
            print("updateComputerUsername(from:): could not determine Jamf ID from detailed record")
            return
        }

        // Determine username to apply
        let usernameToSet = overrideUsername ?? (general as AnyObject).value(forKey: "username") as? String ?? ""
        if usernameToSet.isEmpty {
            print("updateComputerUsername(from:): no username available to set (overrideUsername and detailed record both empty)")
            return
        }

        // Delegate to existing updater
        updateComputerUsername(server: server, authToken: authToken, resourceType: resourceType, computerID: jamfIDString, newUsername: usernameToSet)
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

    // A logical variant of updateName that derives a new name from the existing
    // policy name using simple operations, then uploads the resulting name.
    // Supported actions:
    // - "removelast": remove the last `count` characters
    // - "replacelast": remove the last `count` characters and append `replacement`
    // - "replaceall": replace all occurrences of `match` with `replacement`
    // If the in-memory detailed policy isn't available the function will log and return.
    func updatePolicyNameLogical(server: String, authToken: String, resourceType: ResourceType, policyID: String, action: String, count: Int = 0, match: String = "", replacement: String = "") {
        // Attempt to obtain the current name from the in-memory detailed policy
        let currentName = self.policyDetailed?.general?.name ?? ""
        guard !currentName.isEmpty else {
            print("updatePolicyNameLogical: current policy name not available in memory for id: \(policyID). Aborting.")
            return
        }

        var newName = currentName
        let lowerAction = action.lowercased()
        switch lowerAction {
        case "removelast":
            if count > 0 {
                let remove = min(count, newName.count)
                newName = String(newName.dropLast(remove))
            }
        case "replacelast":
            if count > 0 {
                let remove = min(count, newName.count)
                newName = String(newName.dropLast(remove)) + replacement
            } else {
                // if count is zero, just append the replacement
                newName += replacement
            }
        case "replaceall":
            if !match.isEmpty {
                newName = newName.replacingOccurrences(of: match, with: replacement)
            }
        default:
            print("updatePolicyNameLogical: unknown action '\(action)'. Supported: removelast, replacelast, replaceall")
            return
        }

        // If nothing changed, there's no need to update
        if newName == currentName {
            print("updatePolicyNameLogical: computed name is identical to current name; nothing to do")
            return
        }

        // Delegate to the same XML-based update used by updateName
        let resourcePath = getURLFormat(data: (resourceType))
        var xml: String
        self.separationLine()
        print("updatePolicyNameLogical - currentName='\(currentName)' newName='\(newName)'")

        xml = """
                <policy>
                    <general>
                        <name>\(newName)</name>
                    </general>
                </policy>
                """

        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(policyID)
                print("Running updatePolicyNameLogical - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
                print("Set updateXML to true ")
                self.updateXML = true
            }
        } else {
            print("updatePolicyNameLogical: invalid server string")
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
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
                
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
                print("Running:sendRequestAsXML to push the updated xml")
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
        else {
            print("clearScope request failed")
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
        else {
            print("clearComputers request failed")
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
                                                      <name>\(computerName)</name>
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
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
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
                print("Running update group function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                            
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }

    // Remove a computer from a static computer group via XML
    func updateGroupRemoveID(server: String,authToken: String, resourceType: ResourceType, groupID: String, computerID: Int) {
        var xml: String
        print("Running updateGroupRemoveID - updating via xml")
        print("computerID is set as:\(computerID)")
        print("groupID is set as:\(groupID)")

        xml = """
    <computer_group>
        <computer_deletions>
            <computer>
                <id>\(computerID)</id>
            </computer>
        </computer_deletions>
    </computer_group>
"""

        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("/computergroups/id").appendingPathComponent(groupID)
                print("Running update group remove function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
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
                sendRequestAsXML(url: url, authToken: authToken, resourceType: ResourceType.policyDetail, xml: xml, httpMethod: "PUT")
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

    func processRemoveComputersFromGroupAsync(selection: Set<ComputerBasicRecord.ID>, server: String, authToken: String, resourceType: ResourceType, computerGroup: ComputerGroup) async {
        separationLine()
        print("Running: processRemoveComputersFromGroup")
        print("Set is:\(selection)")
        var count = 1

        for eachItem in selection {
            separationLine()
            print("Count is currently:\(count)")
            print("Items as Dictionary is \(eachItem)")
            let computerID = String(describing:eachItem)
            print("Current computerID is:\(computerID)")
            updateGroupRemoveID(server: server, authToken: authToken, resourceType: resourceType, groupID: String(describing:computerGroup.id), computerID: Int(computerID) ?? 0 )
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
                    //                    // print("xml is set as:\(xml)")
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
                    appendStatus("Connecting to \(url)...")
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
                sendRequestAsXML(url: url, authToken: authToken, resourceType: resourceType, xml: xml, httpMethod: "PUT")
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
                print("Error is:")
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
    //    Create Objects - Push Policies - via XML
    //    #################################################################################
    
    
    
    func createNewPolicy(server: String, authToken: String, policyName: String, customTrigger: String , categoryID: String, category: String, departmentID: String, department: String, scriptID: String, scriptName: String, scriptParameter4: String, scriptParameter5: String, scriptParameter6: String, resourceType: ResourceType, notificationName: String, notificationStatus: String ) {
        
        var xml:String
        //        let date = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .short))
        
        let sem = DispatchSemaphore.init(value: 0)
        
        //        DEBUG
        self.separationLine()
        print("DEBUGGING")
        self.separationLine()
        print("Running createNewPolicy")
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
                <no_user_logged_in>Do not restart</no_user_logged_in>
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
                        self.processPackages(data: data, response: response, resourceType: "packages")
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
        print("Running requestDelete function - url is set as:\(url)")

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "DELETE"
        // Debug: print the request URL and headers
        print("requestDelete - URL: \(request.url?.absoluteString ?? "<no url>")")
//        print("requestDelete - Headers: \(request.allHTTPHeaderFields ?? [:])")

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in

            // Default to assuming there will be an error until we verify otherwise
            var statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if let error = error {
                print("requestDelete network error: \(error)")
            }

            // If we have data/response, process according to resourceType. Make sure UI updates
            // happen on the main actor/queue.
            DispatchQueue.main.async {
//                defer {
//                    // Ensure we always clear the processing flag when the network call completes
//                    self.processingComplete = true
//                    print("requestDelete finished; processingComplete set to true")
//                }

                if let response = response {
                    statusCode = (response as? HTTPURLResponse)?.statusCode ?? statusCode
                    self.currentResponseCode = String(describing: statusCode)
                    if let http = response as? HTTPURLResponse {
                        print("requestDelete - response status: \(http.statusCode)")
                        print("requestDelete - response headers: \(http.allHeaderFields)")
                    }
                }

                // Treat non-200/204 status as an error
                if statusCode != 200 && statusCode != 204 {
                    self.hasError = true
                    print("requestDelete HTTP status: \(statusCode)")
                }

                if let data = data {
                    let body = String(data: data, encoding: .utf8) ?? "<binary>"
                    print("Doing processing of requestDelete; body:\n\(body)")

                    if statusCode != 200 && statusCode != 204 {
                        print("requestDelete ERROR body:\n\(body)")
                    }

                } else {
                    // No data returned; still ensure UI state updated
                    print("requestDelete: no data returned, response: \(String(describing: response)), error: \(String(describing: error))")
                }
            }
        }
        dataTask.resume()
    }

    // Async variant that callers can await so they know the delete has completed (200 or 204 accepted)
    func deleteComputerAwait(server: String, authToken: String, resourceType: ResourceType, itemID: String) async throws {
        // Map convenient resource types to the detailed "computers/id" path
        let effectiveResourceType: ResourceType = {
            if resourceType == .computer || resourceType == .computerBasic {
                return .computerDetailed
            }
            return resourceType
        }()

        let resourcePath = getURLFormat(data: effectiveResourceType)
        if let url = buildJSSResourceURL(server: server, resourcePath: resourcePath, itemID: itemID) {
            separationLine()
            print("Running deleteComputerAwait - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            try await requestDeleteAwait(url: url, authToken: authToken, resourceType: resourceType)
            print("deleteComputerAwait finished for id:\(itemID)")
        } else {
            print("deleteComputerAwait: failed to build URL for resourcePath=\(resourcePath) itemID=\(itemID)")
            throw JamfAPIError.badURL
        }
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
        
        print("Request is:\(request)")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Data is:\(String(describing: String(data: data, encoding: .utf8) ?? "no data") )")

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 || statusCode == 204 else {
            print("Code not 200/204")
            self.hasError = true
            self.currentResponseCode = String(describing: statusCode)
            print("requestDeleteXML Status code is:\(statusCode)")
            throw JamfAPIError.http(statusCode)
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

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 || statusCode == 204 else {
            print("Code not 200/204")
            self.hasError = true
            self.currentResponseCode = String(describing: statusCode)
            print("requestDeleteXML Status code is:\(statusCode)")
            throw JamfAPIError.http(statusCode)
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
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            } else {
                if let error = error {
                    var text = "\n\nError encountered:"
                    text += " \(error)."
                    print(text)
                }

                DispatchQueue.main.async {
                    self.hasError = true
                }
                 //                self.appendStatus(text)
             }
             
             let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            DispatchQueue.main.async {
                self.currentResponseCode = String(describing: statusCode)
            }
        }

        dataTask.resume()
    }
    
    
    func sendRequestAsXMLAsync(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String ) async throws {
    
        
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
        print("policyID is:\(policyID)")
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
            throw JamfAPIError.http(statusCode)
            
            
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
//        if let last = lastRequestDate {
//            print("Last request ran at:\(String(describing: last))")
//            let elapsed = now.timeIntervalSince(last)
//            if elapsed < minInterval {
//                let delay = minInterval - elapsed
//                print("Waiting:\(String(describing: delay))")
//                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
//            }
//        }
        lastRequestDate = Date()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseCode = (response as? HTTPURLResponse)?.statusCode
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - Response is:\(String(describing: responseCode ?? 0))")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(Icon.self, from: data) {
            self.iconDetailed = decodedData
//            separationLine()
            print("Raw data is:")
            print(String(data: data, encoding: .utf8)!)

        print("Decoding getDetailedIcon - iconID is:\(iconID)")
        print("Response is:\(String(describing: responseCode ?? 0))")
        print("Add to:allIconsDetailed: Icon id is:\(iconID)")
            // Only insert if this icon (by id) is not already present to avoid duplicates
            if !self.allIconsDetailed.contains(where: { $0.id == self.iconDetailed.id }) {
                self.allIconsDetailed.insert(self.iconDetailed, at: 0)
            } else {
                print("Icon with id \(self.iconDetailed.id) already exists in allIconsDetailed; skipping insert")
            }
        } else {
            print("Decoding failed")
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
        //  #######################################################################
    //  #######################################################################


    
    @Published var isLoading = false
    @Published var needsCredentials = false
    @Published var connected = false
    // Indicates whether there are cached credentials available in the keychain
    var hasCachedCredentials: Bool {
        guard !server.isEmpty, !username.isEmpty else { return false }
        let pw = getPassword(account: username, service: server)
        return !pw.isEmpty
    }
    //        @Published var hasError = false
    //        var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    //        var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }

//    var password = ""

    var auth: JamfAuthToken?
    
    
    @Published var computersample: [ComputerSample] = []
    @Published var scriptclassic: [ScriptClassic] = []
    @Published var scriptold: [Script] = []

    
    @MainActor
    func load() async {
        isLoading = true
        defer {
            isLoading = false
        }
        
        //              ##############################################################
        //              Samples for preview mode
        //              ##############################################################
        
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // preview mode return sample data
            computersample = ComputerSample.samples
            return
        }
        
        // not in preview mode
        
        //              ##############################################################
        //              Connections
        //              ##############################################################
        separationLine()
        print("Running JamfController.load")
        
        // attempt to get an auth token
        await connect()
        
        // only continue if connected
        guard connected, let auth = auth else { return }
        
        //              ##############################################################
        //              Buildings
        //              ##############################################################
        
        //        if let fetchedBuildings = try? await Building.getAll(server: server, auth: auth) {
        //            buildings = fetchedBuildings
        //            //        print(scripts)
        //            print("fetchedBuildings has run successfully")
        //
        //        } else {
        //            //      hasError = true
        //            print("fetchedBuildings has errored")
        //        }
        
        //              ##############################################################
        //              Computers
        //              ##############################################################
        
        if let fetchedComputers = try? await ComputerSample.getAll(server: server, auth: auth) {
            computersample = fetchedComputers
            //          print(computers)
            separationLine()
            print("fetchedComputers has run successfully")
            
        } else {
            //          hasError = true
            separationLine()
            print("fetchedComputers has errored")
        }
        
        //              ##############################################################
        //              Scripts
        //              ##############################################################
        
        if let fetchedScripts = try? await Script.getAll(server: server, auth: auth) {
            scriptold = fetchedScripts
            //        print(scripts)
            separationLine()
            print("fetchedScripts has run successfully")
            
        } else {
            //      hasError = true
            separationLine()
            print("fetchedScripts has errored")
        }
    }
    
    //              ##############################################################
    //              End requests
    //              ##############################################################
    
    @MainActor
    func connect() async {
        // do we have all credentials?
        if server.isEmpty || username.isEmpty {
            needsCredentials = true
            connected = false
            return
        }
        
        if password.isEmpty {
            // try to get password from keychain
            guard let pwFromKeychain = try? Keychain.getPassword(service: server, account: username)
            else {
                needsCredentials = true
                connected = false
                return
            }
            password = pwFromKeychain
        }
        
        if auth == nil {
            // no token yet, get one
            separationLine()
            print("Running JamfAuthToken.get")
            auth = try? await self.getToken(server: server, username: username, password: password)
            if auth == nil {
                // couldn't get a token, most likely the credentials are wrong
                hasError = true
                needsCredentials = true
                connected = false
                return
            }
        }
        
        // we have a token, all is good
        needsCredentials = false
        hasError = false
        connected = true
    }
    
    
    
    
    
    
    // -------------------- Users --------------------
    // Published state for users list and detailed user (matches Models/UsersModels.swift)
    @Published var allUsers: [UserSimple] = []
    @Published var userDetail: UserDetail? = nil

    // Ensure policies are loaded; try the JSON API first, fall back to request pipeline if it fails
    @MainActor
    func ensurePoliciesLoaded(server: String, authToken: String) async {
        separationLine()
        print("ensurePoliciesLoaded: server=\(server), auth present=\(!authToken.isEmpty)")

        // If we already have policies, nothing to do
        if !self.allPoliciesConverted.isEmpty || !self.policies.isEmpty {
            print("Policies already present: allPoliciesConverted=\(self.allPoliciesConverted.count), policies=\(self.policies.count)")
            // Make sure legacy array is synced
            if self.allPoliciesConverted.isEmpty, !self.policies.isEmpty {
                self.allPoliciesConverted = self.policies
            }
            return
        }

        // Try the JSON API approach first
        do {
            print("ensurePoliciesLoaded: attempting JSON API getAllPolicies")
            try await getAllPolicies(server: server, authToken: authToken)
            print("ensurePoliciesLoaded: getAllPolicies succeeded - count=\(self.allPoliciesConverted.count)")
            return
        } catch {
            print("ensurePoliciesLoaded: getAllPolicies failed: \(error). Falling back to request pipeline.")
        }

        // Fallback: use the legacy request pipeline which will call processPolicies -> receivedPolicies
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent("policies")
            print("ensurePoliciesLoaded: issuing legacy request to \(url)")
            request(url: url, resourceType: ResourceType.policies, authToken: authToken)

            // The legacy request pipeline will call `receivedPolicies(...)` which
            // now syncs `policies` -> `allPoliciesConverted` immediately. No
            // artificial sleep or delayed sync is required here.
        } else {
            print("ensurePoliciesLoaded: invalid server URL, cannot fallback")
        }
    }

    // Centralized error state (UI observes these to show alerts)
    @Published var lastErrorTitle: String? = nil
    @Published var lastErrorMessage: String? = nil
    // Structured details extracted from server error responses (e.g. dependent items preventing delete)
    @Published var lastErrorDetails: [String] = []
    @Published var showErrorAlert: Bool = false

    func publishError(_ error: Error, title: String? = nil) {
        // If the error is a RequestSender.RequestError, produce a precise title/message
        if let reqErr = error as? RequestSender.RequestError {
            var t = title
            var message: String?
            switch reqErr {
            case .invalidURL(let url):
                t = t ?? "Invalid URL"
                message = "Invalid server URL: \(url). Check your server setting and include the scheme (https://)."
            case .unauthorized:
                // If the title indicates we were performing an operation (e.g. "Failed to ..."),
                // show a permission-style message. Otherwise keep the authentication hint.
                if let providedTitle = title?.lowercased(), providedTitle.contains("failed") || providedTitle.contains("load") || providedTitle.contains("perform") {
                    t = t ?? "Not authorised"
                    message = "You are not authorised to perform this operation. Please check your account privileges."
                } else {
                    t = t ?? "Unauthorized"
                    message = reqErr.errorDescription
                }
            case .forbidden:
                t = t ?? "Forbidden"
                message = reqErr.errorDescription
            case .notFound:
                t = t ?? "Not Found"
                message = reqErr.errorDescription
            case .serverError(let code, let body):
                t = t ?? "Server error \(code)"
                if let body = body, !body.isEmpty {
                    message = "Server error (HTTP \(code)). Response: \(body)"
                } else {
                    message = "Server error (HTTP \(code))."
                }
            case .unexpectedStatus(let code, let body):
                t = t ?? "Unexpected response \(code)"
                if let body = body, !body.isEmpty {
                    message = "Unexpected response (HTTP \(code)). Response: \(body)"
                } else {
                    message = "Unexpected response (HTTP \(code))."
                }
            case .network(let err):
                t = t ?? "Network error"
                message = "Network error: \(err.localizedDescription)"
            case .decoding(let err, let body):
                t = t ?? "Decode error"
                if let body = body, !body.isEmpty {
                    message = "Failed to decode server response: \(err.localizedDescription). Response body: \(body)"
                } else {
                    message = "Failed to decode server response: \(err.localizedDescription)"
                }
            }

            DispatchQueue.main.async {
                self.lastErrorTitle = t ?? "Error"
                self.lastErrorMessage = message ?? reqErr.errorDescription ?? "An error occurred"
                self.showErrorAlert = true
                print("Published RequestError: \(self.lastErrorTitle ?? "Error") - \(self.lastErrorMessage ?? "")")
            }
            return
        }

        // Next prefer LocalizedError.errorDescription
        if let localized = (error as? LocalizedError)?.errorDescription {
            DispatchQueue.main.async {
                self.lastErrorTitle = title ?? "Error"
                self.lastErrorMessage = localized
                self.showErrorAlert = true
                print("Published error: \(self.lastErrorTitle ?? "Error") - \(localized)")
            }
            return
        }

        // Fallback to NSError description
        let message = (error as NSError).localizedDescription
        DispatchQueue.main.async {
            self.lastErrorTitle = title ?? "Error"
            self.lastErrorMessage = message
            self.showErrorAlert = true
            print("Published error: \(self.lastErrorTitle ?? "Error") - \(message)")
        }
    }

    // Fetch list of users (wrapper: { "users": [...] })
    func getAllUsers() async throws {
        do {
            let request = APIRequest<UserListResponse>(endpoint: "users", method: .get)
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.allUsers = decoded.users
            print("Loaded \(allUsers.count) users")
        } catch {
            publishError(error, title: "Failed to load users")
            throw error
        }
    }
    
    
    
    
    func getAllPackages() async throws {
        do {
            let request = APIRequest<Packages>(endpoint: "packages", method: .get)
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.packages = decoded.packages
            print("Loaded \(packages.count) packages")
        } catch {
            publishError(error, title: "Failed to load packages")
            throw error
        }
    }
    
    
    
    func getAllScripts() async throws {
        do {
            print("Running getAllScripts (paginated)")
            // Ensure we have a valid token (refresh or fetch if needed)
            let validToken = try await getValidToken(server: server)
            // Assign to authToken in case getValidToken refreshed it
            self.authToken = validToken

            // Pagination parameters
            var page = 0
            let pageSize = 500
            var accumulated: [Script] = []
            var totalCount: Int? = nil

            while true {
                let endpoint = "/api/v1/scripts?page=\(page)&page-size=\(pageSize)"
                let request = APIRequest<ScriptResults>(endpoint: endpoint, method: .get)
                let decoded = try await requestSender.resultFor(apiRequest: request)

                // Append page results
                accumulated.append(contentsOf: decoded.results)

                // Capture totalCount from first response if provided
                if totalCount == nil {
                    totalCount = decoded.totalCount
                }

                print("Fetched page \(page): returned \(decoded.results.count) scripts; accumulated=\(accumulated.count) totalReported=\(totalCount ?? -1)")

                // Stop if this page returned fewer results than pageSize or we've reached the reported total
                if decoded.results.count < pageSize { break }
                if let total = totalCount, accumulated.count >= total { break }

                // Otherwise fetch next page
                page += 1
            }

            // Assign into published properties
            await MainActor.run {
                self.allScriptsDetailed = accumulated

                // Map to the lightweight ScriptClassic used elsewhere in the UI
                self.scripts = accumulated.map { s in
                    let jamfId = Int(s.id) ?? 0
                    return ScriptClassic(name: s.name, jamfId: jamfId)
                }

                // Mirror into the allScripts collection as a convenience for other views
                self.allScripts = self.scripts
            }

            print("Loaded \(accumulated.count) scripts across \(page + 1) page(s)")
        } catch {
            // Provide clearer diagnostics when script fetching fails
            separationLine()
            print("Failed to load scripts: \(error)")
            publishError(error, title: "Failed to load scripts")
            throw error
        }
    }
    
    
    

    // Fetch detailed user by id
    func getDetailUser(userID: String) async throws {
        do {
            let request = APIRequest<UserDetailResponse>(endpoint: "users/id/" + userID, method: .get)
            print("APIRequest: \(request)")
            // ensure we have an auth token
            if authToken.isEmpty {
                _ = try await getToken(server: server, username: username, password: password )
            }
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.userDetail = decoded.user
            print("Loaded detail for user id: \(userID)")
        } catch {
            publishError(error, title: "Failed to load user details")
            throw error
        }
    }

    // Fetch detailed computer by id (lightweight decode)
    func getDetailedComputer(userID: String) async throws {
        do {
            // Decode the full detailed response (includes hardware/security)
            let request = APIRequest<ComputerDetailedFullResponse>(endpoint: "computers/id/" + userID, method: .get)
            print("APIRequest (computer detailed full): \(request)")
            if authToken.isEmpty {
                _ = try await getToken(server: server, username: username, password: password)
            }
            // record the current URL for debugging (RequestSender builds the final URL similarly)
            self.currentURL = server + "/JSSResource/computers/id/" + userID
            // Attempt decode with detailed DecodingError logging to help diagnose failures
            let decodedFull: ComputerDetailedFullResponse
            do {
                decodedFull = try await requestSender.resultFor(apiRequest: request)
            } catch let decodeError as DecodingError {
                // Provide rich diagnostics for common DecodingError cases
                separationLine()
                print("DecodingError while parsing ComputerDetailedFullResponse:")
                switch decodeError {
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type: \(type). Debug description: \(context.debugDescription). CodingPath: \(context.codingPath)")
                case .valueNotFound(let value, let context):
                    print("Value not found for type: \(value). Debug description: \(context.debugDescription). CodingPath: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key.stringValue). Debug description: \(context.debugDescription). CodingPath: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("Data corrupted. Debug description: \(context.debugDescription). CodingPath: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error: \(decodeError)")
                }
                separationLine()
                publishError(decodeError, title: "Decoding failure")
                throw decodeError
            } catch {
                // Non-decoding error (network, etc.)
                separationLine()
                print("Error while fetching ComputerDetailedFullResponse: \(error)")
                publishError(error, title: "Failed to load computer detail")
                throw error
            }
            // Debug: print entire decoded response so we can inspect what arrived
            separationLine()
//            print("Decoded ComputerDetailedFullResponse: \(decodedFull)")
            // Publish the decoded full structure for detailed UI consumption
            self.computerDetailedFull = decodedFull.computer
            // record successful response code for UI
            self.currentResponseCode = "200"
            // clear any previous error message
            self.lastErrorMessage = nil
            // Also keep the slim ComputerDetailedResponse if other code relies on it.
            // Attempt to map a lightweight ComputerSlim.General-like structure into computerDetailedResponse
            // Map fields available in the full response into the slim response shape
            let gen = decodedFull.computer.general
            let loc = decodedFull.computer.location

            if let gen = gen {
                // Map to ComputerBasicRecord for existing UI
                let jamfId = Int(gen.id) ?? 0
                
                
                if let loc = loc {
                    // Note: parameter order for ComputerBasicRecord is id,name,managed,username,model,department,building,macAddress,udid,serialNumber,reportDateUTC,reportDateEpoch
                    let detail = ComputerBasicRecord(id: jamfId,
                                                     name: gen.name ?? "",
                                                     managed: true,
                                                     username: gen.username ?? "",
                                                     model: gen.model ?? "",
                                                     department: loc.department ?? "",
                                                     building: loc.building ?? "",
                                                     macAddress: "",
                                                     udid: gen.udid ?? "",
                                                     serialNumber: gen.serial_number ?? "",
                                                     reportDateUTC: gen.report_date_utc ?? "",
                                                     reportDateEpoch: 0)
                    self.computerDetailed = detail
                    print("Loaded detailed computer id: \(jamfId)")
                }
            } else {
                print("Decoded full response had no general section")
            }
            

            if let loc = loc {
                print("Location info: department=\(loc.department ?? "(none)"), building=\(loc.building ?? "(none)"), room=\(loc.room ?? "(none)")")
            }
            
            
        } catch {
            publishError(error, title: "Failed to load computer detail")
            throw error
        }
    }
    
    
    
    func getAllDetailedUsers(server: String, authToken: String, users: [UserSimple]) async throws {

        self.separationLine()
        print("Running func: getAllPoliciesDetailed")

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
                DispatchQueue.main.async {
                    self.policyDelayStatus = "Delaying detailed user fetch: \(human) (next at \(nextRunAt))"
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        } else {
            print("No previous request timestamp found; proceeding immediately")
        }
        lastRequestDate = Date()

        for user in users {
            Task {
                try await getDetailUser(userID: String(describing: user.jamfId))

                if policyDetailed != nil {
                    print("Users is:\(String(describing: user.name)) - ID is:\(String(describing: user.jamfId ?? 0))")
                }
            }
        }
    }
    // Fetch all categories
      func getAllCategories() async throws {
          do {
              let request = APIRequest<AllCategories>(endpoint: "categories", method: .get)
              let decoded = try await requestSender.resultFor(apiRequest: request)
              self.categories = decoded.categories
              print("Loaded \(categories.count) categories")
          } catch {
              self.alertTitle = "Failed to load categories"
              self.alertMessage = error.localizedDescription
              self.showAlert = true
              throw error
          }
      }

      // Fetch all departments
    func getAllDepartments() async throws {
        do {
            struct DepartmentsResponse: Codable {
                let departments: [Department]
            }
            let request = APIRequest<DepartmentsResponse>(endpoint: "departments", method: .get)
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.departments = decoded.departments
            print("Loaded \(departments.count) departments")
        } catch {
            self.alertTitle = "Failed to load departments"
            self.alertMessage = error.localizedDescription
            self.showAlert = true

        }
    }

    // Fetch detailed advanced computer search by id
    func getDetailAdvancedComputerSearch(userID: String) async throws {
        do {
            let request = APIRequest<AdvancedComputerSearchDetailedResponse>(endpoint: "advancedcomputersearches/id/" + userID, method: .get)
            print("APIRequest: \(request)")
            // ensure we have an auth token
            if authToken.isEmpty {
                _ = try await getToken(server: server, username: username, password: password )
            }
            let decoded = try await requestSender.resultFor(apiRequest: request)
            self.advancedComputerSearchDetailed = decoded.advancedComputerSearch
            print("Loaded advanced computer search detail for id: \(userID)")
        } catch {
            publishError(error, title: "Failed to load advanced computer search details")
            throw error
        }
    }

    // Fetch computer history (legacy JSSResource/computerhistory)
    // Accept an optional server parameter so callers can explicitly choose the server
    // to query; if nil the NetBrain.server is used.
    func getComputerHistory(server: String? = nil, computerID: String) async throws {
        do {
            let endpoint = "computerhistory/id/" + computerID
            let usedServer = server ?? self.server
            print("getComputerHistory: using server=\(usedServer), endpoint=\(endpoint)")
            // ensure auth token exists
            if authToken.isEmpty {
                _ = try await getToken(server: server ?? self.server, username: username, password: password)
            }

            // Build the concrete URL similar to RequestSender.fetchRawData so we can
            // fetch the raw response body directly and still preserve it for the UI.
            let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            let jamfURLQuery: String
            if trimmedEndpoint.lowercased().hasPrefix("http://") || trimmedEndpoint.lowercased().hasPrefix("https://") {
                jamfURLQuery = trimmedEndpoint
            } else if trimmedEndpoint.hasPrefix("/") {
                jamfURLQuery = usedServer + trimmedEndpoint
            } else if trimmedEndpoint.hasPrefix("api/") {
                jamfURLQuery = usedServer + "/" + trimmedEndpoint
            } else {
                jamfURLQuery = usedServer + "/JSSResource/" + trimmedEndpoint
            }

            guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.get.stringValue
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            // Fetch raw data so we can preserve the raw JSON for debugging in the UI,
            // then decode it into the typed response.
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else { throw JamfAPIError.http(status) }
            // Save raw JSON for optional display in the UI
            self.lastComputerHistoryRaw = String(data: data, encoding: .utf8)
            // Decode into the typed response
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ComputerHistoryResponse.self, from: data)
            self.computerHistory = decoded.computerHistory
            print("Loaded computer history for id: \(computerID)")
        } catch {
            publishError(error, title: "Failed to load computer history")
            throw error
        }
    }

    // Fetch a subset of the computer history using the subset path component
    // Example endpoint: computerhistory/id/<id>/subset/<subset>
    func getComputerHistorySubset(server: String? = nil, computerID: String, subset: String) async throws {
        do {
            let endpoint = "computerhistory/id/" + computerID + "/subset/" + subset
            let usedServer = server ?? self.server
            print("getComputerHistorySubset: using server=\(usedServer), endpoint=\(endpoint)")

            // ensure auth token exists
            if authToken.isEmpty {
                _ = try await getToken(server: server ?? self.server, username: username, password: password)
            }

            let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            let jamfURLQuery: String
            if trimmedEndpoint.lowercased().hasPrefix("http://") || trimmedEndpoint.lowercased().hasPrefix("https://") {
                jamfURLQuery = trimmedEndpoint
            } else if trimmedEndpoint.hasPrefix("/") {
                jamfURLQuery = usedServer + trimmedEndpoint
            } else if trimmedEndpoint.hasPrefix("api/") {
                jamfURLQuery = usedServer + "/" + trimmedEndpoint
            } else {
                jamfURLQuery = usedServer + "/JSSResource/" + trimmedEndpoint
            }

            guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.get.stringValue
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else { throw JamfAPIError.http(status) }
            // Save raw JSON for optional display in the UI
            self.lastComputerHistoryRaw = String(data: data, encoding: .utf8)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ComputerHistoryResponse.self, from: data)
            self.computerHistory = decoded.computerHistory
            print("Loaded computer history subset '\(subset)' for id: \(computerID)")
        } catch {
            publishError(error, title: "Failed to load computer history subset")
            throw error
        }
    }

    // Fetch all computers
  func getAllComputers() async throws {
      do {
          struct ComputersResponse: Codable {
              let computers: [Computer]
          }
          let request = APIRequest<ComputersResponse>(endpoint: "computers", method: .get)
          let decoded = try await requestSender.resultFor(apiRequest: request)
          self.computers = decoded.computers
          print("Loaded \(computers.count) computers")
      } catch {
          self.alertTitle = "Failed to load computers"
          self.alertMessage = error.localizedDescription
          self.showAlert = true
          
      }
  }

}
