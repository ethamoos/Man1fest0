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
    @Published var needsCredentials: Bool = false
    @Published var connected: Bool = false
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

    // Cross-controller weak references (set by App init to avoid retain cycles)
    weak var xmlController: XmlBrain? = nil

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

    // Provide lowercase alias used by Views for historical reasons
    @Published var osxConfigProfileDetailed: OSXConfigProfileDetailed? = nil

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
    @Published var isLoading: Bool = false

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
    // Track whether detailed policy fetching is in progress (used by several views)
    @Published var isFetchingDetailedPolicies: Bool = false
    // Store failed detailed policy fetch IDs so UI can show counts and retry options
    @Published var retryFailedDetailedPolicyCalls: [String] = []
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
    // (duplicate declarations removed; canonical @Published properties are declared above)
    // Store failed policy IDs so callers can inspect and retry if needed (single declaration above)

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
        // The Jamf API wraps department arrays in an object; decode into the `Departments` wrapper and extract the array.
        do {
            let decoded = try decoder.decode(Departments.self, from: data)
            DispatchQueue.main.async { self.departments = decoded.department }
        } catch {
            // Fallback: some endpoints may return a bare array; try decode that as well for resilience.
            do {
                let arr = try decoder.decode([Department].self, from: data)
                DispatchQueue.main.async { self.departments = arr }
            } catch {
                print("getDepartments decoding failed: \(error)")
                throw error
            }
        }
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
        // The Jamf API wraps department arrays in an object; decode into the `Departments` wrapper and extract the array.
        do {
            let decoded = try decoder.decode(Departments.self, from: data)
            DispatchQueue.main.async { self.departments = decoded.department }
        } catch {
            // Fallback: some endpoints may return a bare array; try decode that as well for resilience.
            do {
                let arr = try decoder.decode([Department].self, from: data)
                DispatchQueue.main.async { self.departments = arr }
            } catch {
                print("getDepartments decoding failed: \(error)")
                throw error
            }
        }
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
    func getAllScripts(server: String, authToken: String) async throws {

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
                let allScriptResults = try decoder.decode(ScriptResults.self, from: data)
                let localScriptsDetailed = allScriptResults.results

                print("localScriptsDetailed status is set to:\(localScriptsDetailed)")
//                let allScriptsFullyDetailed = self.allScriptsVeryDetailed.results

    }
    
//    func getDetailedScript(server: String, scriptID: Int, authToken: String) async throws {
//
//        separationLine()
//        print("Running func: getDetailedScript")
//        print("scriptID is set to:\(scriptID)")
//
//        let jamfURLQuery = server + "/api/v1/scripts/" + String(describing: scriptID)
//        self.currentURL = jamfURLQuery
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
//            print("Code not 200")
//            throw JamfAPIError.badResponseCode
//        }
//
//        let decoder = JSONDecoder()
//        scriptDetailed = try decoder.decode(Script.self, from: data)
//        //        print("scriptDetailed is set to:\(scriptDetailed)")
//    }
//
//
//    func updateScript(server: String, scriptName: String, scriptContent: String, scriptId: String, authToken: String,category: String,filename: String,info: String, notes: String) async throws {
//
//    // Helper: escape XML reserved characters for element content
//    func escapeXML(_ s: String) -> String {
//        var out = s
//        out = out.replacingOccurrences(of: "&", with: "&amp;")
//        out = out.replacingOccurrences(of: "<", with: "&lt;")
//        out = out.replacingOccurrences(of: ">", with: "&gt;")
//        out = out.replacingOccurrences(of: "\'", with: "&apos;")
//        out = out.replacingOccurrences(of: "\"", with: "&quot;")
//        return out
//    }
//
//    // Ensure any occurrence of the CDATA terminator inside the script is safely handled
//    let safeScriptContent = scriptContent.replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>")
//
//    let xml = """
//    <?xml version="1.0" encoding="utf-8"?>
//    <script>
//        <name>
//        \(escapeXML(scriptName))
//        </name>
//        <category>\(escapeXML(category.isEmpty ? "No category assigned" : category))</category>
//        <filename>\(escapeXML(filename))</filename>
//        <info>\(escapeXML(info))</info>
//        <notes>\(escapeXML(notes))</notes>
//        <script_contents><![CDATA[\(safeScriptContent)]]></script_contents>
//    </script>
//    """
//
//    separationLine()
//    print("Running func: updateScript")
//    print("scriptName is set to:\(scriptName)")
//    print("scriptID is set to:\(scriptId)")
//
//    let jamfURLQuery = server + "/JSSResource/scripts/id/" + String(describing: scriptId)
//    self.currentURL = jamfURLQuery
//    guard let url = URL(string: jamfURLQuery) else {
//        print("Invalid URL for updateScript: \(jamfURLQuery)")
//        throw JamfAPIError.badURL
//    }
//    var request = URLRequest(url: url)
//    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//    request.addValue("application/xml", forHTTPHeaderField: "Accept")
//    request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
//    // Provide a helpful User-Agent (matches other requests)
//    request.addValue("\(String(describing: product_name ?? "Man1fest0"))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
//    request.httpMethod = "PUT"
//    request.httpBody = xml.data(using: .utf8)
//
//    do {
//        let (data, response) = try await URLSession.shared.data(for: request)
//        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
//        self.separationLine()
//        print("updateScript response status: \(status)")
//        if status == 200 || status == 201 {
//            print("updateScript succeeded for id: \(scriptId)")
//            // Optionally refresh the detailed script cache
//            Task {
//                try? await self.getDetailedScript(server: server, scriptID: Int(scriptId) ?? 0, authToken: authToken)
//            }
//            return
//        } else {
//            // Try to show the server response for debugging
//            if let body = String(data: data, encoding: .utf8) {
//                print("updateScript failed - response body:\n\(body)")
//            } else {
//                print("updateScript failed - no response body available")
//            }
//            print("updateScript failed - HTTP status: \(status)")
//            throw JamfAPIError.http(status)
//        }
//    } catch let urlError as URLError {
//        print("updateScript network request failed: \(urlError)")
//        throw JamfAPIError.requestFailed
//    } catch {
//        print("updateScript unexpected error: \(error)")
//        throw JamfAPIError.unknown
//    }
//}
    
    
    
    
    
    
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
//
//        // Rate limiting: ensure at least `policyRequestDelay` seconds between calls
//        let now = Date()
//        if let last = lastRequestDate {
//            let elapsed = now.timeIntervalSince(last)
//            if elapsed < policyRequestDelay {
//                let delay = policyRequestDelay - elapsed
//                if self.debug_enabled { print("Throttling detailed policy request: sleeping \(delay) seconds") }
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
//        let decoder = JSONDecoder()
//        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
//
//        DispatchQueue.main.async {
//            // Insert at front to match previous behavior
//            self.policyDetailed = decodedData
//            self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
//            if let g = self.policyDetailed?.general {
//                self.allPoliciesDetailedGeneral.insert(g, at: 0)
//            }
//        }
//    }

    // Fetch detailed policies for an array of basic policies. This runs sequentially and respects `policyRequestDelay`.
    func getAllPoliciesDetailed(server: String, authToken: String, policies: [Policy]) async throws {
        // Avoid concurrent runs
        if isFetchingDetailedPolicies { return }
        isFetchingDetailedPolicies = true
        defer { isFetchingDetailedPolicies = false }

        print("getAllPoliciesDetailed starting for \(policies.count) policies")

        // If policies is empty, nothing to do
        guard !policies.isEmpty else { return }

        for p in policies {
            // Prefer jamfId if present
            let id = String(describing: p.jamfId ?? 0)
            do {
                try await getDetailedPolicy(server: server, authToken: authToken, policyID: id)
            } catch {
                // Record failures for later retry
                print("getDetailedPolicy failed for id=\(id): \(error)")
                DispatchQueue.main.async {
                    self.retryFailedDetailedPolicyCalls.append(id)
                }
            }
        }
    }
}

extension NetBrain {
    // Fetch a single detailed policy and append to `allPoliciesDetailed`
    func getDetailedPolicy(server: String, authToken: String, policyID: String) async throws {
        if self.debug_enabled { print("Running getDetailedPolicy - policyID is:\(policyID)") }
        let jamfURLQuery = server + "/JSSResource/policies/id/" + policyID
        guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Rate limiting: ensure at least `policyRequestDelay` seconds between calls
        let now = Date()
        if let last = lastRequestDate {
            let elapsed = now.timeIntervalSince(last)
            if elapsed < policyRequestDelay {
                let delay = policyRequestDelay - elapsed
                if self.debug_enabled { print("Throttling detailed policy request: sleeping \(delay) seconds") }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestDate = Date()

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("getDetailedPolicy request error - code is:\(statusCode)")
            throw JamfAPIError.http(statusCode)
        }

        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy

        DispatchQueue.main.async {
            // Keep behavior consistent with previous code: insert at front
            self.policyDetailed = decodedData
            self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
            if let g = self.policyDetailed?.general {
                self.allPoliciesDetailedGeneral.insert(g, at: 0)
            }
        }
    }
}

extension NetBrain {
    func separationLine() {
        print("----------------------------------------------------")
    }

    func appendStatus(_ text: String) {
        DispatchQueue.main.async {
            self.status = (self.status.isEmpty ? "" : self.status + "\n") + text
            print("Status: \(text)")
        }
    }

    // Centralized error publication helper used across NetBrain
    func publishError(_ error: Error, title: String = "Error") {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async {
            self.showAlert = true
            self.alertTitle = title
            // Prefer localizedDescription when available
            self.alertMessage = (error as NSError).localizedDescription
            self.hasError = true
            // Also append to the general status log so it is visible in consoles
            self.status = (self.status.isEmpty ? "" : self.status + "\n") + "\(title): \(self.alertMessage)"
        }
        print("publishError - \(title): \(error)")
    }

    // Acquire a Jamf auth token and set local state
    func getToken(server: String, username: String, password: String) async throws -> JamfAuthToken {
        let token = try await JamfAuthToken.get(server: server, username: username, password: password)
        DispatchQueue.main.async {
            self.authToken = token.token
            // parse expiry if present
            if let expiresDate = ISO8601DateFormatter().date(from: token.expires) {
                self.tokenExpirationTime = expiresDate
            }
            self.tokenComplete = true
        }
        return token
    }

    // Perform a conservative set of loads used by older callers of connect()/load()
    func load() async {
        print("NetBrain.load() called")
        // Ensure token exists for endpoints that require it
        if self.authToken.isEmpty, !self.username.isEmpty && !self.password.isEmpty {
            do { _ = try await getToken(server: server, username: username, password: password) }
            catch { print("load(): failed to acquire token: \(error)") }
        }

        // Run non-critical fetches; ignore individual failures to keep UI responsive
        try? await self.getCategories(server: server, authToken: self.authToken)
        try? await self.getDepartments(server: server)
        // Scripts use the v1 API and may require an auth token
        try? await self.getAllScripts(server: server, authToken: self.authToken)

        DispatchQueue.main.async {
            self.initialDataLoaded = true
        }
    }
}

extension NetBrain {
    func deletePackage(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        guard let base = URL(string: server) else { return }
        let resourcePath = getURLFormat(data: resourceType)
        let url = base.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
        Task {
            try? await requestDeleteAwait(url: url, authToken: authToken, resourceType: resourceType)
        }
    }

    func deletePolicy(server: String, resourceType: ResourceType, itemID: String, authToken: String) {
        guard let base = URL(string: server) else { return }
        let resourcePath = getURLFormat(data: resourceType)
        let url = base.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
        Task {
            try? await requestDeleteAwait(url: url, authToken: authToken, resourceType: resourceType)
        }
    }

    func deleteComputer(server: String, authToken: String, resourceType: ResourceType, itemID: String) {
        guard let base = URL(string: server) else { return }
        let resourcePath = getURLFormat(data: resourceType)
        let url = base.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
        Task {
            try? await requestDeleteAwait(url: url, authToken: authToken, resourceType: resourceType)
        }
    }
}

extension NetBrain {
    func getBuildings(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/buildings"
        guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getBuildings")
        print("url is set to:\(url)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        let allBuildings = try decoder.decode(Buildings.self, from: data)
        DispatchQueue.main.async { self.buildings = allBuildings.buildings }
    }

    func getAllPackages(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/packages"
        guard let url = URL(string: jamfURLQuery) else { throw JamfAPIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getAllPackages")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
        }
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Packages.self, from: data)
        DispatchQueue.main.async {
            self.allPackages = decoded.packages
            self.allPackagesComplete = true
        }
    }
}

extension NetBrain {
    /// Compatibility: original connect(server:resourceType:authToken:) used throughout the Views.
    /// This synchronous wrapper launches appropriate async fetches in the background.
    func connect(server: String, resourceType: ResourceType, authToken: String) {
        print("NetBrain.connect(server:\(server), resourceType:\(resourceType), authTokenPresent=\(!authToken.isEmpty))")
        // Ensure we have an auth token if required
        if authToken.isEmpty {
            // Attempt to refresh token silently if credentials are present
            if !username.isEmpty && !password.isEmpty {
                Task {
                    do { _ = try await getToken(server: server, username: username, password: password) }
                    catch { print("connect: failed to refresh token: \(error)") }
                }
            }
        }

        switch resourceType {
        case .category:
            Task { try? await getCategories(server: server, authToken: authToken) }
        case .department:
            Task { try? await getDepartments(server: server) }
        case .packages, .package:
            Task { try? await getAllPackages(server: server, authToken: authToken) }
        case .policies, .policy:
            Task { try? await getAllPolicies(server: server, authToken: authToken) }
        case .script, .scripts:
            Task { try? await getAllScripts(server: server, authToken: authToken) }
        case .computerBasic:
            Task { try? await getComputersBasic(server: server, authToken: authToken) }
        default:
            // Fallback: perform a conservative load
            Task {
                try? await getCategories(server: server, authToken: authToken)
                try? await getDepartments(server: server)
            }
        }
    }

    /// Parameterless connect() used by older Views: obtain token if needed and perform conservative loads.
    func connect() async {
        print("NetBrain.connect() called (parameterless)")
        // If no auth token, try to get one using stored username/password
        if authToken.isEmpty {
            if !username.isEmpty && !password.isEmpty {
                do {
                    _ = try await getToken(server: server, username: username, password: password)
                } catch {
                    print("connect() failed to get token: \(error)")
                }
            }
        }

        // Run a conservative set of fetches to populate common caches
        await load()
    }
}

extension NetBrain {
    /// Perform an HTTP DELETE on the provided URL using Bearer auth and return when complete.
    /// Centralized helper to be used by deletePackage/deletePolicy/deleteComputer wrappers.
    func requestDeleteAwait(url: URL, authToken: String, resourceType: ResourceType) async throws {
        if self.debug_enabled { print("requestDeleteAwait: deleting \(url.absoluteString) for resource \(resourceType)") }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if !authToken.isEmpty {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else if !self.authToken.isEmpty {
            request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("\(String(describing: product_name ?? "Man1fest0"))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if self.debug_enabled { print("requestDeleteAwait HTTP status: \(status)") }
            switch status {
            case 200, 202, 204:
                appendStatus("Deleted resource at \(url.path) (status: \(status))")
                return
            case 401:
                // Try token refreshing once if credentials are available
                if !username.isEmpty && !password.isEmpty {
                    do {
                        _ = try await getToken(server: server, username: username, password: password)
                        // retry once
                        var retryReq = URLRequest(url: url)
                        retryReq.httpMethod = "DELETE"
                        retryReq.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
                        retryReq.addValue("application/json", forHTTPHeaderField: "Accept")
                        let (_, retryResponse) = try await URLSession.shared.data(for: retryReq)
                        let retryStatus = (retryResponse as? HTTPURLResponse)?.statusCode ?? 0
                        if retryStatus == 200 || retryStatus == 204 || retryStatus == 202 {
                            appendStatus("Deleted resource at \(url.path) after token refresh (status: \(retryStatus))")
                            return
                        }
                        throw JamfAPIError.http(retryStatus)
                    } catch {
                        appendStatus("Failed to delete resource (401) and token refresh failed: \(error)")
                        throw error
                    }
                }
                throw JamfAPIError.http(status)
            default:
                appendStatus("Delete failed (status: \(status)) for \(url.path)")
                throw JamfAPIError.http(status)
            }
        } catch {
            appendStatus("Network delete error: \(error)")
            throw error
        }
    }
}

extension NetBrain {
    // Process deletion for basic computer selections (IDs set<ComputerBasicRecord.ID>)
    func processDeleteComputersBasic(selection: Set<Int>, server: String, authToken: String, resourceType: ResourceType) {
        // selection contains basic computer IDs which map to computer id strings for deletion
        appendStatus("processDeleteComputersBasic: received \(selection.count) items")
        Task {
            for id in selection {
                // convert to string and call deleteComputer
                let itemID = String(describing: id)
                deleteComputer(server: server, authToken: authToken, resourceType: resourceType, itemID: itemID)
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms pacing
            }
            DispatchQueue.main.async {
                self.appendStatus("processDeleteComputersBasic: deletion tasks queued for \(selection.count) items")
                self.processingComplete = true
            }
        }
    }

    // Process delete for packages (selection of Package IDs)
    func processDeletePackages(selection: Set<Int>, server: String, resourceType: ResourceType, authToken: String) {
        appendStatus("processDeletePackages: received \(selection.count) items")
        Task {
            for id in selection {
                let itemID = String(describing: id)
                deletePackage(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async {
                self.appendStatus("processDeletePackages: queued deletion for \(selection.count) packages")
                self.processingComplete = true
            }
        }
    }

    // Generic process delete for full Computer objects
    func processDeleteComputers(selection: Set<Computer>, server: String, authToken: String, resourceType: ResourceType) {
        appendStatus("processDeleteComputers: received \(selection.count) items")
        Task {
            for comp in selection {
                let itemID = String(describing: comp.id)
                deleteComputer(server: server, authToken: authToken, resourceType: resourceType, itemID: itemID)
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async {
                self.appendStatus("processDeleteComputers: queued deletion for \(selection.count) computers")
                self.processingComplete = true
            }
        }
    }

    // Process deletion for policies selection of Ints
    func processDeletePoliciesGeneral(selection: Set<Int>, server: String, authToken: String, resourceType: ResourceType) {
        appendStatus("processDeletePoliciesGeneral: received \(selection.count) items")
        Task {
            for id in selection {
                let itemID = String(describing: id)
                deletePolicy(server: server, resourceType: resourceType, itemID: itemID, authToken: authToken)
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async {
                self.appendStatus("processDeletePoliciesGeneral: queued deletion for \(selection.count) policies")
                self.processingComplete = true
            }
        }
    }

    // Update selected basic computers' name
    func processUpdateComputerName(selection: Set<Int>, server: String, authToken: String, resourceType: ResourceType, computerName: String) {
        appendStatus("processUpdateComputerName: updating name for \(selection.count) items to \(computerName)")
        Task {
            for id in selection {
                let itemID = String(describing: id)
                // Construct a JSON payload for computer name update (Jamf specifics may vary)
                let jamfURLQuery = server + "/JSSResource/computers/id/" + itemID
                guard let url = URL(string: jamfURLQuery) else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let body: [String: Any] = ["computer": ["general": ["name": computerName]]]
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                    let (_, response) = try await URLSession.shared.data(for: request)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    appendStatus("Updated computer id:\(itemID) status:\(status)")
                } catch {
                    appendStatus("Failed to update computer id:\(itemID) error:\(error)")
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async {
                self.appendStatus("processUpdateComputerName: completed for \(selection.count) items")
                self.processingComplete = true
            }
        }
    }

    // Update department for basic computers
    func processUpdateComputerDepartmentBasic(selection: Set<Int>, server: String, authToken: String, resourceType: ResourceType, department: String) {
        appendStatus("processUpdateComputerDepartmentBasic: updating department to \(department) for \(selection.count) items")
        Task {
            for id in selection {
                let itemID = String(describing: id)
                let jamfURLQuery = server + "/JSSResource/computers/id/" + itemID
                guard let url = URL(string: jamfURLQuery) else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let body: [String: Any] = ["computer": ["general": ["department": department]]]
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                    let (_, response) = try await URLSession.shared.data(for: request)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    appendStatus("Updated department for computer id:\(itemID) status:\(status)")
                } catch {
                    appendStatus("Failed to update department for computer id:\(itemID) error:\(error)")
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            DispatchQueue.main.async {
                self.appendStatus("processUpdateComputerDepartmentBasic: completed for \(selection.count) items")
                self.processingComplete = true
            }
        }
    }
}
