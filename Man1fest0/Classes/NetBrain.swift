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
    //  #############################################################################
    //  Login and Tokens Confirmations
    //  #############################################################################
    
    @Published var status: String = ""
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
    var resourceAccess = false
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
    
    private let minInterval: TimeInterval
    private var lastRequestDate: Date?
    
    init(minInterval: TimeInterval = 3.0) { // 2 seconds between requests
        self.minInterval = minInterval
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
        print("processDetail Json data as text is:")
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
            separationLine()
            print("getCategories Decoding succeeded")
            
        } catch {
            separationLine()
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
    
    
    
    
    func getBuildings(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/buildings"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
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
    
    
    
    func getAllPackages(server: String) async throws {
        let jamfURLQuery = server + "/JSSResource/packages"
        let url = URL(string: jamfURLQuery)!
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
    
    
    
    func updateScript(server: String, scriptName: String, scriptContent: String, scriptId: String, authToken: String) async throws {
        
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <script>
            <name>\(scriptName)</name>
            <script_contents>\(scriptContent)</script_contents>
        </script>
        """
        
        
        separationLine()
        print("Running func: updateScript")
        print("scriptName is set to:\(scriptName)")
        print("scriptID is set to:\(scriptId)")
        separationLine()
        print("scriptContent is\(scriptContent)")
        
        //        let scriptData = Data(scriptContent.utf8)
        let jamfURLQuery = server + "/JSSResource/scripts/id/" + String(describing: scriptId)
        //        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: URL(string: jamfURLQuery)!)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        request.httpBody = xml.data(using: .utf8)
        
        //
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw JamfAPIError.badResponseCode
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
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Use a resilient request helper which handles rate limiting and transient server errors
        let (data, response) = try await performRequestWithRetries(request: request, maxRetries: 5)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
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
        //        let secondDecodedData = try decoder.decode(PoliciesDetailed.self, from: data)
        
        //        var newCurrentDetailedPolicy: PolicyDetailed = decodedData
        
        self.policyDetailed = decodedData
        
        separationLine()
        print("getDetailedPolicy has run - policy name is:\(self.policyDetailed?.general?.name ?? "")")
        print("Policy Trigger:\t\t\t\t\(self.policyDetailed?.general?.triggerOther ?? "")\n")
        
        //        }
        // On completion add policy to array of detailed policies
        self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
        
        //        self.policyDetailed2? = newCurrentDetailedPolicy
    }
    
    // New helper: perform a URLRequest with retries for 429 and 5xx, exponential backoff + jitter, honoring Retry-After header and minInterval throttling.
    private func performRequestWithRetries(request: URLRequest, maxRetries: Int = 4) async throws -> (Data, URLResponse) {
        var attempt = 0
        var delaySeconds: Double = 1.0
        
        while true {
            // Cooperative cancellation: throw immediately if caller cancelled
            try Task.checkCancellation()
            
            // Enforce minimum interval between requests
            let now = Date()
            if let last = lastRequestDate {
                let elapsed = now.timeIntervalSince(last)
                if elapsed < minInterval {
                    let wait = minInterval - elapsed
                    print("Throttling: waiting \(wait)s before request")
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
            
            // Update lastRequestDate to avoid hammering
            lastRequestDate = Date()
            
            do {
                try Task.checkCancellation()
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                // Success
                if (200...299).contains(statusCode) {
                    return (data, response)
                }
                
                // Retry on rate limiting (429) and server errors (500-510)
                if statusCode == 429 || (500...510).contains(statusCode) {
                    attempt += 1
                    self.currentResponseCode = String(describing: statusCode)

                    if attempt > maxRetries {
                        print("Max retries (\(maxRetries)) reached for status code \(statusCode)")
                        throw JamfAPIError.http(statusCode)
                    }

                    // Respect Retry-After header if present
                    var wait = delaySeconds
                    if let httpResp = response as? HTTPURLResponse {
                        if let retryHeader = httpResp.value(forHTTPHeaderField: "Retry-After") {
                            if let retryValue = Double(retryHeader.trimmingCharacters(in: .whitespaces)) {
                                wait = retryValue
                                print("Server requested Retry-After (seconds): \(wait)s")
                            } else {
                                let df = DateFormatter()
                                df.locale = Locale(identifier: "en_US_POSIX")
                                df.timeZone = TimeZone(secondsFromGMT: 0)
                                df.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss zzz"
                                if let retryDate = df.date(from: retryHeader) {
                                    let interval = retryDate.timeIntervalSinceNow
                                    wait = interval > 0 ? interval : 0
                                    print("Server requested Retry-After (date): retry at \(retryDate) — waiting \(wait)s")
                                } else {
                                    print("Unrecognized Retry-After header: '\(retryHeader)'")
                                }
                            }
                        }
                    }

                    let jitter = Double.random(in: 0..<0.5)
                    let sleepTime = wait + jitter
                    print("Transient HTTP \(statusCode) — retrying in \(sleepTime)s (attempt \(attempt))")
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
                    // Exponential backoff for next round
                    delaySeconds *= 2
                    continue
                }

                // Not a retriable status code — return failure
                self.currentResponseCode = String(describing: statusCode)
                throw JamfAPIError.http(statusCode)

            } catch {
                // If it's a URLError that looks transient, retry up to maxRetries
                if let urlErr = error as? URLError {
                    let transient: [URLError.Code] = [.timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed]
                    if transient.contains(urlErr.code) {
                        attempt += 1
                        if attempt > maxRetries {
                            print("Max retries reached for URLError: \(urlErr)")
                            throw error
                        }
                        let jitter = Double.random(in: 0..<0.5)
                        let sleepTime = delaySeconds + jitter
                        print("Transient URLError \(urlErr) — retrying in \(sleepTime)s (attempt \(attempt))")
                        try Task.checkCancellation()
                        try await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
                        delaySeconds *= 2
                        continue
                    }
                }
                // If cancellation was the reason, rethrow it so callers can handle cancellation
                if (error as? CancellationError) != nil {
                    throw error
                }
                // Non-transient error — rethrow
                throw error
            }
        }
    }

    func getAllPoliciesDetailed(server: String, authToken: String, policies: [Policy]) async {
        separationLine()
        print("Running func: getAllPoliciesDetailed (batched)")
         
         // Limit concurrent requests to a small batch size to avoid rate limiting
         let batchSize = 4
         guard !policies.isEmpty else { return }
         
         for i in stride(from: 0, to: policies.count, by: batchSize) {
             let end = min(i + batchSize, policies.count)
             let batch = Array(policies[i..<end])
             
             await withTaskGroup(of: Void.self) { group in
                 for policy in batch {
                     group.addTask {
                         do {
                             try await self.getDetailedPolicy(server: server, authToken: authToken, policyID: String(describing: policy.jamfId ?? 1))
                         } catch {
                             // Log the error but continue with other policies in the batch
                             separationLine()
                             print("Failed to fetch detailed policy \(policy.name) id:\(String(describing: policy.jamfId)) — error: \(error)")
                         }
                     }
                 }
                 // Wait for the batch to complete
                 for await _ in group { }
             }
             // Small pause between batches to be extra-safe
             try? await Task.sleep(nanoseconds: UInt64( (minInterval) * 1_000_000_000 ))
         }
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
              Task {
                  try await requestDelete(url: url, authToken: authToken, resourceType: resourceType)
              }
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
        Task {
                  try await requestDelete(url: url, authToken: authToken, resourceType: resourceType)
              }
              appendStatus("Connecting to \(url)...")
              
              print("deleteComputer has finished")
              print("Set processingComplete to true")
              self.processingComplete = true
              print(String(describing: self.processingComplete))
          }
      }
    
    
    func appendStatus(_ string: String) {
        doubleSeparationLine()
        print("Appending status")
        DispatchQueue.main.async { // need to modify status on the main queue
            self.status += string
            self.status = "Connected"
            self.status += "\n\n"
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
    Task {
                  try await requestDelete(url: url, authToken: authToken, resourceType: resourceType)
              }
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
        Task {
                  try await requestDelete(url: url, authToken: authToken, resourceType: resourceType)
              }
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
          
        separationLine()
          print("Running: batchDeleteScripts")
          print("selection is: \(selection)")

          for eachItem in selection {
            separationLine()
  //            print("Items as Dictionary is \(eachItem)")
              let scriptID = String(describing:eachItem.jamfId)
              print("Current scriptID is:\(scriptID)")
              print("Running: deleteScriptAlt")
              print("resourceType is: \(resourceType)")
              
  //            self.deleteScriptAlt(server: server, resourceType: resourceType, itemID: scriptID, authToken: authToken )
              
              Task {
                  try await self.deleteScript(server: server, resourceType: resourceType, itemID: scriptID, authToken: authToken )
              }
          }
          separationLine()
          print("Finished - batchDeleteScripts")

      }
      
      func deleteGroup(server: String,resourceType: ResourceType, itemID: String, authToken: String)  async throws {
          let resourcePath = getURLFormat(data: (resourceType))
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
      
    func requestDelete(url: URL, authToken: String, resourceType: ResourceType) async throws  {
        
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
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            self.hasError = true
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("requestDelete Status code is:\(statusCode)")
            throw JamfAPIError.http(statusCode)
        }
        print("requestDelete has finished successfully")
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
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            self.hasError = true
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
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
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            self.hasError = true
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
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
                
                self.hasError = true
                //                self.appendStatus(text)
            }
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            self.currentResponseCode = String(describing: statusCode)
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
        
        //        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
        //            if let (data, response) = try await URLSession.shared.data(for: request)
        //                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        //                print("Code not 200")
        //                self.hasError = true
        //
        //                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        //                self.currentResponseCode = String(describing: statusCode)
        //                print("getComputerExtAttributes Status code is:\(statusCode)")
        //                throw JamfAPIError.http(statusCode)
        //            }
    }
//}
//        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let data = data, let response = response {
//                print("Doing processing of sendRequestAsXML:\(httpMethod)")
//                print("Data is:\(data)")
//                print("Data is:\(response)")
//                return response
//
//            } else {
//                print("Error encountered")
//                var text = "\n\nFailed."
//                if let error = error {
//                    text += " \(error)."
//                }
//                //                self.appendStatus(text)
//                print(text)
//            }
//        }
//        dataTask.resume()
//    }
    
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
        
        
        //        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
        //            if let (data, response) = try await URLSession.shared.data(for: request)
        //                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        //                print("Code not 200")
        //                self.hasError = true
        //
        //                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        //                self.currentResponseCode = String(describing: statusCode)
        //                print("getComputerExtAttributes Status code is:\(statusCode)")
        //                throw JamfAPIError.http(statusCode)
        //            }
        //    }
    }
    
    
}
