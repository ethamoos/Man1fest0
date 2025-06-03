
import Foundation
import SwiftUI
import AEXML


@MainActor class NetBrain: ObservableObject {
    
    // #########################################################################
    // Global Variables
    // #########################################################################
    
    //    #################################################################################
    //    DEBUG STATUS
    //    #################################################################################

        @State var debugStatus = false
    
    // #########################################################################
    //  Build identifiers
    // #########################################################################
        
        let product_name = Bundle.main.infoDictionary!["CFBundleName"] as? String
        let product_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let build_version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    //    let buildString = "Version: \(appVersion ?? "").\(build ?? "")"
    
    //    #################################################################################
    //    ############ Login
    //    #################################################################################
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    
    //    #################################################################################
    //    ############ Login and Tokens Confirmations
    //    #################################################################################
    
    @Published var status: String = ""
    var tokenComplete: Bool = false
    var tokenStatusCode: Int = 0
    var authToken = ""
    var encoded = ""
    var initialDataLoaded = false
    
    //    #################################################################################
    //    Alerts
    //    #################################################################################

    @Published var showAlert = false
    var alertMessage = ""
    var alertTitle = ""
    var showActivity = false

    //    #################################################################################
    //    Error Codes
    //    #################################################################################

    @State var currentResponseCode: String = ""
    var hasError = false
    
    //    #################################################################################
    //    ############ Screen Access
    //    #################################################################################
    
    var showLoginScreen = true
    var allComputersComplete = false
    var allPoliciesComplete = false
    var allPackagesComplete = false
    var allPoliciesStatusCode: Int = 0
    var resourceAccess = false
    @Published var showingWarning = false
    
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
    
    //    #################################################################################
    //    ############ Packages
    //    #################################################################################
    
    @Published var currentPackages: [Package] = []
    @Published var allPackagesAssignedToAPolicyGlobal: [Package?] = []
    @Published var packages: [Package] = []
    @Published var packagesAssignedToPolicy: [ Package ] = []
    @Published var allPackages: [Package] = []
    @Published var packageDetailed: PackageDetailed? = PackageDetailed(id: 0, name: "", category: "", filename: "" , info: "", notes: "", priority: 0, rebootRequired: false,fillUserTemplate: false, fillExistingUsers: false, allowUninstalled: false,
                                                                       osRequirements: "", requiredProcessor: "", hashType: "", hashValue: "", switchWithPackage: "",
                                                                       installIfReportedAvailable: "", reinstallOption: "", sendNotification: false  )
    
    //    #################################################################################
    //    ############ Policies
    //    #################################################################################
    
    @Published var policies: [Policy] = []
    @Published var fetchedDetailedPolicies: Bool = false
    @Published var currentPolicyID: Int = 0
    @Published var currentPolicyName: String = ""
    @Published var currentPolicyIDIString: String = ""
    
    @Published var allPolicies: PolicyBasic? = nil
    @Published var allPoliciesConverted: [Policy] = []
    @Published var currentDetailedPolicy: PoliciesDetailed? = nil
    @Published var policyDetailed: PolicyDetailed? = nil
    @Published var allPoliciesDetailed: [PolicyDetailed?] = []
    @Published var allPoliciesDetailedGeneral: [General] = []
    
    var singlePolicyDetailedGeneral: General? = nil
    
    //    #################################################################################
    //    XML data
    //    #################################################################################
    
    @Published var xmlDoc: AEXMLDocument = AEXMLDocument()
    @Published var computerGroupMembersXML: String = ""
    @Published var currentPolicyAsXML: String = ""
    @Published var updateXML: Bool = false
    
    //    #################################################################################
    //    ############ Scripts
    //    #################################################################################
    
    @Published var scripts: [ScriptClassic] = []
    //    @Published var ScriptResults: ScriptResults = ScriptResults(totalCount: 0, results: Script(id: "", name: "", info: "", notes: "", priority: Script.Priority(rawValue: "") ?? .after, parameter4: "", parameter5: "", parameter6: "", parameter7: "", parameter8: "", parameter9: "", parameter10: "", parameter11: "", osRequirements: "", scriptContents: "", categoryId: "", categoryName: ""))
    @Published var allScripts: [ScriptClassic] = []
    @Published var allScriptsVeryDetailed: [Scripts] = []
    @Published var allScriptsDetailed: [Script] = []
    @Published var scriptDetailed: Script = Script(id: "")
    @Published var allPolicyScripts: [PolicyScripts] = []
    
    //    #################################################################################
    //    ############ Category
    //    #################################################################################
    
    @Published var category: [Category] = []
    @Published var categories: [Category] = []
    
    //    #################################################################################
    //    ############ Buildings
    //    #################################################################################
    
    @Published var buildings: [Building] = []
    
    //    #################################################################################
    //    ############ Config Profiles
    //    #################################################################################
    
    @Published var allConfigProfiles: ConfigurationProfiles = ConfigurationProfiles()
    
    //    #################################################################################
    //    ############ Department
    //    #################################################################################
    
    @Published var department: [Department] = []
    @Published var departments: [Department] = []
    
    //    #################################################################################
    //    Icons
    //    #################################################################################
    
    @Published var allIconsDetailed: [Icon?] = [Icon(id: 0, url: "", name: "")]
    @Published var iconDetailed: Icon = Icon(id: 0, url: "", name: "")
    
    //    #################################################################################
    //    ############ SELECTIONS
    //    #################################################################################
    
    @Published var selectedSimpleComputer: Computer = Computer(id: 0, name: "")
    @Published var selectedCategory: Category = Category(jamfId: 0, name: "")
    //    @Published var computerGroupSelection: ComputerGroup = ComputerGroup(id: 0, name: "", isSmart: false name: "")
    
    //    #################################################################################
    //    ############ BOOLEAN - TOGGLES
    //    #################################################################################
    
    //    @Published var enableDisable: Bool = true
    //    @State var currentSelection: Category = Category(jamfId: 0, name: "")
    
    //    #################################################################################
    //    ############ Process lists - for batch operations
    //    #################################################################################
    
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
    //    Functions
    //    #################################################################################
    

    
    func getComputersBasic(server: String, authToken: String) async throws {
        self.separationLine()
        print("Running getComputersBasic")
        let jamfURLQuery = server + "/JSSResource/computers/subset/basic"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
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
            throw NetError.badResponseCode
        }
        //        DEBUG
        //        separationLine()
        //        print("getAllGroups - processDetail Json data as text is:")
        //        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.allComputerGroups = try decoder.decode(Man1fest0.allComputerGroups.self, from: data).computerGroups
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
            throw NetError.badResponseCode
        }
        
        //        DEBUG
        if self.debugStatus == true {
            separationLine()
            print("processDetail getGroupMembers Json data as text is:")
            print(String(data: data, encoding: .utf8)!)
        }
        
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
            throw NetError.badResponseCode
        }
        separationLine()
        print("getDepartmentScope - processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.departments = try decoder.decode([Department].self, from: data)

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
            throw NetError.badResponseCode
        }
        separationLine()
        print("processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.categories = try decoder.decode([Category].self, from: data)
    }
    
    func getCategories(server: String) async throws {
        
        let jamfURLQuery = server + "/JSSResource/categories"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
          request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
  
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getCategories")
        print("jamfURLQuery is: \(jamfURLQuery)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw NetError.badResponseCode
        }
        separationLine()
        print("processDetail Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        self.categories = try decoder.decode([Category].self, from: data)
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
            throw NetError.badResponseCode
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
            throw NetError.badResponseCode
        }
        let decoder = JSONDecoder()
        print("Decoding without array - using ConfigurationProfiles")
        self.allConfigProfiles = try decoder.decode(ConfigurationProfiles.self, from: data)
    }
    
    //    #################################################################################
    //    FUNCTIONS
    //    #################################################################################
    
    func getPackagesAssignedToPolicy() {
        
        if let detailed = self.currentDetailedPolicy {
            if let policyPackages = detailed.policy.package_configuration?.packages {
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
            print("No detailed policy response yet")
        }
    }
    
    
    func getDetailedPackage(server: String, authToken: String, packageID: String) async throws {
        print("Running getDetailedPackage - packageID is:\(packageID)")
        let jamfURLQuery = server + "/JSSResource/packages/id/" + packageID
        print("jamfURLQuery is:\(jamfURLQuery)")
        let url = URL(string: jamfURLQuery)!
        print("url is:\(url)")
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
            print("Code not 200 - Response is:\(String(describing: responseCode))")
            throw NetError.badResponseCode
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
            print("Running delete policy function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            requestDelete(url: url, authToken: authToken, resourceType: resourceType)
            appendStatus("Connecting to \(url)...")
            
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
    
    
    //    #################################################################################
    //    Tokens and Authorisation
    //    #################################################################################
    
    func getToken(server: String, username: String, password: String) async throws -> JamfAuthToken {
        
        print("Getting token - Netbrain")
        guard let base64 = encodeBase64(username: username, password: password) else {
            print("Error encoding username/password")
            throw NetError.couldntEncodeNamePass
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
        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            throw JamfAPIError.requestFailed
        }
        
        // check the response code
        self.tokenStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        if self.tokenStatusCode != 200 {
            
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
        self.authToken = auth.token
        return auth
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
    
    
    func connectDetailed(server: String, authToken: String, resourceType: ResourceType, itemID: Int) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let itemIDString = String(itemID)
        
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
            asteriskSeparationLine()
            doubleSeparationLine()
            print("Running connectDetailed function")
            print("URL is set as:\n\(url)")
            print("resourceType is set as:\(resourceType)")
            detailedRequest(url: url, resourceType: resourceType, authToken: authToken)
            appendStatus("Connecting to \(url)...")
        }
    }
    
    
    func handleConnect(server: String, authToken: String,resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        self.connect(server: server,resourceType: resourceType, authToken: authToken)
    }
    
    
    //    #################################################################################
    //    Request functions
    //    #################################################################################
    
    
    func detailedRequest(url: URL,resourceType: ResourceType, authToken: String) {
        
        asteriskSeparationLine()
        print("Running detailedRequest function - resourceType is set as:\(resourceType)")
        print("URL is set as:\n\(url)")
        let headers = [
            "Accept": "application/json",
            "Authorization": "Bearer \(self.authToken)"
        ]
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                //                self.separationLine()
                //                self.doubleSeparationLine()
                print("Data returned - processing detailed request")
                
                DispatchQueue.main.async {
                    
                    self.processPolicyDetail(data: data, response: response, resourceType: resourceType)
                    
                }
                            
            } else {
                
                var text = "\n\nDetailed Request Failed."
                print(text)
                print("Request is:")
                //                print(request)
                if let error = error {
                    text += " \(error)."
                }
                DispatchQueue.main.async {
                    self.appendStatus(text)
                }
            }
        }
        dataTask.resume()
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
    
    func receivedPolicyDetail(policyDetailed: PoliciesDetailed) {
        DispatchQueue.main.async {
            self.currentDetailedPolicy = policyDetailed
            // self.status = "Computers retrieved"
            //        self.status = ""
            print("Adding:policyDetailed to: allPoliciesDetailed ")
            self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
            
        }
    }
    
    
    //    #################################################################################
    //    BATCH PROCESSING
    //    #################################################################################
    
    
    //
    //    func batchProcessComputers(computers: [Computers]) {
    //        print("Running: batchProcessComputers")
    //        //        DEBUG
    //        //        print("Doing thing to computer:\(computers)")
    //    }
    //
    //
    //    func batchProcessPackages(packages: [Packages]) {
    //        print("Doing thing to packages:\(packages)")
    //    }
    //
    
    func addExistingPackages() {
        
        if let detailed = self.currentDetailedPolicy {
            if let policyPackages = detailed.policy.package_configuration?.packages {
                self.separationLine()
                print("Adding currently assigned packages to packagesAssignedToPolicy:")
                for package in policyPackages {
                    self.separationLine()
                    print("Package is:\(package)")
                    packagesAssignedToPolicy.insert(package, at: 0)
                }
            }
        } else {
            self.separationLine()
            print("No detailed policy response yet")
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
            throw NetError.badResponseCode
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
            throw NetError.badResponseCode
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
            throw NetError.badResponseCode
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
    //
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
            throw NetError.badResponseCode
        }

        let decoder = JSONDecoder()
        scriptDetailed = try decoder.decode(Script.self, from: data)
        //        print("scriptDetailed is set to:\(scriptDetailed)")
        
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
            throw NetError.badResponseCode
        }
        
        let decoder = JSONDecoder()
        self.allPolicies = try decoder.decode(PolicyBasic.self, from: data)
        let decodedData = try decoder.decode(PolicyBasic.self, from: data).policies
        self.allPoliciesConverted = decodedData
        allPoliciesComplete = true
        separationLine()
        atSeparationLine()
        print("getAllPolicies status is set to:\(allPoliciesComplete)")
        print("allPolicies status code is:\(String(describing: self.allPoliciesStatusCode))")
        print("allPoliciesConverted count is:\(String(describing: self.allPoliciesConverted.count))")
        
    }
    
    func getDetailedPolicy(server: String, authToken: String, policyID: String) async throws {
        if self.debugStatus == true {
            print("Running getDetailedPolicy - policyID is:\(policyID)")
        }
        let jamfURLQuery = server + "/JSSResource/policies/id/" + policyID
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(String(describing: product_name ?? ""))/\(String(describing: build_version ?? ""))", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            throw NetError.badResponseCode
        }
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(PoliciesDetailed.self, from: data).policy
        self.policyDetailed = decodedData
        
        if self.debugStatus == true {
            separationLine()
            print("getDetailedPolicy has run - policy name is:\(self.policyDetailed?.general?.name ?? "")")
        }
        self.allPoliciesDetailed.insert(self.policyDetailed, at: 0)
    }
    
    func getAllPoliciesDetailed(server: String, authToken: String, policies: [Policy]){
        
        self.separationLine()
        print("Running func: getAllPoliciesDetailed")
        
        for policy in policies {
            
            Task {
                try await getDetailedPolicy(server: server, authToken: authToken, policyID: String(describing: policy.jamfId ?? 1))
                
                if policyDetailed != nil {
                    //                print("Policy is:\(policy.name) - ID is:\(String(describing: policy.jamfId ?? 0))")
                }
            }
        }
    }
    
    
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
    //    run operation - processPoliciesSelected
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
    
    
    func processAllComputers(computers: [Computer],  server: String, resourceType: ResourceType, url: String) {
        
        print("Running processAllComputers")
        for eachItem in computers {
            self.separationLine()
            print("Item is \(eachItem)")
            let computerIDInt = eachItem.id
            print("Current computerID is:\(computerIDInt)")
            print("Adding computer:\(eachItem.name) to list")
            computerProcessList.insert(eachItem, at: 0)
            print("Doing function for item:\(computerIDInt)")
            
            
            //    #################################################################################
            //      run operation - download file
            //    #################################################################################
            
            
            //            self.downloadFileAsync(objectID: String(describing: computerIDInt), resourceType: resourceType, server: server, url: url) { (path, error) in}
        }
    }
    
    
    
    
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
        print("selection is:\(selection)")

        for eachItem in selection {
            separationLine()
            print("Processing items from Dictionary:\(eachItem)")
            let policyID = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.jamfId ?? 0)
            print("Current policyID is:\(policyID)")
            print("Current jamfID is:\(String(describing: jamfID))")
            deletePolicy(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken )
            print("List is:\(packageProcessList)")
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
    //    processComputerDetail
    //    #################################################################################
    
    
    
    func processComputerDetail(data: Data, response: URLResponse, resourceType: ResourceType) {
        
        separationLine()
        print("Running: processComputerDetail")
        
        let decoded = PoliciesDetailReply.decode(data)
        
        
        switch decoded {
        case .success(let policyDetailed):
            receivedPolicyDetail(policyDetailed: policyDetailed)
            //            separationLine()
            //            print("policyDetailed is:\(String(describing: policyDetailed.policy.general?.name ?? nil))")
        case .failure(let error):
            print("Decoding failed - Corrupt data. \(response) \(error)")
            separationLine()
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    
    
    //    #################################################################################
    //    processComputerDetail
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
    //    processPolicyDetail
    //    #################################################################################
    
    
    func processPolicyDetail(data: Data, response: URLResponse, resourceType: ResourceType) {
        
        separationLine()
        print("Running: processPolicyDetail")
        print("ResourceType is:\(String(describing: ResourceType.self))")
        
        let decoded = PoliciesDetailReply.decode(data)
        
        switch decoded {
        case .success(let policyDetailed):
            receivedPolicyDetail(policyDetailed: policyDetailed)
            separationLine()

        case .failure(let error):
            print("Decoding failed - Corrupt data. \(response) \(error)")
            separationLine()
            appendStatus("Corrupt data. \(response) \(error)")
        }
    }
    
    
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
            
            self.connectDetailed(server: server, authToken: authToken, resourceType: resourceType, itemID: Int(policyID) ?? 0)
            
            let newCategoryName: String = self.selectedCategory.name
            let newCategoryID: String = String(describing: self.selectedCategory.jamfId)
            let policyEnDisable: Bool = enableDisable
            
            print("New categoryName is:\(newCategoryName))")
            print("New categoryID is:\(newCategoryID)")
            print("policyEnDisable is:\(policyEnDisable)")
            
            if self.currentDetailedPolicy != nil {
                if let categoryName = self.currentDetailedPolicy?.policy.general?.category?.name {
                    let categoryID = self.currentDetailedPolicy?.policy.general?.category?.jamfId
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
            
            self.connectDetailed(server: server, authToken: authToken, resourceType: resourceType, itemID: policyID ?? 0 )
            
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
            
            self.connectDetailed(server: server, authToken: authToken, resourceType: resourceType, itemID: policyID ?? 0 )
            
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
    
    
    func editPolicy(server: String, authToken: String, resourceType: ResourceType, packageName: String, packageID: String, policyID: Int) {
        
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
                    <action>Install</action>
                    <fut>false</fut>
                    <feu>false</feu>
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
        //        }
        
        else {
            print("Nothing to do")
            
        }
    }
    
    func updateSSName(server: String, authToken: String, resourceType: ResourceType, policyName: String, policyID: String) {
        
        let resourcePath = getURLFormat(data: (resourceType))
        let policyID = policyID
        var xml: String
        self.separationLine()
        print("updateSSName XML")
        print("updateSSName is set as:\(policyName)")
        
        xml = """
                <policy>
                    <self_service>
                        <self_service_display_name>\(policyName)</self_service_display_name>
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
        //        }
        
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
    
    
    //    Update Extension Attribute
    //
    //    var request = URLRequest(url: URL(string: "https://https//testJamfserver.jamfcloud.com/JSSResource/computerextensionattributes/id/{{id}}")!,timeoutInterval: Double.infinity)
    //    request.addValue("application/xml", forHTTPHeaderField: "Accept")
    //    request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
    
    //
    //    request.httpMethod = "PUT"
    //
    //    let task = URLSession.shared.dataTask(with: request) { data, response, error in
    //      guard let data = data else {
    //        print(String(describing: error))
    //        return
    //      }
    //      print(String(data: data, encoding: .utf8)!)
    //    }
    //
    //    task.resume()
    //
    //    var request = URLRequest(url: URL(string: "https://https//testJamfserver.jamfcloud.com/JSSResource/computerextensionattributes/name/{{name}}")!,timeoutInterval: Double.infinity)
    //    request.addValue("application/xml", forHTTPHeaderField: "Accept")
    //    request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
    //
    //    request.httpMethod = "PUT"
    //
    //    let task = URLSession.shared.dataTask(with: request) { data, response, error in
    //      guard let data = data else {
    //        print(String(describing: error))
    //        return
    //      }
    //      print(String(data: data, encoding: .utf8)!)
    //    }
    //
    //    task.resume()
    
    //    <?xml version="1.0" encoding="UTF-8"?>
    //    <user_extension_attribute>
    //        <id>1</id>
    //        <name>username Test EA</name>
    //        <description/>
    //        <data_type>Date</data_type>
    //        <input_type>
    //            <type>Text Field</type>
    //        </input_type>
    //    </user_extension_attribute>
    
    //    <?xml version="1.0" encoding="UTF-8"?>
    //    <computer_extension_attribute>
    //        <id>1</id>
    //        <name>Extension Attribute 1</name>
    //        <description/>
    //        <data_type>String</data_type>
    //        <input_type>
    //            <type>Pop-up Menu</type>
    //            <popup_choices>
    //                <choice>Value 1</choice>
    //                <choice>Value 2</choice>
    //                <choice>Value 3</choice>
    //            </popup_choices>
    //        </input_type>
    //        <inventory_display>General</inventory_display>
    //        <recon_display>Extension Attributes</recon_display>
    //    </computer_extension_attribute>
    //
    
    
    
    
    
    //    ##################################################
    //    addComputerToGroup
    //    ##################################################
    
    
    
//    func addComputerToGroup(xmlContent: String, computerName: String,  computerId: String,groupId: String, resourceType: ResourceType, server: String, authToken: String) {
//        readXMLDataFromString(xmlContent: xmlContent)
//        
//        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
//        let url = URL(string: jamfURLQuery)!
//        self.separationLine()
//        print("Running addComputerToGroup")
//        print("xmlContent is:\(xmlContent)")
//        print("url is:\(url)")
//        print("computerName is:\(computerId)")
//        print("computerId is:\(computerId)")
//        
//        let computers = self.xmlDoc.root["computers"].addChild(name: "computer")
//        computers.addChild(name: "id", value: computerId)
//        computers.addChild(name: "name", value: computerName)
//        print("updatedContent is:\(self.xmlDoc.root.xml)")
//        let jamfCount = computers.count
//        print("jamfCount is:\(jamfCount)")
//        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
//
//    }
    
    
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
                // self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
    //    #################################################################################
    //    removeLastComputer
    //    #################################################################################
    
    
    
    
    func removeLastComputer(xmlContent: String, computerName: String,  computerId: String,groupId: String, resourceType: ResourceType, server: String) {
        readXMLDataFromString(xmlContent: xmlContent)
        
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupId)"
        let url = URL(string: jamfURLQuery)!
        self.separationLine()
        print("Running removeLastComputer")
        print("xmlContent is:\(xmlContent)")
        print("url is:\(url)")
        //        print("computerName is:\(computerId)")
        //        print("computerId is:\(computerId)")
        let computers = self.xmlDoc.root["computers"]
        let lastcomputer = computers["computer"].last!
        lastcomputer.removeFromParent()
        print("updatedContent is:\(self.xmlDoc.root.xml)")
        let jamfCount = computers.count
        print("jamfCount is:\(jamfCount)")
        self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
    }
    
    //    #############################################################################
    //   getGroupMembersXML - getAsXML
    //    #############################################################################
    
    func getGroupMembersXML(server: String, groupId: Int) {
        
        let groupIdString = String(describing: groupId )
        let jamfURLQuery = server + "/JSSResource/computergroups/id/" + "\(groupIdString)"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url,timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        separationLine()
        print("Running: getGroupMembersXML")
        print("groupId set as: \(groupId)")
        print("jamfURLQuery set as: \(jamfURLQuery)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                //                self.separationLine()
                print("getGroupMembersXML failed")
                print(String(describing: error))
                return
            }
            //            self.separationLine()
            print("getGroupMembersXML data is:")
            print(String(data: data, encoding: .utf8)!)
            DispatchQueue.main.async {
                self.computerGroupMembersXML = (String(data: data, encoding: .utf8)!)
            }
        }
        task.resume()
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
        print("Running: networkController.getPolicyAsXML")
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
            //                        print("networkController.getPolicyAsXML data is:")
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
    
    
    func getPolicyAsXMLaSync(server: String, policyID: Int, authToken: String) async throws -> String{
        
        
        let policyIdString = String(describing: policyID )
        let jamfURLQuery = server + "/JSSResource/policies/id/" + "\(policyIdString)"
        let url = URL(string: jamfURLQuery)!
        
        print("Running getPolicyAsXMLaSync - Netbrain")
        print("policyIdString is: \(policyIdString)")

        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running getPolicyAsXMLaSync - policyID is:\(policyID)")
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseCode = (response as? HTTPURLResponse)?.statusCode
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - Response is:\(String(describing: responseCode))")
            throw NetError.badResponseCode
        }
        
        self.currentPolicyAsXML = (String(data: data, encoding: .utf8)!)
        return self.currentPolicyAsXML
    }
    
    func readXMLDataFromString(xmlContent: String) {
        self.separationLine()
        separationLine()
        print("Running readXMLDataFromString - NetBrain")
//        print("xmlContent is:\(xmlContent)")
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
        if selfServiceToggle == false {
            print("Enabling")
            xml = "<policy><self_service><use_for_self_service>true</use_for_self_service></self_service></policy>"
            
            if URL(string: server) != nil {
                if let serverURL = URL(string: server) {
                    let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemIDString)
                    print("Running toggleSelfServiceOnOff policy function - url is set as:\(url)")
                    print("ItemID is set as:\(itemIDString)")
                    print("resourceType is set as:\(resourceType)")
                    //                    // print("xml is set as:\(xml)")
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
                    // print("xml is set as:\(xml)")
                    //            self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
                    self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: xml, httpMethod: "PUT")
                    
                    appendStatus("Connecting to \(url)...")
                }
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
            
            print("Enabling")
            
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
            print("Disabling")
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
    
    
    func createPackageRecord(name: String, server: String,authToken: String) {
        
        print("Running createPackageRecord - updating via xml")
        print("name is set as:\(name)")
//        print("authToken is set as:\n\(authToken)")
        
        let parameters = "<package>\n\t<name>\(name)</name>\n\t<category>Unknown</category>\n\t<filename>\(name)</filename>\n\t<info>string</info>\n\t<notes>string</notes>\n\t<priority>5</priority>\n\t<reboot_required>true</reboot_required>\n\t<fill_user_template>true</fill_user_template>\n\t<fill_existing_users>true</fill_existing_users>\n\t<boot_volume_required>true</boot_volume_required>\n\t<allow_uninstalled>true</allow_uninstalled>\n\t<os_requirements>string</os_requirements>\n\t<required_processor>None</required_processor>\n\t<switch_with_package>Do Not Install</switch_with_package>\n\t<install_if_reported_available>true</install_if_reported_available>\n\t<reinstall_option>Do Not Reinstall</reinstall_option>\n\t<triggering_files>string</triggering_files>\n\t<send_notification>true</send_notification>\n</package>"
        
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "\(server)/JSSResource/packages/id/0")!,timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        print("Request is:\(String(describing: request))")
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
                
                self.resourceAccess = true
                
                //                self.doubleSeparationLine()
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
                    DispatchQueue.main.async {
                        self.processPolicies(data: data, response: response, resourceType: resourceType)
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    self.resourceAccess = false
                }
                var text = "\n\nFailed."
                if let error = error {
                    text += " \(error)."
                }
                DispatchQueue.main.async {
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
                    //                    print(String(error: error, encoding: .utf8)!)
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
        //        func getPolicyAsXMLaSync(server: String, policyID: Int, authToken: String) async throws -> String{
        
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
//        print("Running getDetailedIcon - iconID is:\(iconID)")
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseCode = (response as? HTTPURLResponse)?.statusCode
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - Response is:\(String(describing: responseCode ?? 0))")
            throw NetError.badResponseCode
        }
        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(Icon.self, from: data) {
            self.iconDetailed = decodedData
            separationLine()
            //        print("Running getDetailedIcon - iconID is:\(iconID)")
            //        print("Response is:\(String(describing: responseCode))")
            print("Add to:allIconsDetailed: Icon id is:\(iconID)")
            self.allIconsDetailed.insert(self.iconDetailed, at: 0)
        } else {
            print("Decoding failed")
        }
        //        print("All icons are:\(self.allIconsDetailed)")
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
    
    
    func fetchDetailedData() {
        
        if self.fetchedDetailedPolicies == false {
            
            print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
            
            if self.allPoliciesDetailed.count < self.allPoliciesConverted.count {
                
                print("fetching detailed policies")
                self.getAllPoliciesDetailed(server: server, authToken: self.authToken, policies: self.allPoliciesConverted)
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

    //
    //  JamfController.swift
    //  JamfList
    //
    //  Created by Armin Briegel on 2022-12-20.
    //
    
    //    import Foundation
    //
    //    class JamfController: ObservableObject {
    
    //  #######################################################################
    //    Jamf objects fetched
    //  #######################################################################
    
    //        @Published var computers: [ComputerSample] = []
    //        @Published var scripts: [Script] = []
    //        @Published var buildings: [Building] = []
    
    //  #######################################################################
    //    Jamf objects fetched - FINISHED
    //  #######################################################################
    
    @Published var isLoading = false
    @Published var needsCredentials = false
    @Published var connected = false
    //        @Published var hasError = false
    
    //
    //
    //        var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    //        var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password = ""
    
    var auth: JamfAuthToken?
    
    
    @Published var computersample: [ComputerSample] = []
    @Published var scriptclassic: [ScriptClassic] = []
    @Published var scriptold: [Script] = []
    //    @Published var buildings: [Building] = []
    
    
    
    
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
            print("fetchedComputers has run successfully")
            
        } else {
            //          hasError = true
            print("fetchedComputers has errored")
        }
        
        //              ##############################################################
        //              Scripts
        //              ##############################################################
        
        if let fetchedScripts = try? await Script.getAll(server: server, auth: auth) {
            scriptold = fetchedScripts
            //        print(scripts)
            print("fetchedScripts has run successfully")
            
        } else {
            //      hasError = true
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
    
}

    
    
//}
