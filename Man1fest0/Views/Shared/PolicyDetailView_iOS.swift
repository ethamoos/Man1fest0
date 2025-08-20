////
////  PolicyDetailView_-iOS.swift
////  Man1fest0
////
////  Created by Amos Deane on 19/09/2024.
////
//
//import SwiftUI
//
//struct PolicyDetailView_iOS: View {
// 
//    var server: String
//    
//    //  ########################################################################################
//    //  EnvironmentObjects
//    //  ########################################################################################
//    
//    @EnvironmentObject var networkController: NetBrain
//    
//    @EnvironmentObject var scopingController: ScopingBrain
//    
//    @EnvironmentObject var progress: Progress
//    
//    @EnvironmentObject var policyController: PolicyBrain
//    
//    @EnvironmentObject var layout: Layout
//    
//    //  ########################################################################################
//    
//    @State var selectedResourceType = ResourceType.policyDetail
//    
//    @State var selection: Package? = nil
//    
//    @State var categoryName = ""
//    
//    @State private var categoryID = ""
//    
//    @State var categories: [Category] = []
//    
//    @State private var computers: [ Computer ] = []
//    
//    @State var computerID = ""
//    
//    @State var computerUDID = ""
//    
//    @State var computerName = ""
//    
//    //  ########################################################################################
//    //  GROUPS
//    //  ########################################################################################
//
//    @State private var computerGroupSelection = Set<ComputerGroup>()
//    
//    @State var computerGroupFilter = ""
//    
//    //  ########################################################################################
//    //  LDAP
//    //  ########################################################################################
//    
//    @State var ldapUserGroupName = ""
//    
//    @State var ldapUserGroupId = ""
//    
//    @State var ldapUserGroupName2 = ""
//    
//    @State var ldapUserGroupId2 = ""
//    
//    //  ########################################################################################
//    //  Packages
//    //  ########################################################################################
//    
//    @State var packageSelection = Set<Package>()
//    
//    @State var packageFilter = ""
//    
//    @State private var packageID = ""
//    
//    @State private var packageName = ""
//    
//    //  ########################################################################################
//    //  Policies
//    //  ########################################################################################
//    
//    var policy: Policy
//    
//    var policyID: Int
//    
//    @State var policyName = ""
//    
//    @State var policyNameInitial = ""
//    
//    @State var policyCustomTrigger = ""
//
//    //    ########################################################################################
//    //    ########################################################################################
//    //    VARIABLES
//    //    ########################################################################################
//    //    ########################################################################################
//    
//    @State var currentDetailedPolicy: PoliciesDetailed? = nil
//    
//    @State var scriptName = ""
//    
//    @State var scriptID = ""
//    
//    @State var enableDisableButton: Bool = true
//    
//    @State var enableDisableStatus: Bool = true
//    
//    
//    //    ########################################################################################
//    //    Selections
//    //    ########################################################################################
//    
//    @State var selectedComputer: Computer = Computer(id: 0, name: "")
//    
//    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
//    
//    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
//    
//    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
//    
//    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
//    
//    //    ########################################################################################
//    //    Script parameters
//    //    ########################################################################################
//    
//    @State var scriptParameter4: String = ""
//    
//    @State var scriptParameter5: String = ""
//    
//    @State var scriptParameter6: String = ""
//    
//    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())
//    
//    @State private var showingWarning = false
//    
//    //    ########################################################################################
//    //    ########################################################################################
//    //    MAIN BODY
//    //    ########################################################################################
//    //    ########################################################################################
//    
//                                   
//    var body: some View {
//        
////        var currentSelectedPolicyID = String(describing: networkController.currentDetailedPolicy?.policy.general?.jamfId ?? 0)
//
//        VStack(alignment: .leading) {
//            
//            //              ################################################################################
//            //              Top
//            //              ################################################################################
//
//            
//            if networkController.currentDetailedPolicy != nil {
//                
////#if os(macOS)
//                VStack(alignment: .leading) {
//                    
//                    Text("Jamf Name:\t\t\t\t\(networkController.currentDetailedPolicy?.policy.general?.name ?? "Blank")\n")
//                    Text("Enabled Status:\t\t\t\(String(describing: networkController.currentDetailedPolicy?.policy.general?.enabled ?? true))\n")
//                    Text("Policy Trigger:\t\t\t\t\(networkController.currentDetailedPolicy?.policy.general?.triggerOther ?? "")\n")
//                    Text("Category:\t\t\t\t\t\(networkController.currentDetailedPolicy?.policy.general?.category?.name ?? "")\n")
//                    Text("Jamf ID:\t\t\t\t\t\(String(describing: networkController.currentDetailedPolicy?.policy.general?.jamfId ?? 0))" )
//                }
//                .textSelection(.enabled)
//                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
//                
//                //              ################################################################################
//                //              Toolbar
//                //              ################################################################################
////                .toolbar {
////                    
////                }
////#endif
//            }
//            
//            //              ################################################################################
//            //              ENABLE/DISABLE/DELETE
//            //              ################################################################################
//                        
//            VStack(alignment: .leading) {
//                
//                Divider()
//
//                HStack() {
//                    
//                    Toggle("", isOn: $enableDisableButton)
//                        .toggleStyle(SwitchToggleStyle(tint: .red))
//                        .onChange(of: enableDisableButton) { value in
//                            networkController.togglePolicyOnOff(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, policyToggle: enableDisableButton)
//                            print("enableDisableButton changed - value is now:\(value) for policy:\(policyID)")
//                        }
//                    
//                    if enableDisableButton {
//                        Text("Enabled")
//                    } else {
//                        Text("Disabled")
//                    }
//#if os(macOS)
//                    
//                    //              ################################################################################
//                    //              CLONE
//                    //              ################################################################################
//                    
//                    Button(action: {
//                        
//                        print("Cloning policy:\(policyName)")
//                        
//                        progress.showProgress()
//                        progress.waitForABit()
//                        
//                        if policyName.isEmpty == true {
//                            policyNameInitial = networkController.currentDetailedPolicy?.policy.general?.name ?? ""
//                            let newPolicyName = "\(policyNameInitial)1"
//                            print("No name provided - policy is:\(newPolicyName)")
//                            policyController.clonePolicy(xmlContent: xmlController.currentPolicyAsXML, server: server, policyName: newPolicyName, authToken: networkController.authToken)
//                        } else {
//                            print("Policy name is set as:\(policyName)")
//                        }
//                        
//                    }) {
//                        HStack(spacing: 10) {
//                            Image(systemName: "plus.square.fill.on.square.fill")
//                            Text("Clone")
//                        }
//                    }
//#endif
//                    
//                    
//                    
//                    //              #############################################################################
//                    //              DELETE
//                    //              #############################################################################
//                    
//                    Button(action: {
//                        
//                        progress.showProgress()
//                        progress.waitForABit()
//                        
//                        networkController.deletePolicy(server: server, resourceType: selectedResourceType, itemID: String(describing: policyID), authToken: networkController.authToken)
//                        print("Deleting policy:\(policyID)")
//                        showingWarning = true
//                        
//                    }) {
//                        //                    HStack(spacing: 10) {
//                        //                        Image(systemName: "delete.left.fill")
//                        Text("Delete")
//                        //                    }
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.red)
////                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
//                    .alert(isPresented: $showingWarning) {
//                        Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
//                    }
////                    .buttonStyle(.borderedProminent)
////                    .tint(.red)
//                    
//                    
//                    
//                    //              ################################################################################
//                    //              DOWNLOAD OPTION
//                    //              ################################################################################
//#if os(macOS)
//                    Button(action: {ASyncFileDownloader.downloadFileAsyncAuth( objectID: policyID, resourceType: ResourceType.policies, server: server, authToken: networkController.authToken) { (path, error) in}}) {
//                        Text("Download")
//                    }
//#endif
//                }
//            }
//            
//            .textSelection(.enabled)
//            
//            //              ################################################################################
//            //              UPDATE NAME
//            //              ################################################################################
//            
//            Divider()
//            
//            VStack(alignment: .leading) {
//                
//                VStack(alignment: .leading) {
//                
////                    LazyVGrid(columns: layout.fourColumns, spacing: 20) {
//                    
//                    HStack {
//
//                        TextField(networkController.currentDetailedPolicy?.policy.general?.name ?? policyNameInitial, text: $policyName)
//                            .textSelection(.enabled)
//                        
//                        Button(action: {
//                            progress.showProgress()
//                            progress.waitForABit()
//                            networkController.updateName(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyName, policyID: String(describing: policyID))
//                            //                            networkController.updateSSName(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyName, policyID: String(describing: policyID))
//                            networkController.separationLine()
//                            print("Renaming Policy:\(policyName)")
//                        }) {
//                            Text("Rename")
//                        }
//                    }
//                    
//                    //              ################################################################################
//                    //              UPDATE Trigger
//                    //              ################################################################################
//                    
//                    HStack {
//                        TextField(networkController.currentDetailedPolicy?.policy.general?.triggerOther ?? "", text: $policyCustomTrigger)
//                            .textSelection(.enabled)
//                        Button(action: {
//                            
//                            progress.showProgress()
//                            progress.waitForABit()
//                            
//                            networkController.updateCustomTrigger(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyCustomTrigger: policyCustomTrigger, policyID: String(describing: policyID))
//                            
//                            networkController.separationLine()
//                            print("Updating Policy Trigger to:\(policyName)")
//                            
//                        }) {
//                            Text("Trigger")
//                        }
//                    }
////                }
//                
//                //              ################################################################################
//                //              UPDATE Self-Service
//                //              ################################################################################
//                
////                LazyVGrid(columns: layout.columnsFlex, spacing: 20) {
//                    
//                    HStack {
//                        TextField(networkController.currentDetailedPolicy?.policy.general?.name ?? policyName, text: $policyName)
//                            .textSelection(.enabled)
//                        Button(action: {
//                            
//                            progress.showProgress()
//                            progress.waitForABit()
//                            
//                            networkController.updateSSName(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyName: policyNameInitial, policyID: String(describing: policyID))
//                            networkController.separationLine()
//                            print("Name Self-Service to:\(policyName)")
//                        }) {
//                            Text("Self-Service")
//                        }
//                    }
////                }
//                
//                //              ####################################################################
//                //              CATEGORY
//                //              ####################################################################
//                
//                    Divider()
//
//                    Text("Category")
//
////                LazyVGrid(columns: layout.columnsFlex) {
//                    HStack {
//                        
//                        Picker(selection: $selectedCategory, label: Text("Category")) {
//                            //                            Text("").tag("") //basically added empty tag and it solve the case
//                            ForEach(networkController.categories, id: \.self) { category in
//                                Text(String(describing: category.name))
//                                    .tag(category as Category?)
//                            }
//                        }
//                        .onAppear {
//                        
//                        if networkController.categories.isEmpty != true {
//                            print("Setting categories picker default")
//                            selectedCategory = networkController.categories[0] }
//                    }
//                        
//                        Button(action: {
//                            
//                            progress.showProgress()
//                            progress.waitForABit()
//                            
//                            categoryID = (String(describing: networkController.currentDetailedPolicy?.policy.general?.jamfId ?? 0))
//                            categoryName = networkController.currentDetailedPolicy?.policy.general?.category?.name ?? ""
//                            
//                            networkController.updateCategory(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, categoryID: String(describing: selectedCategory.jamfId), categoryName: selectedCategory.name, updatePressed: true, resourceID: String(describing: policyID))
//                        }) {
////                            HStack(spacing: 10) {
////                                Image(systemName: "arrow.clockwise")
//                                Text("Update")
////                            }
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.blue)
//                    }
////                }
//            }
////            .padding()
//            .frame(minWidth: 50, maxWidth: .infinity, minHeight: 70, maxHeight: .infinity)
//
//                
//                //              ################################################################################
//                //              DELETE POLICY
//                //              ################################################################################
//                
//                //              ################################################################################
//                //              Manually add to assigned list
//                //              ################################################################################
//  
//                //              ################################################################################
//                //              TabView - TAB
//                //              ################################################################################
//                
//                
//#if os(macOS)
//                TabView {
//                    
//                    PolicyPackageTabView(policyID: policyID, server: server, resourceType: selectedResourceType, packageSelection: packageSelection)
//                        .tabItem {
//                            //                                Text("Packages")
//                            Label("Packages", systemImage: "square.and.pencil")
//                        }
//                    
//                    PolicyScopeTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID, computerGroupSelection: $computerGroupSelection)
//                        .tabItem {
//                            //                                Text("Scoping")
//                            Label("Scoping", systemImage: "square.and.pencil")
//                        }
//                    
//                    PolicyScriptsTabView(server: server, resourceType: ResourceType.policyDetail, computerGroupSelection: $computerGroupSelection , policyID: policyID)
//                        .tabItem {
//                            //                                Text("Scoping")
//                            Label("Scripts", systemImage: "square.and.pencil")
//                        }
//                }
//                
//#endif
//            }
//            
//            //  ################################################################################
//            //  Progress view via showProgress
//            //  ################################################################################
//            
//            if progress.showProgressView == true {
//                
//                ProgressView {
//                    Text("Processing")
//                }
//                .padding()
//                
//            } else {
//                Text("")
//            }
//        }
//        . padding()
//        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 70, maxHeight: .infinity)
//        
//        //        if progress.debugMode == true {
//        //            .background(Color.blue)
//        //        }
//        
//        .onAppear {
//            
//            networkController.separationLine()
//            print("PolicyDetailView appeared - running detailed policy connect function")
//            
//            progress.showProgress()
//            progress.waitForNotVeryLong()
//
//            Task {
//                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
//            }
//            
//            if networkController.categories.count <= 1 {
//                print("No categories - fetching")
//                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
//            }
//            
//            if networkController.packages.count <= 1 {
//                networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
//            }
//            
//            if networkController.departments.count <= 1 {
//                
//                networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
//            }
//
//            xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
//  
//            networkController.connectDetailed(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: policyID)
//            
//            //  ################################################################################
////    ENABLE DISABLE
//            //  ################################################################################
//
//            print("Setting policy enable status")
//            enableDisableStatus = ((networkController.currentDetailedPolicy?.policy.general?.enabled) != nil)
//            enableDisableButton = enableDisableStatus
//            print("enableDisableStatus is:\(String(describing: enableDisableStatus)) for policy:\(policyID)")
//            
//            Task {
//                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
//            }
//            
//            //  ################################################################################
//            //  Add current packages to packagesAssignedToPolicy list on appear of View
//            //  ################################################################################
//            
//            networkController.getPackagesAssignedToPolicy()
//            
//            networkController.addExistingPackages()
//            
//            fetchData()
//            
//        }
//        .padding()
//        //            .background(Color.blue)
//    }
//    
//    
//    func fetchData() {
//        
//        if  networkController.packages.isEmpty {
//            print("No package data - fetching")
//            networkController.connect(server: server,resourceType: ResourceType.packages, authToken: networkController.authToken)
//
//        } else {
//            print("package data is available")
//        }
//        
////        if networkController.updateXML == true {
////            xmlController.getPolicyAsXML(server: server, policyID: policyID, authToken: networkController.authToken)
////        }
//        
//    }
//}
//
//
//
////struct PolicyDetailView_Previews: PreviewProvider {
////    static var previews: some View {
////        PolicyDetailView(server: "", username: "", password: "", policy: PolicyDetailed(id:11111111-1111-1111-1111-111111111111, name: "", policyID: 1), policyID: 01)
////
////        //    DetailView(computer: Computer.sampleMacBookAir)
////
////    }
////}
//
////
////
////#Preview {
////    PolicyDetailView_iOS()
////}
