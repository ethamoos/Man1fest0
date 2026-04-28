import SwiftUI
import UniformTypeIdentifiers
import AEXML


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

    // New states for Clone-per-package flow
    @State private var showingClonePerPackageConfirm = false
    @State private var cloningInProgress = false
    // New states for Clone-per-script flow
    @State private var showingClonePerScriptConfirm = false
    @State private var scriptFilter: String = ""
    @State private var cloneUseParameters: Bool = true
    @State private var cloneAllParameters: Bool = false

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

    // Computed property - always reflects current detailed policy triggers
    private var pushTriggerActiveWarningComputed: Bool {
        let gd = networkController.policyDetailed?.general
        return (gd?.triggerLogin ?? false) || (gd?.triggerCheckin ?? false) || (gd?.triggerStartup ?? false) || (gd?.triggerEnrollmentComplete ?? false)
    }

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

    // removed stored pushTriggerActiveWarning; view now reads computed property

    @State private var exporting = false



    //    ########################################################################################
    //    Selections
    //    ########################################################################################

    @State var selectedResourceType = ResourceType.policyDetail

    // Explicit TabView selection (ensures tab clicks reliably switch tabs on macOS)
    @State private var selectedPolicyDetailTab: Int = 0

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

        let currentDateString = layout.date
        // Prepare a safe filename for export (replace characters that are not allowed in filenames)
        let safeDateComponent = currentDateString.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: " ", with: "_")

        let exportFilename = "\(policyName)\(safeDateComponent).txt"

        let document = TextDocument(text: text)

        // Compute filtered scripts list here (outside the ViewBuilder) so we don't place statements inside the view builder
        let filteredScriptsForClone = networkController.scripts.filter { s in
            scriptFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || s.name.lowercased().contains(scriptFilter.lowercased())
        }
        
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
                    // Only show the 'Current Icon' text when there is NO icon set (i.e. filename is nil or empty)
                    if let iconFilename = networkController.policyDetailed?.self_service?.selfServiceIcon?.filename, !iconFilename.isEmpty {
                        // If an icon filename exists, we do not show the textual "Current Icon" line here (the image below represents it).
                    } else {
                        Text("Current Icon:\t\t\t\tNo icon set\n")
                    }
                     AsyncImage(url: URL(string: networkController.policyDetailed?.self_service?.selfServiceIcon?.uri ?? "")) { image in
                         image.resizable()
                     } placeholder: {
                         Color.red.opacity(0.1)
                     }
                     .frame(width: 50, height: 50)
                     .clipShape(.rect(cornerRadius: 25))
                    // On macOS, show the icon filename as a hover tooltip for the image
                    #if os(macOS)
                    .help(networkController.policyDetailed?.self_service?.selfServiceIcon?.filename ?? "")
                    #endif
                    
                    if pushTriggerActiveWarningComputed {
                        Text("⚠️ Push Trigger Active! ⚠️\n").foregroundColor(.red)
                    }
                    
                    
                }
                .textSelection(.enabled)
                .foregroundColor(.blue)
                
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
                .help("Delete this policy from the Jamf server. This action is destructive and cannot be undone.")
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
                .help("Export the current policy XML to a file for saving or sharing.")
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)

                .fileExporter(
                    isPresented: $exporting,
                    document: document,
                    contentType: .xml,
                    defaultFilename: exportFilename
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
                .help("Reload policy details and XML from the server to reflect current state.")
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                
                
                
                
#endif
            }
            
            .textSelection(.enabled)
            
                //              ##########################################################################
                //              CLONE
                //              ##########################################################################
                
                DisclosureGroup("Clone Policy") {
                
                    LazyVGrid(columns: layout.fourColumns, spacing: 20) {
                        
                        HStack {
                            
                            Button(action: {
                                print("Cloning policy:\(policyName)")
                                progress.showProgress()
                                progress.waitForABit()
                                if policyNameClone == policyName {
                                    policyNameInitial = networkController.policyDetailed?.general?.name ?? ""
                                    let newPolicyName = "\(policyNameInitial)-1"
                                    print("No name provided - policy is:\(newPolicyName)")
                                    policyController.clonePolicy(xmlContent: xmlController.currentPolicyAsXML, server: server, policyName: newPolicyName, authToken: networkController.authToken)
                                } else {
                                    print("Cloning name is being used and is set as:\(policyNameClone)")
                                    policyController.clonePolicy(xmlContent: xmlController.currentPolicyAsXML, server: server, policyName: policyNameClone, authToken: networkController.authToken)
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "dog")
                                    Text("Clone")
                                }
                            }
                            .help("Create a copy of this policy on the server. Provide a clone name or a '-1' suffix will be used.")
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            TextField(policyName, text: $policyNameClone)
                                .textSelection(.enabled)
                        }
                    }
            
              
                
                // UI controls to trigger clonePerScript
                VStack(alignment: .leading, spacing: 6) {
                    // Filter input for the picker
                    TextField("Filter scripts...", text: $scriptFilter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 260)
                        .disabled(cloningInProgress)
                    
                    // Compute filtered scripts list from networkController.scripts
                    if !filteredScriptsForClone.isEmpty {
                        Picker(selection: $selectedScript, label: Text("Script").bold()) {
                            ForEach(filteredScriptsForClone, id: \.self) { script in
                                Text(script.name).tag(script)
                            }
                        }
                        .frame(maxWidth: 260)
                        .onAppear {
                            // default to first filtered script if none selected or current selection is not in filtered list
                            if (selectedScript.jamfId == 0 && selectedScript.name.isEmpty) || !filteredScriptsForClone.contains(selectedScript) {
                                selectedScript = filteredScriptsForClone.first!
                            }
                        }
                        .onChange(of: networkController.scripts) { _ in
                            if !filteredScriptsForClone.contains(selectedScript) {
                                selectedScript = filteredScriptsForClone.first ?? ScriptClassic(name: "", jamfId: 0)
                            }
                        }
                        .disabled(cloningInProgress)
                    } else {
                        Text("No scripts match filter")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Toggle("Use Parameters", isOn: $cloneUseParameters)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .disabled(cloningInProgress)
                        Toggle("All Parameters", isOn: $cloneAllParameters)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .disabled(cloningInProgress)
                    }
                    
                    Button(action: {
                        showingClonePerScriptConfirm = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.doc")
                            Text("Clone per Script")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(cloningInProgress || (selectedScript.jamfId == 0 && selectedScript.name.isEmpty))
                    .alert(isPresented: $showingClonePerScriptConfirm) {
                        // Determine readable identifier for confirmation text
                        let idText = selectedScript.jamfId == 0 ? selectedScript.name : String(selectedScript.jamfId)
                        return Alert(
                            title: Text("Clone per Script"),
                            message: Text("This will create clones based on script '\(idText)'. Proceed?"),
                            primaryButton: .destructive(Text("Yes, clone")) {
                                let identifier = selectedScript.jamfId == 0 ? selectedScript.name : String(selectedScript.jamfId)
                                clonePerScript(scriptIdentifier: identifier, useParameters: cloneUseParameters, allParameters: cloneAllParameters)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                // Clone-per-package button: only present when multiple packages are attached
            if networkController.packagesAssignedToPolicy.count > 1 {
                Button(action: {
                    showingClonePerPackageConfirm = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.on.doc")
                        Text("Clone per Package")
                    }
                }
                .help("Create one cloned policy per package currently assigned to this policy. Each clone will contain exactly one package.")
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(cloningInProgress)
                .alert(isPresented: $showingClonePerPackageConfirm) {
                    Alert(
                        title: Text("Clone per Package"),
                        message: Text("This will create \(networkController.packagesAssignedToPolicy.count) new policies (one per package). Are you sure?"),
                        primaryButton: .destructive(Text("Yes, clone")) {
                            clonePerPackage()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
                    
                    //              ##########################################################################
                    //              CLONE - END
                    //
//                }
                     Spacer()
                 
         }
            
            //  ##########################################################################
            //              UPDATE NAME
            //  ##########################################################################
            
            Divider()
            
            
                
                VStack(alignment: .leading) {
                    
//                    Text("Edit Names:").fontWeight(.bold)
                    
                    LazyVGrid(columns: layout.columnsFlexAdaptive, spacing: 20) {
                        
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
                            .help("Rename the policy on the server to the provided name.")
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                       
//                        }
//                    }
                    
                    //  ##########################################################################
                    //              UPDATE Self-Service
                    //  ##########################################################################
                    
//                    LazyVGrid(columns: layout.columnsFlex, spacing: 20) {
                        
                        HStack {
//                            TextField(policyName, text: $policyName)
//                                .textSelection(.enabled)
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateSSName(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, providedName: policyName, policyID: String(describing: policyID))
                                
                                networkController.separationLine()
                                print("Name Self-Service to:\(policyName)")
                            }) {
                                Text("Self-Service")
                            }
                            .help("Set the Self Service display name for this policy.")
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
                            .help("Enable Self Service for this policy.")
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
                        .help("Set the selected category for this policy.")
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(networkController.categories.isEmpty)
                        
                        //  ##########################################################################
                        //              UPDATE Trigger
                        //  ##########################################################################
                        
                            
                     
                            Divider()
                            Button(action: {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                
                                networkController.updateCustomTrigger(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, policyCustomTrigger: policyCustomTrigger, policyID: String(describing: policyID))
                                
                                networkController.separationLine()
                                print("Updating Policy Trigger to:\(policyName)")
                                
                            }) {
                                Text("Trigger")
                            }
                            .help("Update the custom trigger value for this policy on the server.")
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        TextField(policyCustomTrigger, text: $policyCustomTrigger)
                            .textSelection(.enabled)
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
            // Replace TabView with a segmented Picker + switched content to ensure clicks reliably switch tabs on macOS
            VStack(alignment: .leading, spacing: 8) {
                // Use explicit buttons to avoid segmented Picker quirks on macOS
                HStack(spacing: 6) {
                    ForEach(Array([(0, "Packages"), (1, "Scoping"), (2, "Scripts"), (3, "Self Service"), (4, "Triggers"), (5, "Clear Items")]), id: \.0) { idx, label in
                        Button(action: { selectedPolicyDetailTab = idx }) {
                            Text(label)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedPolicyDetailTab == idx ? .blue : .secondary)
                        .controlSize(.small)
                    }
                    Spacer()
                }
                .padding(.bottom, 6)
                
                // Switched content
                Group {
                    switch selectedPolicyDetailTab {
                    case 0:
                        PolicyPackageTabView(policyID: policyID, server: server, resourceType: selectedResourceType, packageSelection: packageSelection)
                    case 1:
                        PolicyScopeTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID, computerGroupSelection: $computerGroupSelection)
                    case 2:
                        PolicyScriptsTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID, computerGroupSelection: $computerGroupSelection)
                    case 3:
                        PolicySelfServiceTabView(server: server, resourceType: ResourceType.policyDetail, policyID: policyID )
                    case 4:
                        PolicyTriggersTabView(policyID: policyID, server: server, resourceType: ResourceType.policyDetail, trigger_login: networkController.policyDetailed?.general?.triggerLogin ?? false, trigger_checkin: networkController.policyDetailed?.general?.triggerCheckin ?? false, trigger_startup: networkController.policyDetailed?.general?.triggerStartup ?? false, trigger_enrollment_complete: networkController.policyDetailed?.general?.triggerEnrollmentComplete ?? false )
                    case 5:
                        PolicyRemoveItemsTabView(policyID: policyID, server: server, resourceType: ResourceType.policyDetail )
                    default:
                        PolicyPackageTabView(policyID: policyID, server: server, resourceType: selectedResourceType, packageSelection: packageSelection)
                    }
                }
                .frame(minHeight: 300)
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
                .help("Open this policy in the Jamf web interface in your default browser.")
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 6)
                Spacer()
            }
            .padding()
            .textSelection(.enabled)

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
               
               // print current computed trigger status for debugging
               print("Push trigger active? \(pushTriggerActiveWarningComputed)")
                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
            }
            
            Task {
                print("getPolicyAsXML - running get policy as xml function")
                let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: policyID, authToken: networkController.authToken)
                 print("Fetched policy XML length: \(policyAsXML.count)")
                 xmlController.readXMLDataFromString(xmlContent: xmlController.currentPolicyAsXML)
            }

            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                Task {
                      Task { try await networkController.getAllCategories() }
                }
            }

            if networkController.packages.count <= 1 {
                Task {
                     Task { try await networkController.getAllPackages() }
                }
            }

            if networkController.departments.count <= 1 {
                Task {
                      Task {
                        try await networkController.getAllDepartments()
                    }
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

        // Whenever the XML representation of the current policy changes (children often edit XML),
        // refresh the detailed policy from the server so the UI reflects server-side state.
        .onChange(of: xmlController.currentPolicyAsXML) { _ in
            Task {
                do {
                    let refreshedXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: policyID, authToken: networkController.authToken)
                    print("Refreshed detailed policy after XML change (len: \(refreshedXML.count))")
                } catch {
                    print("Failed to refresh detailed policy after XML change: \(error)")
                }
                print("Refreshing AEXML to reflect currentPolicyAsXML changes")
                xmlController.readXMLDataFromString(xmlContent: xmlController.currentPolicyAsXML)
            }
        }
        
        // Whenever the aexmlDoc representation of the current policy changes (children often edit XML),
        // refresh the detailed policy from the server so the UI reflects server-side state.
//        .onChange(of: xmlController.aexmlDoc) { _ in
//                    xmlController.readXMLDataFromString(xmlContent: xmlController.currentPolicyAsXML)
//                    print("Refreshed aexmlDoc policy after XML change")
//        }
        
        // Also attempt to refresh after potential network-based edits by observing the packagesAssignedToPolicy
        // array which many package actions mutate; this covers some edit paths that don't go through XML.
        
        .onChange(of: networkController.packagesAssignedToPolicy) { _ in
            Task {
                do {
                    try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                    print("Refreshed detailed policy after package assignments changed")
                } catch {
                    print("Failed to refresh detailed policy after package assignment change: \(error)")
                }
            }
        }

        // Listen for child tabs signalling that they modified the policy and request a refresh.
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("policyDidChange"))) { _ in
            Task {
                do {
                    try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                    print("Refreshed detailed policy in response to policyDidChange notification")
                } catch {
                    print("Failed to refresh detailed policy after policyDidChange notification: \(error)")
                }
            }
        }
    }
    
    func fetchData() {
        
        if  networkController.packages.isEmpty {
            print("No package data - fetching")
             Task { try await networkController.getAllPackages() }
            
        } else {
            print("package data is available")
        }
    }

    // Clone the current policy into multiple policies, one per attached package.
    // This function edits a local copy of the policy XML (does not persist changes to the original)
    // and calls the existing clone API for each package.
    func clonePerPackage() {
        Task {
            cloningInProgress = true
            defer { cloningInProgress = false }

            let baseName = policyNameClone.isEmpty ? (networkController.policyDetailed?.general?.name ?? policyName) : policyNameClone

            let packages = networkController.packagesAssignedToPolicy
            guard !packages.isEmpty else {
                print("No packages assigned to policy - nothing to clone per package")
                return
            }

            let xmlString = xmlController.currentPolicyAsXML
            guard !xmlString.isEmpty else {
                print("Current policy XML is empty - cannot clone")
                return
            }

            // Track generated names so we can guarantee uniqueness within this run
            var generatedNames = Set<String>()

            // Helper to sanitize names for inclusion in policy names (keep alphanumerics, spaces, - and _)
            func sanitizeForName(_ input: String) -> String {
                var allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
                // Normalize Unicode scalars to remove weird characters
                let filtered = input.unicodeScalars.map { allowed.contains($0) ? Character($0) : Character("-") }
                var out = String(filtered)
                // Collapse multiple dashes
                while out.contains("--") { out = out.replacingOccurrences(of: "--", with: "-") }
                // Trim whitespace and dashes
                out = out.trimmingCharacters(in: .whitespacesAndNewlines)
                out = out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                if out.isEmpty { out = "package" }
                // Limit length to avoid excessively long policy names
                if out.count > 200 { out = String(out.prefix(200)) }
                return out
            }

            let sanitizedBase = sanitizeForName(baseName)

            for pkg in packages {
                do {
                    // Work on a fresh AEXMLDocument so we don't mutate shared controller state
                    let data = Data(xmlString.utf8)
                    let doc = try AEXMLDocument(xml: data)

                    // Ensure package_configuration exists
                    if doc.root["package_configuration"].children.isEmpty {
                        _ = doc.root.addChild(name: "package_configuration")
                    }

                    // Remove any existing <packages> node and create a new one with single package
                    if doc.root["package_configuration"]["packages"].children.count > 0 {
                        doc.root["package_configuration"]["packages"].removeFromParent()
                    }
                    let packagesNode = doc.root["package_configuration"].addChild(name: "packages")
                    packagesNode.addChild(name: "size", value: "1")
                    let packageNode = packagesNode.addChild(name: "package")
                    packageNode.addChild(name: "id", value: String(pkg.jamfId))
                    packageNode.addChild(name: "name", value: pkg.name)
                    packageNode.addChild(name: "action", value: "Install")
                    packageNode.addChild(name: "fut", value: "false")
                    packageNode.addChild(name: "feu", value: "false")
                    packageNode.addChild(name: "update_autorun", value: "false")

                    // Prepare clone name - include package name (sanitized). Guarantee uniqueness by appending jamfId if needed
                    let sanitizedPkgName = sanitizeForName(pkg.name)
                    var candidateName = "\(sanitizedBase)-\(sanitizedPkgName)"
                    if generatedNames.contains(candidateName) {
                        candidateName += "-\(pkg.jamfId)"
                    }
                    generatedNames.insert(candidateName)
                    let newPolicyName = candidateName

                    // Call the existing clone routine (PolicyBrain)
                    policyController.clonePolicy(xmlContent: doc.root.xml, server: server, policyName: newPolicyName, authToken: networkController.authToken)
                    print("Requested clone for package \(pkg.name) as \(newPolicyName)")

                    // Small delay between requests to avoid hammering the server
                    try await Task.sleep(nanoseconds: 200_000_000)
                } catch {
                    print("Failed to create clone XML for package \(pkg.name): \(error)")
                }
            }
            print("clonePerPackage finished")
        }
    }

    // New: Clone the current policy into multiple policies based on the presence of a specified script.
    // - `scriptIdentifier`: either a Jamf script ID (numeric string) or a script name to match.
    // - `useParameters`: when true, create one clone per non-empty parameter value found in matching scripts.
    // - `allParameters`: when true, each generated clone will include all matching script instances with all parameters preserved; otherwise clones include only the single script instance with only the parameter used for naming.
    func clonePerScript(scriptIdentifier: String, useParameters: Bool = true, allParameters: Bool = false) {
        Task {
            cloningInProgress = true
            defer { cloningInProgress = false }

            let xmlString = xmlController.currentPolicyAsXML
            guard !xmlString.isEmpty else {
                print("Current policy XML is empty - cannot clone per script")
                return
            }

            // Determine if identifier is numeric (Jamf ID) or a name
            let identifierInt = Int(scriptIdentifier)
            let identifierName = scriptIdentifier

            // Parse XML once to discover matching script nodes
            do {
                let data = Data(xmlString.utf8)
                let doc = try AEXMLDocument(xml: data)

                let scriptsNode = doc.root["scripts"]
                if scriptsNode.children.isEmpty {
                    print("No <scripts> section found in policy XML")
                    return
                }

                // Gather matching script nodes (we'll capture their XML string and their parameter sets)
                struct MatchedScript {
                    let xmlString: String
                    let id: String
                    let name: String
                    let parameters: [(key: String, value: String)]
                }

                var matchedScripts: [MatchedScript] = []

                for scriptChild in scriptsNode.children where scriptChild.name == "script" {
                    let sid = scriptChild["id"].string
                    let sname = scriptChild["name"].string

                    var isMatch = false
                    if let identifierInt = identifierInt, Int(sid) == identifierInt {
                        isMatch = true
                    } else if !identifierName.isEmpty && sname == identifierName {
                        isMatch = true
                    }

                    if !isMatch { continue }

                    // Collect parameter elements (parameterX) that are non-empty
                    var params: [(String, String)] = []
                    for child in scriptChild.children {
                        if child.name.lowercased().hasPrefix("parameter") {
                            let val = child.string.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !val.isEmpty {
                                params.append((child.name, val))
                            }
                        }
                    }

                    matchedScripts.append(MatchedScript(xmlString: scriptChild.xml, id: sid, name: sname, parameters: params))
                }

                guard !matchedScripts.isEmpty else {
                    print("No matching scripts found for identifier: \(scriptIdentifier)")
                    return
                }

                // Determine clones to create
                // If useParameters is true, we will create one clone for each parameter entry across all matched scripts
                // If useParameters is false, we will create one clone per matched script instance
                var cloneJobs: [(scriptIndex: Int, parameter: (key: String, value: String)?)] = []
                if useParameters {
                    for (idx, ms) in matchedScripts.enumerated() {
                        if ms.parameters.isEmpty {
                            // If there are no parameters but useParameters requested, still create a single clone (fallback)
                            cloneJobs.append((scriptIndex: idx, parameter: nil))
                        } else {
                            for param in ms.parameters {
                                cloneJobs.append((scriptIndex: idx, parameter: param))
                            }
                        }
                    }
                } else {
                    for (idx, _) in matchedScripts.enumerated() {
                        cloneJobs.append((scriptIndex: idx, parameter: nil))
                    }
                }

                if cloneJobs.isEmpty {
                    print("No clone jobs found (no parameters and useParameters requested)")
                    return
                }

                // Helper to sanitize names
                func sanitizeForName(_ input: String) -> String {
                    var allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
                    let filtered = input.unicodeScalars.map { allowed.contains($0) ? Character($0) : Character("-") }
                    var out = String(filtered)
                    while out.contains("--") { out = out.replacingOccurrences(of: "--", with: "-") }
                    out = out.trimmingCharacters(in: .whitespacesAndNewlines)
                    out = out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                    if out.isEmpty { out = "script" }
                    if out.count > 200 { out = String(out.prefix(200)) }
                    return out
                }

                var generatedNames = Set<String>()

                // For each clone job, construct a modified XML and request a clone
                for job in cloneJobs {
                    do {
                        let dataForClone = Data(xmlString.utf8)
                        let cloneDoc = try AEXMLDocument(xml: dataForClone)

                        // Remove existing scripts node entirely and replace with our constructed one
                        if !cloneDoc.root["scripts"].children.isEmpty {
                            cloneDoc.root["scripts"].removeFromParent()
                        }

                        let newScriptsNode = cloneDoc.root.addChild(name: "scripts")

                        if allParameters {
                            // Include all matched script instances with all parameters preserved
                            for ms in matchedScripts {
                                // Parse the matched script fragment to AEXML and append as a child
                                if let msDoc = try? AEXMLDocument(xml: Data(ms.xmlString.utf8)) {
                                    // msDoc.root is the <script> node
                                    let scriptElement = newScriptsNode.addChild(name: "script")
                                    // copy children from msDoc.root
                                    for child in msDoc.root.children {
                                        _ = scriptElement.addChild(name: child.name, value: child.string)
                                    }
                                } else {
                                    // fallback: create an id/name/priority stub
                                    let scriptElement = newScriptsNode.addChild(name: "script")
                                    _ = scriptElement.addChild(name: "id", value: ms.id)
                                    _ = scriptElement.addChild(name: "name", value: ms.name)
                                }
                            }
                            newScriptsNode.addChild(name: "size", value: String(matchedScripts.count))

                            // Derive name: if parameter exists in job, use it for naming, otherwise use a combined name
                            var candidateName = "\(policyNameClone.isEmpty ? (networkController.policyDetailed?.general?.name ?? policyName) : policyNameClone)"
                            if let param = job.parameter {
                                candidateName += "-\(sanitizeForName(param.value))"
                            } else {
                                // combine script names
                                let joined = matchedScripts.map { sanitizeForName($0.name) }.joined(separator: "-")
                                candidateName += "-\(joined)"
                            }
                            var finalName = sanitizeForName(candidateName)
                            if generatedNames.contains(finalName) {
                                finalName += "-\(UUID().uuidString.prefix(6))"
                            }
                            generatedNames.insert(finalName)

                            policyController.clonePolicy(xmlContent: cloneDoc.root.xml, server: server, policyName: finalName, authToken: networkController.authToken)
                            print("Requested clone (allParameters) as \(finalName)")

                        } else {
                            // Only include a single instance of the script with only the selected parameter set (or no parameters if none)
                            let ms = matchedScripts[job.scriptIndex]
                            let scriptElement = newScriptsNode.addChild(name: "script")
                            // basic fields
                            _ = scriptElement.addChild(name: "id", value: ms.id)
                            _ = scriptElement.addChild(name: "name", value: ms.name)

                            // attempt to copy priority if present in original matched xml (safe, non-throwing)
                            var priorityValue: String? = nil
                            if ms.xmlString.range(of: "<priority>") != nil {
                                if let doc = try? AEXMLDocument(xml: Data(("<root>\(ms.xmlString)</root>").utf8)) {
                                    priorityValue = doc.root["script"]["priority"].string
                                }
                            }
                            if let pv = priorityValue, !pv.isEmpty {
                                _ = scriptElement.addChild(name: "priority", value: pv)
                            }

                            // Add only the parameter used for naming (when parameter provided), otherwise add no additional parameter elements
                            if let param = job.parameter {
                                _ = scriptElement.addChild(name: param.key, value: param.value)
                            } else {
                                // If no parameter and useParameters was true but script had none, copy all parameters (fallback)
                                if ms.parameters.isEmpty {
                                    // parse ms.xmlString and copy all children except id/name
                                    if let msDoc = try? AEXMLDocument(xml: Data(ms.xmlString.utf8)) {
                                        for child in msDoc.root.children {
                                            if child.name != "id" && child.name != "name" && child.name != "priority" {
                                                _ = scriptElement.addChild(name: child.name, value: child.string)
                                            }
                                        }
                                    }
                                }
                            }

                            newScriptsNode.addChild(name: "size", value: "1")

                            // Determine clone name
                            var base = policyNameClone.isEmpty ? (networkController.policyDetailed?.general?.name ?? policyName) : policyNameClone
                            var candidateName: String
                            if let param = job.parameter {
                                candidateName = "\(sanitizeForName(param.value))"
                            } else {
                                // fallback to script name or id
                                candidateName = sanitizeForName(ms.name.isEmpty ? ms.id : ms.name)
                            }
                            var finalName = sanitizeForName("\(base)-\(candidateName)")
                            if generatedNames.contains(finalName) {
                                finalName += "-\(UUID().uuidString.prefix(6))"
                            }
                            generatedNames.insert(finalName)

                            policyController.clonePolicy(xmlContent: cloneDoc.root.xml, server: server, policyName: finalName, authToken: networkController.authToken)
                            print("Requested clone for script parameter \(String(describing: job.parameter?.value)) as \(finalName)")
                        }

                        // Small delay between requests
                        try await Task.sleep(nanoseconds: 200_000_000)

                    } catch {
                        print("Failed to prepare clone XML for job: \(job). Error: \(error)")
                    }
                }

                print("clonePerScript finished - created \(cloneJobs.count) clones (requested)")

            } catch {
                print("Failed to parse policy XML for clonePerScript: \(error)")
            }
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
