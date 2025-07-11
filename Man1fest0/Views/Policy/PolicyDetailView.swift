

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
    //  LDAP
    //  ########################################################################################
    
    @State var ldapUserGroupName = ""
    
    @State var ldapUserGroupId = ""
    
    @State var ldapUserGroupName2 = ""
    
    @State var ldapUserGroupId2 = ""
    
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
    
    @State var policyCustomTrigger = ""
    
    //    ########################################################################################
    //    ########################################################################################
    //    VARIABLES
    //    ########################################################################################
    //    ########################################################################################
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    @State var scriptName = ""
    
    @State var scriptID = ""
    
    @State var enableDisableButton: Bool = true
    
    @State var enableDisableStatus: Bool = true
    
    @State var enableDisableSelfServiceStatus: Bool = true
    
    @State var enableDisableSelfService: Bool = true
    
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

        let text = String(describing: networkController.currentPolicyAsXML)
        
        let document = TextDocument(text: text)
        
        VStack(alignment: .leading) {
            
            //  ################################################################################
            //              Top
            //  ################################################################################
            
            if networkController.currentDetailedPolicy != nil {
                
#if os(macOS)
                VStack(alignment: .leading) {
                    Text("Jamf Name:\t\t\t\t\(networkController.currentDetailedPolicy?.policy.general?.name ?? "Blank")\n")
                    Text("Enabled Status:\t\t\t\(String(describing: networkController.currentDetailedPolicy?.policy.general?.enabled ?? true))\n")
                    Text("Self Service Status:\t\t\(String(describing: networkController.currentDetailedPolicy?.policy.self_service?.useForSelfService ?? true))\n")
                    Text("Policy Trigger:\t\t\t\(networkController.currentDetailedPolicy?.policy.general?.triggerOther ?? "")\n")
                    Text("Category:\t\t\t\t\(networkController.currentDetailedPolicy?.policy.general?.category?.name ?? "")\n")
                    Text("Jamf ID:\t\t\t\t\t\(String(describing: networkController.currentDetailedPolicy?.policy.general?.jamfId ?? 0))" )
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
            
            //              ################################################################################
            //              ENABLE/DISABLE
            //              ################################################################################
            
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
                
//              ##########################################################################
//              CLONE
//              ##########################################################################

                Button(action: {
                    print("Cloning policy:\(policyName)")
                    progress.showProgress()
                    progress.waitForABit()
                    if policyName.isEmpty == true {
                        policyNameInitial = networkController.currentDetailedPolicy?.policy.general?.name ?? ""
                        let newPolicyName = "\(policyNameInitial)1"
                        print("No name provided - policy is:\(newPolicyName)")
                        policyController.clonePolicy(xmlContent: networkController.currentPolicyAsXML, server: server, policyName: newPolicyName, authToken: networkController.authToken)
                    } else {
                        print("Policy name is set as:\(policyName)")
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "dog")
                        Text("Clone")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
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
                    
                    networkController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
                    networkController.connectDetailed(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: policyID)
                    print("Refresh detailPolicyView")
                    
                }) {
                    HStack(spacing: 10) {
                        Text("Refresh Detail")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
#endif
            }
            
            .textSelection(.enabled)
            
//  ##########################################################################
//              UPDATE NAME
//  ##########################################################################

            Divider()
            
            VStack(alignment: .leading) {
                
                VStack(alignment: .leading) {
                    
                    Text("Edit Names:").fontWeight(.bold)
                    
                    LazyVGrid(columns: layout.fourColumns, spacing: 20) {
                        
                        HStack {
                            
                            TextField(networkController.currentDetailedPolicy?.policy.general?.name ?? policyNameInitial, text: $policyName)
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
                            
                            TextField(networkController.currentDetailedPolicy?.policy.general?.triggerOther ?? "", text: $policyCustomTrigger)
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
                            TextField(networkController.currentDetailedPolicy?.policy.general?.name ?? policyName, text: $policyName)
                                .textSelection(.enabled)
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateSSName(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyNameInitial, policyID: String(describing: policyID))
                                
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
                                    networkController.toggleSelfServiceOnOff(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, selfServiceToggle: enableDisableSelfService)
                                    print("enableDisableSelfServiceButton changed - value is now:\(value) for policy:\(policyID)")
                                }
#if os(macOS)
                            if enableDisableSelfService == true {
                                Text("Enabled")
                            } else {
                                Text("Disabled")
                            }
#endif
                        }
                    }
                    
//  ##########################################################################
//              CATEGORY
//  ##########################################################################

                    Divider()
                    
                    LazyVGrid(columns: layout.columnsFlex) {
                        HStack {
                            
                            Picker(selection: $selectedCategory, label: Text("Category").fontWeight(.bold)) {
                                ForEach(networkController.categories, id: \.self) { category in
                                    Text(String(describing: category.name))
                                        .tag(category as Category?)
                                        .tag(selectedCategory as Category?)
                                }
                            }
                            .onAppear {
                                
                                if networkController.categories.isEmpty != true {
                                    print("Setting categories picker default")
                                    selectedCategory = networkController.categories[0] }
                            }
                            
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                
                                networkController.updateCategory(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, categoryID: String(describing: selectedCategory.jamfId), categoryName: String(describing: selectedCategory.name), updatePressed: true, resourceID: String(describing: policyID))
                                
                            }) {
                                HStack(spacing: 10) {
                                    Text("Update")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                }
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
                    
                    PolicyTriggersTabView(policyID: policyID, server: server, resourceType: ResourceType.policyDetail)
                        .tabItem {
                            Label("Triggers", systemImage: "square.and.pencil")
                        }
                }
#endif
            }
            
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
        .frame(minWidth: 100, maxWidth: 600, minHeight: 70, maxHeight: .infinity)
        
        //        if progress.debugMode == true {
        //            .background(Color.blue)
        //        }
        
        .onAppear {
            
            //  ##########################################################################
            //  PolicyDetailView
            //  ##########################################################################

            networkController.separationLine()
            print("PolicyDetailView appeared - running detailed policy connect function")
            
            progress.showProgress()
            progress.waitForNotVeryLong()
            
            let currentPolicyAsXMLLocal = Task {
                
                print("getPolicyAsXML - running get policy as xml function")
                
                try await networkController.getPolicyAsXMLaSync(server: server, policyID: policyID, authToken: networkController.authToken)
                
                if !networkController.currentPolicyAsXML.isEmpty {
                    print("Reading XML into AEXML - networkController")
                    
//  ##########################################################################
//  NOTE: CHANGED FROM XML CONTROLLER BELOW
//  ##########################################################################

//                    xmlController.readXMLDataFromString(xmlContent: networkController.currentPolicyAsXML)
                    networkController.readXMLDataFromString(xmlContent: networkController.currentPolicyAsXML)

//  ##########################################################################
//  NOTE: CHANGED FROM XML CONTROLLER - END
//  ##########################################################################

                }
            }
            
//            This is fetching the detailed policy - which is already happening - eventually, this can be removed and instead of using the property: networkController.currentDetailedPolicy?.policy

//            The property networkController.policyDetailed will be used
            
            networkController.connectDetailed(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: policyID)
            
            Task {
                
                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                
                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
            }
            
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            }
            
            if networkController.packages.count <= 1 {
                networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
            }
            
            if networkController.departments.count <= 1 {
                
                networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
            }
            
            if networkController.buildings.count <= 1 {
//                networkController.connect(server: server,resourceType: ResourceType.building, authToken: networkController.authToken)
                Task {
                    try await networkController.getBuildings(server: server, authToken: networkController.authToken)
                }
            }
            
//  ##########################################################################
//  getAllGroups
//  ##########################################################################

            
            Task {
                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
            }
            
            //  ##########################################################################
//  Add current packages to packagesAssignedToPolicy list on appear of View
            //  ##########################################################################

            networkController.getPackagesAssignedToPolicy()
            
            networkController.addExistingPackages()
            
            fetchData()
            
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

