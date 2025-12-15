import SwiftUI
import UniformTypeIdentifiers


struct PolicyDetailView: View {
    
    var server: String
    
    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var exportController: ImportExportBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    //  ########################################################################################
    
    @State var categoryName = ""
    
    @State private var categoryID = ""
    
    @State var categories: [Category] = []
    
    @State private var computers: [ Computer ] = []
    
    @State var computerID = ""
    
    @State var computerUDID = ""
    
    @State var computerName = ""
    
    //  ########################################################################################
    //  GROUPS
    //  ########################################################################################
    
    @State var computerGroupFilter = ""

    //  ########################################################################################
    //  Packages
    //  ########################################################################################
    
    @State var packageFilter = ""
    
    @State private var packageID = ""
    
    @State private var packageName = ""
    
    //  ########################################################################################
    //  Policies
    //  ########################################################################################
    
    var policy: Policy
    
    var policyID: Int
    
    @State var policyName = ""
    
    @State var policyNameInitial = ""
    
    @State var policyNameClone = ""
    
    @State var policyCustomTrigger = ""
    
    
    //    ########################################################################################
//    Triggers
    //    ########################################################################################

    @State var trigger_login: Bool = false
    @State var trigger_checkin: Bool = false
    @State var trigger_startup: Bool = false
    @State var trigger_enrollment_complete: Bool = false
    
    //    ########################################################################################
    //    ########################################################################################
    //    VARIABLES
    //    ########################################################################################
    //    ########################################################################################
    
//    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    @State var scriptName = ""
    
    @State var scriptID = ""
    
    @State var enableDisableButton: Bool = true
    
    @State var enableDisableStatus: Bool = true
    
    @State var enableDisableSelfServiceStatus: Bool = true
    
    @State var enableDisableSelfService: Bool = true
    
    @State var pushTriggerActiveWarning: Bool = false
    
    @State private var exporting = false
    
    //    ########################################################################################
    //    Selections
    //    ########################################################################################
    
    @State var selectedResourceType = ResourceType.policyDetail
    
    @State var selection: Package? = nil
    
    @State var packageSelection = Set<Package>()
    
    @State private var computerGroupSelection = Set<ComputerGroup>()
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
    
    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
    
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = Icon(id: 0, url: "", name: "")
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    //    ########################################################################################
    //    Script parameters
    //    ########################################################################################
    
    @State var scriptParameter4: String = ""
    
    @State var scriptParameter5: String = ""
    
    @State var scriptParameter6: String = ""
    
    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())
    
    @State private var showingWarning = false
    
    @State private var showingWarningDelete = false
    
    @State private var showingWarningClearScope = false
    
    @State private var showingWarningClearLimit = false
    
    //    ########################################################################################
    //    ########################################################################################
    //    MAIN BODY
    //    ########################################################################################
    //    ########################################################################################
    
    var body: some View {
        
        let text = String(describing: xmlController.currentPolicyAsXML)
        
        let document = TextDocument(text: text)
        
        VStack(alignment: .leading) {
            
            //  ################################################################################
            //              Top
            //  ################################################################################
            
            if networkController.policyDetailed != nil {
                
#if os(macOS)
                VStack(alignment: .leading) {
                    Text("Jamf Name:\t\t\t\t\(networkController.policyDetailed?.general?.name ?? "Blank")\n")
                    Text("Enabled Status:\t\t\t\(String(describing: networkController.policyDetailed?.general?.enabled ?? true))\n")
                    Text("Self Service Name:\t\t\(String(describing: networkController.policyDetailed?.self_service?.selfServiceDisplayName ?? ""))\n")
                    Text("Self Service Status:\t\t\(String(describing: networkController.policyDetailed?.self_service?.useForSelfService ?? true))\n")
                    Text("Policy Trigger:\t\t\t\(networkController.policyDetailed?.general?.triggerOther ?? "")\n")
                    Text("Category:\t\t\t\t\(networkController.policyDetailed?.general?.category?.name ?? "")\n")
                    Text("Jamf ID:\t\t\t\t\t\(String(describing: networkController.policyDetailed?.general?.jamfId ?? 0))\n" )
                    Text("Current Icon:\t\t\t\t\(networkController.policyDetailed?.self_service?.selfServiceIcon?.filename ?? "No icon set")\n")
                    AsyncImage(url: URL(string: networkController.policyDetailed?.self_service?.selfServiceIcon?.uri ?? "")) { image in
                        image.resizable()
                    } placeholder: {
                        Color.red.opacity(0.1)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(.rect(cornerRadius: 25))
                    
                    if networkController.policyDetailed?.general?.overrideDefaultSettings?.distributionPoint != "" {
                        
                        Text("Distribution Point :\t\t\t\(networkController.policyDetailed?.general?.overrideDefaultSettings?.distributionPoint ?? "")\n")
                    }
                    
                    if pushTriggerActiveWarning == true {
                        Text("⚠️ Push Trigger Active! ⚠️\n").foregroundColor(.red)
                    }
                    
                    
                }
                .textSelection(.enabled)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                
                //              ################################################################################
                //              Toolbar
                //              ################################################################################
                
                .toolbar {
                    
                }
#endif
            }
            
            // ################################################################################
            //              ENABLE/DISABLE
            // ################################################################################
            
            HStack(spacing: 20) {
                
                Toggle("", isOn: $enableDisableButton)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .onChange(of: enableDisableButton) { value in
                        networkController.togglePolicyOnOff(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, policyToggle: enableDisableButton)
                        print("enableDisableButton changed - value is now:\(value) for policy:\(policyID)")
                    }
                
#if os(macOS)
                
                if enableDisableButton == true {
                    Text("Enabled")
                } else {
                    Text("Disabled")
                }
                
            
#endif
                
                //  ##########################################################################
                //              DELETE
                //  ##########################################################################
                
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    print("Deleting policy:\(policyID)")
                    showingWarning = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "delete.left.fill")
                        Text("Delete")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                
                .alert(isPresented: $showingWarning) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            networkController.deletePolicy(server: server, resourceType: selectedResourceType, itemID: String(describing: policyID), authToken: networkController.authToken)
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                
                //              ################################################################################
                //              DOWNLOAD OPTION
                //              ################################################################################
                
#if os(macOS)
                
                Button("Export") {
                    exporting = true
                    networkController.separationLine()
                    print("Printing text to export:\(text)")
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                
                .fileExporter(
                    isPresented: $exporting,
                    document: document,
                    contentType: .xml
                ) { result in
                    switch result {
                    case .success(let file):
                        print("Printing file to export:\(file)")
                    case .failure(let error):
                        print(error)
                    }
                }
                
                Button(action: {
                    
                    print("Refresh detailPolicyView")
                    progress.showProgress()
                    progress.waitForABit()
                    
                    Task {
                        do {
                            let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: policyID, authToken: networkController.authToken)
                            
                            xmlController.readXMLDataFromString(xmlContent: xmlController.currentPolicyAsXML)
                        } catch {
                            print("Fetching detailed policy as xml failed: \(error)")
                        }
                    }
                    
                    Task {
                        try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                        policyName = networkController.policyDetailed?.general?.name ?? ""
                        policyCustomTrigger = networkController.policyDetailed?.general?.triggerOther ?? ""
                    }
                    
                }) {
                    HStack(spacing: 10) {
                        Text("Refresh Detail")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                
                HStack {
                //              ##########################################################################
                //              CLONE
                //              ##########################################################################
                
                TextField(policyNameClone, text: $policyName)
                    .textSelection(.enabled)
                
                Button(action: {
                    print("Cloning policy:\(policyName)")
                    progress.showProgress()
                    progress.waitForABit()
                    if policyNameClone.isEmpty == true {
                        policyNameInitial = networkController.policyDetailed?.general?.name ?? ""
                        let newPolicyName = "\(policyNameInitial)-1"
                        print("No name provided - policy is:\(newPolicyName)")
                        policyController.clonePolicy(xmlContent: xmlController.currentPolicyAsXML, server: server, policyName: newPolicyName, authToken: networkController.authToken)
                    } else {
                        print("Policy name is set as:\(policyName)")
                        policyController.clonePolicy(xmlContent: xmlController.currentPolicyAsXML, server: server, policyName: policyNameClone, authToken: networkController.authToken)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "dog")
                        Text("Clone")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
#endif
            }
            
            .textSelection(.enabled)
            
            //  ##########################################################################
            //              UPDATE NAME
            //  ##########################################################################
            
            Divider()
            
            
                
                VStack(alignment: .leading) {
                    
                    Text("Edit Names:").fontWeight(.bold)
                    
                    LazyVGrid(columns: layout.columns, spacing: 20) {
                        
                        HStack {
                            
                            TextField(policyName, text: $policyName)
                                .textSelection(.enabled)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateName(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyName, policyID: String(describing: policyID))
                                
                                networkController.separationLine()
                                print("Renaming Policy:\(policyName)")
                            }) {
                                Text("Rename")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        //  ##########################################################################
                        //              UPDATE Trigger
                        //  ##########################################################################
                        
                        HStack {
                            
                            TextField(policyCustomTrigger, text: $policyCustomTrigger)
                                .textSelection(.enabled)
                            
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                
                                networkController.updateCustomTrigger(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyCustomTrigger: policyCustomTrigger, policyID: String(describing: policyID))
                                
                                networkController.separationLine()
                                print("Updating Policy Trigger to:\(policyName)")
                                
                            }) {
                                Text("Trigger")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                    
                    //  ##########################################################################
                    //              UPDATE Self-Service
                    //  ##########################################################################
                    
                    LazyVGrid(columns: layout.columnsFlex, spacing: 20) {
                        
                        HStack {
                            TextField(policyName, text: $policyName)
                                .textSelection(.enabled)
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateSSName(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, providedName: policyName, policyID: String(describing: policyID))
                                
                                networkController.separationLine()
                                print("Name Self-Service to:\(policyName)")
                            }) {
                                Text("Self-Service")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            Toggle("", isOn: $enableDisableSelfService)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                                .onChange(of: enableDisableSelfService) { value in
                                    progress.showProgress()
                                    progress.waitForABit()
                                    networkController.toggleSelfServiceOnOff(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, selfServiceToggle: enableDisableSelfService)
                                    print("enableDisableSelfServiceButton changed - value is now:\(value) for policy:\(policyID)")
                                }
#if os(macOS)
                            if enableDisableSelfService == true {
                                Text("Enabled")
                            } else {
                                Text("Disabled")
                            }
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.enableSelfService(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, selfServiceToggle: true)
                            }) {
                                Text("Enable")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
#endif
                        }
                    }
                }

                
                //  ##########################################################################
                //              CATEGORY
                //  ##########################################################################
                
            Divider()
                
            LazyVGrid(columns: layout.columnsFlex) {
                    HStack {
                        
                        if !networkController.categories.isEmpty {
                            Picker(selection: $selectedCategory, label: Text("Category").fontWeight(.bold)) {
                                ForEach(networkController.categories, id: \.self) { category in
                                    Text(category.name).tag(category)
                                }
                            }
                            .onAppear {
                                if !networkController.categories.isEmpty {
                                    if !networkController.categories.contains(selectedCategory) {
                                        selectedCategory = networkController.categories.first!
                                    }
                                }
                            }
                            .onChange(of: networkController.categories) { newCategories in
                                if !newCategories.isEmpty {
                                    if !newCategories.contains(selectedCategory) {
                                        selectedCategory = newCategories.first!
                                    }
                                }
                            }
                        } else {
                            Text("No categories available")
                        }
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.updateCategory(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, categoryID: String(describing: selectedCategory.jamfId), categoryName: selectedCategory.name, updatePressed: true, resourceID: String(describing: policyID))
                        }) {
                            HStack(spacing: 10) {
                                Text("Update")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(networkController.categories.isEmpty)
                    }
                }
//            }
            .padding()
            
            //  ##########################################################################
            //              DELETE POLICY
            //  ##########################################################################
            
            //  ##########################################################################
            //  Manually add to assigned list
            //  ##########################################################################
            
            //  ##########################################################################
            //  TabView - TAB
            //  ##########################################################################
            
#if os(macOS)
            TabView {
                
                PolicyPackageTabView(policyID: policyID, server: server, resourceType: selectedResourceType, packageSelection: packageSelection)
                    .tabItem {
                        Label("Packages", systemImage: "square.and.pencil")
                    }
                
                PolicyScopeTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID, computerGroupSelection: $computerGroupSelection)
                    .tabItem {
                        Label("Scoping", systemImage: "square.and.pencil")
                    }
                
                PolicyScriptsTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID, computerGroupSelection: $computerGroupSelection)
                    .tabItem {
                        Label("Scripts", systemImage: "square.and.pencil")
                    }
                
                PolicyTriggersTabView(policyID: policyID, server: server, resourceType: ResourceType.policyDetail, trigger_login: networkController.policyDetailed?.general?.triggerLogin ?? false, trigger_checkin: networkController.policyDetailed?.general?.triggerCheckin ?? false, trigger_startup: networkController.policyDetailed?.general?.triggerStartup ?? false, trigger_enrollment_complete: networkController.policyDetailed?.general?.triggerEnrollmentComplete ?? false )
                    .tabItem {
                        Label("Triggers", systemImage: "square.and.pencil")
                    }
                
                PolicySelfServiceTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID )
                    .tabItem {
                        Label("Self Service", systemImage: "square.and.pencil")
                    }
                
                PolicyRemoveItemsTabView(policyID: policyID, server: server, resourceType: ResourceType.policyDetail )
                    .tabItem {
                        Label("Clear", systemImage: "square.and.pencil")
                    }
            }

#endif
            
            //  ##########################################################################
            //  Progress view via showProgress
            //  ##########################################################################
            
            if progress.showProgressView == true {
                
                ProgressView {
                    Text("Processing")
                }
                .padding()
            } else {
                Text("")
            }
        }
        . padding()
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 70, maxHeight: .infinity)
        
        //        if progress.debugMode == true {
        //            .background(Color.blue)
        //        }
        
        .onAppear {
            networkController.separationLine()
            progress.showProgress()
            progress.waitForNotVeryLong()

            Task {
                print("PolicyDetailView appeared - running getDetailedPolicy function")
                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                policyName = networkController.policyDetailed?.general?.name ?? ""
                policyCustomTrigger = networkController.policyDetailed?.general?.triggerOther ?? ""
                trigger_login = networkController.policyDetailed?.general?.triggerLogin ?? false
                trigger_checkin = networkController.policyDetailed?.general?.triggerCheckin ?? false
                trigger_startup = networkController.policyDetailed?.general?.triggerStartup ?? false
                trigger_enrollment_complete = networkController.policyDetailed?.general?.triggerEnrollmentComplete ?? false
               
               if trigger_login || trigger_checkin || trigger_startup || trigger_enrollment_complete == true {
                   pushTriggerActiveWarning = true
                   print("Push trigger is active!")
               } else {
                   pushTriggerActiveWarning = false
                   print("Push trigger has been deactivated")
               }
                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
            }
            
            Task {
                print("getPolicyAsXML - running get policy as xml function")
                _ = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: policyID, authToken: networkController.authToken)
                 xmlController.readXMLDataFromString(xmlContent: xmlController.currentPolicyAsXML)
            }
            
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                Task {
                    networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
                }
            }
            
            if networkController.packages.count <= 1 {
                Task {
                    networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
                }
            }
            
            if networkController.departments.count <= 1 {
                Task {
                    networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
                }
            }
            
            if networkController.buildings.count <= 1 {
                Task {
                    try await networkController.getBuildings(server: server, authToken: networkController.authToken)
                }
            }
            
            if networkController.allComputerGroups.count <= 0 {
                
                Task {
                    try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                }
            }
          
          
         
          
            if networkController.packagesAssignedToPolicy.count <= 0 {
                
                Task {
                    networkController.getPackagesAssignedToPolicy()
                    networkController.addExistingPackages()
                    fetchData()
                }
        }
    }

        // Add an "Open in Browser" button that uses the Layout helper to open the current policy URL
        HStack {
            Spacer()
            Button(action: {
                // Use the current URL provided by the network controller
                let urlToOpen = networkController.currentURL
                print("Opening URL: \(urlToOpen)")
                layout.openURL(urlString: urlToOpen)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "safari")
                    Text("Open in Browser")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.top, 6)
            Spacer()
        }
        .padding()
        .textSelection(.enabled)
}
    
    func fetchData() {
        
        if  networkController.packages.isEmpty {
            print("No package data - fetching")
            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
            
        } else {
            print("package data is available")
        }
    }
}


//struct PolicyDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PolicyDetailView(server: "", username: "", password: "", policy: PolicyDetailed(id:11111111-1111-1111-1111-111111111111, name: "", policyID: 1), policyID: 01)
//
//        //    DetailView(computer: Computer.sampleMacBookAir)
//
//    }
//}
