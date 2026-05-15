//
//  CreatePolicyView.swift
//  Manifesto
//
//  Created by Amos Deane on 06/08/2024.
//

import SwiftUI

@available(iOS 17.0, macOS 13.0, *)

struct CreatePolicyView: View {
    
    var selectedResourceType: ResourceType = ResourceType.package
    var server: String
    
    //              ################################################################################
    //              EnvironmentObject
    //              ################################################################################
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var policyController: PolicyBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var importExportBrain: ImportExportBrain
    @EnvironmentObject var networkController: NetBrain
    
    //              ################################################################################
    //              Variables
    //              ################################################################################
    
    @State private var searchText = ""
    @State private var showingWarning = false
    @State var enableDisable: Bool = true
    @State private var selfServiceEnable = true
    @State private var createDepartmentIsChecked = false
    @State private var enableSelfService = false
    
    //              ################################################################################
    //              categories
    //              ################################################################################
    
    @State var categoryName = ""
    @State private var categoryID = ""
    @State var categories: [Category] = []
    
    //              ################################################################################
    //              computers
    //              ################################################################################
    
    @State private var computers: [ Computer ] = []
    @State var computerID = ""
    @State var computerUDID = ""
    @State var computerName = ""
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    // ################################################################################
    // New items
    // ################################################################################
    
    @State var newPolicyName = ""
    // @State var departmentName: String = ""
    @State var newCategoryName: String = ""
    @State var newGroupName: String = ""
    @State var newPolicyId = "0"
    @State private var importFilePath: String = ""

    //              ################################################################################
    //              Packages
    //              ################################################################################
    
    @State private var packageSelection = Set<Package>()
    @State private var packagesAssignedToPolicy: [ Package ] = []
    @State private var packageID = "0"
    @State private var packageName = ""
    
    // Sorting for package selection list
    private enum PackageSortField: Hashable { case name, id }
    @State private var packageSortBy: PackageSortField = .name
    @State private var packageSortAscending: Bool = true

    // Table selection (UUID-based) for macOS Table; we synchronize this with packageMultiSelection (Set<Int>)
    @State private var packageSelectionIDs = Set<UUID>()

    // ################################################################################
    // Scripts
    // ################################################################################
    
    @State var scriptName = ""
    @State var scriptID = ""
    
    // ################################################################################
    // Selections
    // ################################################################################
    
    @State var selectedComputer: Computer = Computer(id: 0, name: "")
    
    // ################################################################################
    // Selection IDs used by Pickers to avoid mismatched tag/selection warnings
    // ################################################################################

    @State var selectedCategoryId: Int? = nil
    @State var selectedDepartmentId: Int? = nil
    @State var selectedScriptId: Int? = nil
    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
    // Use jamfId (Int) for multi-selection so List selection matches the id used by the data source
    @State var packageMultiSelection = Set<Int>()
    @State var iconMultiSelection = Set<String>()
    @State var selectedIconString = ""
    @State var iconFilter: String = ""
    @State var categoryFilter: String = ""
    @State var departmentFilter: String = ""
    @State var scriptFilter: String = ""

    // Use optional ID selection for icon picker
    @State var selectedIconId: Int? = nil
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    //      ################################################################################
    //      Script parameters
    //      ################################################################################
    
    @State var scriptParameter4: String = "Parameter 1"
    
    @State var scriptParameter5: String = "Parameter 2"
    
    @State var scriptParameter6: String = "Parameter 3"
        
    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())

    // Policy templates stored per-server
    struct PolicyTemplate: Codable, Identifiable, Equatable {
        var id: UUID = UUID()
        var name: String
        var policyName: String
        var selectedPackageIds: [Int]
        var categoryId: Int?
        var departmentId: Int?
        var scriptId: Int?
        var selfServiceEnabled: Bool
        var iconId: Int?
    }

    @State private var templates: [PolicyTemplate] = []
    @State private var newTemplateName: String = ""
    @State private var editingTemplate: PolicyTemplate? = nil
    @State private var previewXML: String = ""
    @State private var showPreviewSheet: Bool = false
    @State private var templatesExpanded: Bool = false
    
    
        
    var body: some View {
        
        VStack(alignment: .leading) {
            
            ScrollView {
                //
                VStack(alignment: .leading, spacing: 20) {
                    
                    // New header: nicer title, subtitle and quick actions
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create Policy")
                                .font(.title)
                                .fontWeight(.semibold)
//                                                            .foregroundColor(.secondary)

                            //                            Text("Create categories, groups, packages and scripts")
                            //                                .font(.subheadline)
                            //                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Button(action: {
                                Task {
                                    try await networkController.getAllCategories()
                                    try await networkController.getAllDepartments()
                                }
                                
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                // open import/export filename if available
                                // keep as info-only quick action
                            }) {
                                Image(systemName: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
                    
                    
                    
                        
                }
                //                        Spacer()
                
                
                
                if networkController.packages.count > 0 {
                    packagesSection
                }
            }
            //              ################################################################################
            //              Toolbar
            //              ################################################################################
#if os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        print("Refresh")
                        print("Icon selection id is:\(String(describing: selectedIconId))")
                        
                        Task {
                            try await networkController.getAllPackages()
                            try await networkController.getAllScripts()
                            try await networkController.getAllDepartments()
                            try await networkController.getAllCategories()
                        }
                        
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            
#endif
            
            //  ################################################################################
            //              Toolbar - END
            //  ################################################################################
            
            Divider()
            
            //  ################################################################################
            //              selections
            //  ################################################################################
            
            // Selection row always shown under header so users see selection count
            HStack(spacing: 8) {
                Text("Selection:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("Selected: \(packageMultiSelection.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            Divider()
            
            if packageMultiSelection.isEmpty {
                Text("No packages selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
            } else {
                List(Array(packageMultiSelection), id: \.self) { selectedJamfId in
                    Text(networkController.packages.first(where: { $0.jamfId == selectedJamfId })?.name ?? "")
                }
                .frame(height: selectionListHeight)
            }
            
            VStack {
                
                Group {
                    
                    // ####################################################
                    // CREATE NEW POLICY - with multiple packages
                    // ####################################################
                    
                    LazyVGrid(columns: columns, spacing: 5) {
                        
                        HStack {
                            Image(systemName:"hammer")
                            TextField("Policy Name", text: $newPolicyName)
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                
                                // Resolve selection values from the networkController arrays using the selected IDs
                                // Find the category by jamfId (Int) which is what the Picker tags use
                                let categoryNameLocal = networkController.categories.first(where: { $0.jamfId == selectedCategoryId })?.name ?? ""
                                let departmentNameLocal = networkController.departments.first(where: { $0.jamfId == selectedDepartmentId })?.name ?? ""
                                let iconLocal = networkController.allIconsDetailed.first(where: { $0.id == selectedIconId })
                                let iconIdString = String(iconLocal?.id ?? 0)
                                let iconNameLocal = iconLocal?.name ?? ""
                                let iconUrlLocal = iconLocal?.url ?? ""
                                let scriptLocal = networkController.scripts.first(where: { $0.jamfId == selectedScriptId })
                                let scriptNameLocal = scriptLocal?.name ?? ""
                                let scriptIdString = String(scriptLocal?.jamfId ?? 0)
                                
                                // Prepare selected package ids to pass to XML builder
                                let selectedPackageIdsToAdd = Set(packageMultiSelection)
                                
                                xmlController.createNewPolicyViaAEXML(authToken: networkController.authToken,
                                                                      server: server,
                                                                      policyName: newPolicyName,
                                                                      policyID: newPolicyId,
                                                                      scriptName: scriptNameLocal,
                                                                      scriptID: scriptIdString,
                                                                      packageName: packageName,
                                                                      packageID: packageID,
                                                                      SelfServiceEnabled: enableSelfService,
                                                                      department: departmentNameLocal,
                                                                      category: categoryNameLocal,
                                                                      enabledStatus: enableDisable,
                                                                      iconId: iconIdString,
                                                                      iconName: iconNameLocal,
                                                                      iconUrl: iconUrlLocal,
                                                                      selectedPackageIds: selectedPackageIdsToAdd, packages: networkController.packages)
                                
                                layout.separationLine()
                                print("Creating New Policy:\(newPolicyName)")
                            }) {
                                Text("Create Policy")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(newPolicyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                            Button(action: {
                                // Build preview XML and show sheet
                                let selectedPackageIdsToAdd = Set(packageMultiSelection)
                                let categoryNameLocal = networkController.categories.first(where: { $0.jamfId == selectedCategoryId })?.name ?? ""
                                let departmentNameLocal = networkController.departments.first(where: { $0.jamfId == selectedDepartmentId })?.name ?? ""
                                let iconLocal = networkController.allIconsDetailed.first(where: { $0.id == selectedIconId })
                                let iconIdString = String(iconLocal?.id ?? 0)
                                let iconNameLocal = iconLocal?.name ?? ""
                                let iconUrlLocal = iconLocal?.url ?? ""
                                let scriptLocal = networkController.scripts.first(where: { $0.jamfId == selectedScriptId })
                                let scriptNameLocal = scriptLocal?.name ?? ""
                                let scriptIdString = String(scriptLocal?.jamfId ?? 0)
                                
                                previewXML = xmlController.buildPolicyXML(policyName: newPolicyName, policyID: newPolicyId, scriptName: scriptNameLocal, scriptID: scriptIdString, selectedPackageIds: selectedPackageIdsToAdd, packages: networkController.packages, SelfServiceEnabled: enableSelfService, department: departmentNameLocal, category: categoryNameLocal, enabledStatus: enableDisable, iconId: iconIdString, iconName: iconNameLocal, iconUrl: iconUrlLocal)
                                showPreviewSheet = true
                            }) {
                                Text("Preview XML")
                            }

                            // Open in Browser - refresh policies first and estimate new policy ID
                            Button(action: {
                                progress.showProgress()
                                Task {
                                    // Refresh policy list from server before estimating next ID
                                    do {
                                        try await networkController.getAllPolicies(server: server)
                                    } catch {
                                        print("Failed to refresh policies before opening in browser: \(error)")
                                    }

                                    // Combine any available policy lists
                                    let combined = (networkController.allPoliciesConverted + networkController.policies)

                                    // First attempt: try to find a policy by name (exact or contains) matching the policy name the user entered.
                                    let trimmedName = newPolicyName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    var opened = false
                                    if !trimmedName.isEmpty {
                                        // Prefer exact match (case-insensitive), then contains
                                        if let exact = combined.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }), let id = exact.jamfId {
                                            let base = server.trimmingCharacters(in: .whitespacesAndNewlines)
                                            let uiURL = base.hasSuffix("/") ? "\(base)policies.html?id=\(id)&o=r" : "\(base)/policies.html?id=\(id)&o=r"
                                            print("Found policy by exact name: opening id \(id) -> \(uiURL)")
                                            layout.openURL(urlString: uiURL, requestType: "policies")
                                            opened = true
                                        } else if let contain = combined.first(where: { $0.name.localizedCaseInsensitiveContains(trimmedName) }), let id = contain.jamfId {
                                            let base = server.trimmingCharacters(in: .whitespacesAndNewlines)
                                            let uiURL = base.hasSuffix("/") ? "\(base)policies.html?id=\(id)&o=r" : "\(base)/policies.html?id=\(id)&o=r"
                                            print("Found policy by partial name: opening id \(id) -> \(uiURL)")
                                            layout.openURL(urlString: uiURL, requestType: "policies")
                                            opened = true
                                        }
                                    }

                                    if !opened {
                                        // No match by name; fall back to numeric estimate based on the highest known ID + 1 (Jamf generally increments IDs)
                                        let idSet = Set(combined.compactMap { $0.jamfId })
                                        let maxID = idSet.max() ?? 0
                                        let estimated = maxID + 1

                                        var base = server.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if base.hasSuffix("/") { base.removeLast() }
                                        func makeURL(_ id: Int) -> String { "\(base)/policies.html?id=\(id)&o=r" }

                                        // Silent lookup: probe estimated id and neighbouring ids; if any exists open that one.
                                        let maxAttempts = 5
                                        let candidates: [Int] = [estimated] + (1...maxAttempts).flatMap { off in [estimated + off, estimated - off] }

                                        for id in candidates {
                                            if id <= 0 { continue }
                                            let uiURL = makeURL(id)
                                            let exists = await checkURLExists(uiURL)
                                            if exists {
                                                print("Opening nearby policy UI at id \(id): \(uiURL)")
                                                layout.openURL(urlString: uiURL, requestType: "policies")
                                                opened = true
                                                break
                                            }
                                        }

                                        if !opened {
                                            // Fallback: open estimated URL anyway
                                            let uiURL = makeURL(estimated)
                                            print("Fallback: opening estimated policy URL: \(uiURL)")
                                            layout.openURL(urlString: uiURL, requestType: "policies")
                                        }
                                    }

                                    // End progress indicator
                                    progress.endProgress()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari")
                                    Text("Open in Browser")
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Open the estimated new policy in the Jamf web UI (tries gaps and neighbours before fallback).")
                            
                            Toggle(isOn: $createDepartmentIsChecked) {
                                Text("New Dept")
                            }
                            .toggleStyle(.checkbox)
                            
                            Toggle(isOn: $enableSelfService) {
                                Text("Self Service")
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                    
#if os(macOS)
                    // File import controls - Select a local XML file and import as a policy
                    
                    DisclosureGroup("Import Policy from XML") {
                        
                        //                    LazyVGrid(columns: layout.column, spacing: 5) {
                        //
                        //                        VStack(alignment: .leading) {
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                let openURL = importExportBrain.showOpenPanel()
                                print("openURL path is:\(String(describing: openURL?.path ?? ""))")
                                if let url = openURL {
                                    self.importFilePath = url.path
                                    // Import the file contents into the shared ImportExportBrain so other views can access it too
                                    importExportBrain.selectedFilename = url.lastPathComponent
                                    do {
                                        importExportBrain.importedString = try String(contentsOf: url, encoding: .utf8)
                                        print("Imported file length: \(importExportBrain.importedString.count)")
                                    } catch {
                                        print("Failed to read file: \(error)")
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc")
                                    Text("Select File")
                                }
                            }
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                // Use the imported string as the XML content and POST it as a new policy
                                let xml = importExportBrain.importedString
                                if xml.isEmpty {
                                    print("No XML imported - cannot import policy")
                                } else {
                                    xmlController.createPolicyManual(xmlContent: xml, server: server, resourceType: ResourceType.policyDetail, policyName: newPolicyName, authToken: networkController.authToken)
                                    layout.separationLine()
                                    print("Import Policy requested for file:\(importExportBrain.selectedFilename)")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import Policy")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                            
                            
                            // show selected file name
                            if !importExportBrain.selectedFilename.isEmpty {
                                Text("Selected: \(importExportBrain.selectedFilename)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        //                    }
                        //                    }
                    }
                    
                    // Templates section
                    DisclosureGroup("Policy Templates", isExpanded: $templatesExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Template name", text: $newTemplateName)
                                Button("Save Template") {
                                    saveCurrentAsTemplate()
                                }
                                .disabled(newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                Spacer()
                                Button("Export") { exportTemplatesToDownloads() }
                                    .buttonStyle(.bordered)
                                Button("Import") { importTemplatesFromFile() }
                                    .buttonStyle(.bordered)
                            }
                            
                            if templates.isEmpty {
                                Text("No templates saved for this server").foregroundColor(.secondary)
                            } else {
                                ForEach(templates) { t in
                                    HStack {
                                        Text(t.name)
                                        Spacer()
                                        Button("Apply") { applyTemplate(t) }
                                            .buttonStyle(.bordered)
                                        Button("Edit") { editingTemplate = t }
                                            .buttonStyle(.bordered)
                                        Button("Delete") { deleteTemplate(t) }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    // Edit sheet for templates
                    .sheet(item: $editingTemplate) { tpl in
                        TemplateEditView(template: tpl, onSave: { updated in
                            if let idx = templates.firstIndex(where: { $0.id == updated.id }) {
                                templates[idx] = updated
                            } else {
                                templates.append(updated)
                            }
                            persistTemplates()
                            editingTemplate = nil
                        }, onCancel: {
                            editingTemplate = nil
                        })
                    }
                    
#endif
                    
                    
                    VStack(alignment: .leading) {
                        
                        LazyVGrid(columns: layout.columnsFlexAdaptiveMedium, spacing: 20) {
                            
                            HStack {
                                Text("Self-Service").bold()
                                if #available(macOS 14.0, *) {
                                    Toggle("", isOn: $selfServiceEnable)
                                        .toggleStyle(SwitchToggleStyle(tint: .red))
                                        .onChange(of: enableDisable) {
                                            print("Self-Service is currently:\(selfServiceEnable)")
                                        }
                                } else {
                                    // Fallback on earlier versions
                                    Toggle("", isOn: $selfServiceEnable)
                                        .toggleStyle(SwitchToggleStyle(tint: .red))
                                }
                            }
                        }
                    }
                }
                
                // ##########################################################################################
                //                        Icons
                // ##########################################################################################
                
                if !networkController.allIconsDetailed.isEmpty {
                    Divider()
                    
                    // Prominent Icons filter header so it's always visible
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Icons").bold().padding(.bottom, 4)
                        HStack {
                            TextField("Filter icons", text: $iconFilter)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                            if !iconFilter.isEmpty {
                                Button(action: { iconFilter = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(6)
                    }
                }
                
                //  ################################################################################
                //              selections
                //  ################################################################################
                
                // ##########################################################################################
                //                        Icons - selector (compact horizontal strip)
                // ##########################################################################################
                
                LazyVGrid(columns: columns, spacing: 30) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Compact horizontal icon selector (30x30)
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 8) {
                                ForEach(networkController.allIconsDetailed.filter { icon in
                                    let trimmed = iconFilter.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty { return true }
                                    return icon.name.localizedCaseInsensitiveContains(trimmed)
                                }, id: \.id) { icon in
                                    AsyncImage(url: URL(string: icon.url)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        case .failure(_):
                                            Image(systemName: "photo").resizable().scaledToFit()
                                        default:
                                            ProgressView()
                                        }
                                    }
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(selectedIconId == icon.id ? Color.blue : Color.clear, lineWidth: 2))
                                    .onTapGesture {
                                        selectedIconId = icon.id
                                        selectedIconString = icon.name
                                        selectedIconList = icon
                                    }
                                    .help(icon.name)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onAppear {
                            if !networkController.allIconsDetailed.isEmpty {
                                selectedIconId = networkController.allIconsDetailed.first?.id
                                selectedIconString = networkController.allIconsDetailed.first?.name ?? ""
                                selectedIconList = networkController.allIconsDetailed.first ?? Icon(id: 0, url: "", name: "")
                            } else {
                                selectedIconId = nil
                                selectedIconString = ""
                            }
                        }
                        .onChange(of: networkController.allIconsDetailed) { newIcons in
                            if !newIcons.isEmpty {
                                selectedIconId = newIcons.first?.id
                                selectedIconString = newIcons.first?.name ?? ""
                                selectedIconList = newIcons.first ?? Icon(id: 0, url: "", name: "")
                            } else {
                                selectedIconId = nil
                                selectedIconString = ""
                            }
                        }
                    }
                }
                
                // ##########################################################################################
                //                        Category
                // ##########################################################################################
                Divider()
                
                if !networkController.categories.isEmpty {
                    Group {
                        LazyVGrid(columns: columns, spacing: 30) {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Filter categories", text: $categoryFilter)
                                    .textFieldStyle(.roundedBorder)
                                
                                        Picker(selection: $selectedCategoryId, label: Text("Category")) {
                                            // Allow explicit "None" option
                                            Text("None").tag(nil as Int?)
                                            // Use jamfId (Int) for tags so the Picker selection (an Int?) matches the tags.
                                            ForEach(networkController.categories.filter { cat in
                                                categoryFilter.isEmpty ? true : cat.name.localizedCaseInsensitiveContains(categoryFilter)
                                            }, id: \.jamfId) { category in
                                                Text(category.name).tag(category.jamfId as Int?)
                                            }
                                        }
                                .onChange(of: networkController.categories) { newCategories in
                                    if selectedCategoryId == nil {
                                        selectedCategoryId = newCategories.first?.jamfId
                                    }
                                }
                            }
                        }
                    }
                }
                
                // ##########################################################################################
                //                        Department
                // ##########################################################################################
                Divider()
                
                if !networkController.departments.isEmpty {
                    Group {
                        LazyVGrid(columns: columns, spacing: 30) {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Filter departments", text: $departmentFilter)
                                    .textFieldStyle(.roundedBorder)
                                
                                      Picker(selection: $selectedDepartmentId, label: Text("Department:")) {
                                          Text("None").tag(nil as Int?)
                                          ForEach(networkController.departments.filter { dept in
                                             departmentFilter.isEmpty ? true : dept.name.localizedCaseInsensitiveContains(departmentFilter)
                                          }, id: \.jamfId) { department in
                                              Text(department.name).tag(department.jamfId as Int?)
                                          }
                                      }
                            }
                        }
                    }
                }
                Divider()
                
                if !networkController.scripts.isEmpty {
                    Group {
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Filter scripts", text: $scriptFilter)
                                    .textFieldStyle(.roundedBorder)
                                
                                Picker(selection: $selectedScriptId, label: Text("Scripts")) {
                                    Text("None").tag(nil as Int?)
                                    ForEach(networkController.scripts.filter { s in
                                        scriptFilter.isEmpty ? true : s.name.localizedCaseInsensitiveContains(scriptFilter)
                                    }, id: \.jamfId) { script in
                                        Text(script.name).tag(script.jamfId as Int?)
                                    }
                                }
                                .onChange(of: networkController.scripts) { newScripts in
                                    if selectedScriptId == nil {
                                        selectedScriptId = newScripts.first?.jamfId
                                    }
                                }
                            }
                        }
                        
                        // ######################################################################################
                    }
                }
            }
            
            // ######################################################################################
            //                        onAppear
            // ######################################################################################
            .onAppear {
                print("CreateView appeared - connecting")
                handleConnect()
                loadTemplates()
            }
            .sheet(isPresented: $showPreviewSheet) {
                VStack(alignment: .leading) {
                    Text("Preview XML").font(.headline).padding()
                    ScrollView { Text(previewXML).font(.system(.body, design: .monospaced)).padding() }
                    HStack {
                        Spacer()
                        Button("Export") {
#if os(macOS)
                            if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                                let filename = "policy-preview-\(Int(Date().timeIntervalSince1970)).xml"
                                let dest = downloads.appendingPathComponent(filename)
                                do {
                                    try previewXML.data(using: .utf8)?.write(to: dest)
                                    NSWorkspace.shared.activateFileViewerSelecting([dest])
                                } catch {
                                    print("Failed to write preview XML: \(error)")
                                }
                            }
#endif
                        }
                        Button("Close") { showPreviewSheet = false }
                    }
                    .padding()
                }
                .frame(minWidth: 600, minHeight: 400)
            }
            .padding()
            
            if progress.showProgressView == true {
                ProgressView {
                    Text("Processing")
                        .padding()
                }
            } else {
                Text("")
            }
        }
    }
    
    // MARK: - MAIN VIEW
    
    
    func handleConnect() {
        print("Running handleConnect.")
        networkController.fetchStandardData()
        if networkController.allIconsDetailed.count <= 1 {
            print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 1000)
        } else {
            print("getAllIconsDetailed has already run")
            print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
        }
    }

    

    // MARK: - Template persistence (file-based under Application Support)
    private var templatesDirectoryURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        return appSupport.appendingPathComponent("Man1fest0", isDirectory: true)
    }

    private func templatesFileURL() -> URL? {
        guard let dir = templatesDirectoryURL else { return nil }
        // encode server to filename-safe string
        let encoded = Data(server.utf8).base64EncodedString()
        return dir.appendingPathComponent("templates-\(encoded).json")
    }

    private func ensureTemplatesDirectory() {
        guard let dir = templatesDirectoryURL else { return }
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func loadTemplates() {
        guard let file = templatesFileURL() else { return }
        if FileManager.default.fileExists(atPath: file.path) {
            if let data = try? Data(contentsOf: file), let decoded = try? JSONDecoder().decode([PolicyTemplate].self, from: data) {
                templates = decoded
                // Expand templates section if templates exist, otherwise keep collapsed
                templatesExpanded = !templates.isEmpty
            }
        } else {
            templates = []
            templatesExpanded = false
        }
    }

    private func persistTemplates() {
        ensureTemplatesDirectory()
        guard let file = templatesFileURL() else { return }
        if let encoded = try? JSONEncoder().encode(templates) {
            try? encoded.write(to: file, options: .atomic)
        }
    }

    private func saveCurrentAsTemplate() {
        let tpl = PolicyTemplate(name: newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines), policyName: newPolicyName, selectedPackageIds: Array(packageMultiSelection), categoryId: selectedCategoryId, departmentId: selectedDepartmentId, scriptId: selectedScriptId, selfServiceEnabled: enableSelfService, iconId: selectedIconId)
        templates.append(tpl)
        persistTemplates()
        newTemplateName = ""
    }

    private func applyTemplate(_ t: PolicyTemplate) {
        newPolicyName = t.policyName
        packageMultiSelection = Set(t.selectedPackageIds)
        selectedCategoryId = t.categoryId
        selectedDepartmentId = t.departmentId
        selectedScriptId = t.scriptId
        enableSelfService = t.selfServiceEnabled
        selectedIconId = t.iconId
    }

    private func deleteTemplate(_ t: PolicyTemplate) {
        templates.removeAll { $0.id == t.id }
        persistTemplates()
    }

    // Export all templates to Downloads for sharing/backups
    private func exportTemplatesToDownloads() {
        guard !templates.isEmpty else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(templates) else { return }
        #if os(macOS)
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let filename = "policy-templates-\(Date().timeIntervalSince1970).json"
            let dest = downloads.appendingPathComponent(filename)
            do {
                try data.write(to: dest)
                NSWorkspace.shared.activateFileViewerSelecting([dest])
            } catch {
                print("Failed to export templates: \(error)")
            }
        }
        #else
        // On other platforms save to Documents
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filename = "policy-templates-\(Date().timeIntervalSince1970).json"
            let dest = docs.appendingPathComponent(filename)
            try? data.write(to: dest)
        }
        #endif
    }

    // Import templates from a JSON file and merge (avoid duplicates by name)
    private func importTemplatesFromFile() {
        #if os(macOS)
        if let url = importExportBrain.showOpenPanel() {
            do {
                let data = try Data(contentsOf: url)
                if let decoded = try? JSONDecoder().decode([PolicyTemplate].self, from: data) {
                    // merge: if same name exists, replace
                    for tpl in decoded {
                        if let idx = templates.firstIndex(where: { $0.name == tpl.name }) {
                            templates[idx] = tpl
                        } else {
                            templates.append(tpl)
                        }
                    }
                    persistTemplates()
                } else if let single = try? JSONDecoder().decode(PolicyTemplate.self, from: data) {
                    if let idx = templates.firstIndex(where: { $0.name == single.name }) {
                        templates[idx] = single
                    } else {
                        templates.append(single)
                    }
                    persistTemplates()
                }
            } catch {
                print("Failed to import templates: \(error)")
            }
        }
        #endif
    }

    var searchResults: [Package] {
        if searchText.isEmpty {
            return networkController.packages
        } else {
            return networkController.packages.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
    
    // Combined sorted packages based on current searchResults and sort settings
    private var sortedPackages: [Package] {
        let arr = searchResults
        switch packageSortBy {
        case .name:
            return arr.sorted { a, b in
                if packageSortAscending {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                } else {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
                }
            }
        case .id:
            return arr.sorted { a, b in
                // Treat jamfId==0 as large so it sorts after real ids
                let aId = (a.jamfId != 0) ? a.jamfId : Int.max
                let bId = (b.jamfId != 0) ? b.jamfId : Int.max
                return packageSortAscending ? (aId < bId) : (aId > bId)
            }
        }
    }

    // Dynamic heights to conserve vertical space when lists are small
    private var packageListHeight: CGFloat {
        let rows = max(1, sortedPackages.count)
        let h = CGFloat(rows) * 28.0 + 80.0
        return min(400.0, max(120.0, h))
    }

    private var selectionListHeight: CGFloat {
        let rows = packageMultiSelection.count
        if rows == 0 { return 44.0 }
        let h = CGFloat(rows) * 22.0 + 24.0
        return min(240.0, max(44.0, h))
    }
    
    // Added packagesSection composed view (renders header + platform-specific selectable list/table)
    private var packagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            packagesHeader

            // Platform-specific selectable view: native macOS Table or iOS List
            Group {
                #if os(macOS)
                packagesTable
                    .frame(height: packageListHeight)
                #else
                packagesListView
                    .frame(height: packageListHeight)
                #endif
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
    }

    // Extracted packages header to simplify type-checking
    private var packagesHeader: some View {
        VStack(alignment: .leading) {
            // Search field for packages (binds to searchText)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search packages", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal)

                    HStack {
                Text("All Packages").bold().padding(.leading)
                Spacer()
                HStack(spacing: 8) {
                    Picker("Sort by", selection: $packageSortBy) {
                        Text("Name").tag(PackageSortField.name)
                        Text("ID").tag(PackageSortField.id)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)

                    Button(action: { packageSortAscending.toggle() }) {
                        Image(systemName: packageSortAscending ? "arrow.up" : "arrow.down")
                    }
                    .buttonStyle(.plain)
                    .help("Toggle sort direction")
                    Button(action: {
                        // Clear package selection
                        packageMultiSelection.removeAll()
                        packageSelectionIDs.removeAll()
                    }) {
                        Text("Clear")
                    }
                    .buttonStyle(.bordered)
                }
            }

        }
    }

    // Small macOS Table extracted to reduce overall expression complexity
    private var packagesTable: some View {
        Table(sortedPackages, selection: $packageSelectionIDs) {
            TableColumn("Name") { pkg in
                Text(pkg.name)
                    .font(.system(size: 12.0))
                    .lineLimit(1)
            }
            TableColumn("ID") { pkg in
                Text(pkg.jamfId != 0 ? String(pkg.jamfId) : pkg.id.uuidString)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .trailing)
            }
        }
        .onChange(of: packageSelectionIDs) { newIDs in
            let selectedIds = Set(newIDs.compactMap { id in
                networkController.packages.first(where: { $0.id == id })?.jamfId
            })
            packageMultiSelection = selectedIds
        }
    }

     // Small iOS/List alternative extracted separately
     private var packagesListView: some View {
    
         // Show a small header row above the selectable list so users understand this pane
         
          
         
         VStack(alignment: .leading, spacing: 6) {
             // Selection row always shown under header so users see selection count
             HStack(spacing: 8) {
                 Text("Selection:")
                     .font(.caption)
                     .fontWeight(.semibold)
                     .foregroundColor(.primary)
                 Spacer()
                 Text("Selected: \(packageMultiSelection.count)")
                     .font(.caption2)
                     .foregroundColor(.secondary)
             }
             .padding(.horizontal)
             .padding(.top, 4)
             List(sortedPackages, id: \.jamfId, selection: $packageMultiSelection) { package in
                 HStack(alignment: .center, spacing: 12) {
                     VStack(alignment: .leading, spacing: 2) {
                         Text(package.name)
                             .font(.system(size: 12.0))
                             .lineLimit(1)
                     }
                     Spacer()
                     Text(package.jamfId != 0 ? String(package.jamfId) : package.id.uuidString)
                         .font(.caption.monospaced())
                         .foregroundColor(.secondary)
                         .frame(width: 120, alignment: .trailing)
                 }
                 .contentShape(Rectangle())
             }
         }
      }
    
      // Helper: check whether a Jamf UI URL exists (not a 404)
      private func checkURLExists(_ urlString: String) async -> Bool {
          guard let url = URL(string: urlString) else { return false }
          var req = URLRequest(url: url)
          req.httpMethod = "HEAD"
          req.timeoutInterval = 8
          do {
              let (_, response) = try await URLSession.shared.data(for: req)
              if let http = response as? HTTPURLResponse {
                  return http.statusCode < 400
              }
          } catch {
              // Some servers do not support HEAD - fall back to a lightweight GET
              do {
                  var req2 = URLRequest(url: url)
                  req2.httpMethod = "GET"
                  req2.timeoutInterval = 8
                  let (_, response2) = try await URLSession.shared.data(for: req2)
                  if let http2 = response2 as? HTTPURLResponse {
                      return http2.statusCode < 400
                  }
              } catch {
                  print("checkURLExists error for \(urlString): \(error)")
                  return false
              }
          }
          return false
      }

      // End of view helpers
}

// End of file

// Template edit view
struct TemplateEditView: View {
    @EnvironmentObject var networkController: NetBrain
    @State var template: CreatePolicyView.PolicyTemplate
    var onSave: (CreatePolicyView.PolicyTemplate) -> Void
    var onCancel: () -> Void

    @State private var selectedPackageIds: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Edit Template").font(.headline)
                Spacer()
            }

            TextField("Template name", text: $template.name)
            TextField("Policy name", text: $template.policyName)

            // Category picker
            Picker("Category", selection: Binding(get: { template.categoryId ?? -1 }, set: { template.categoryId = $0 == -1 ? nil : $0 })) {
                Text("None").tag(-1)
                ForEach(networkController.categories, id: \.jamfId) { cat in
                    Text(cat.name).tag(cat.jamfId)
                }
            }

            // Department picker
            Picker("Department", selection: Binding(get: { template.departmentId ?? -1 }, set: { template.departmentId = $0 == -1 ? nil : $0 })) {
                Text("None").tag(-1)
                ForEach(networkController.departments, id: \.jamfId) { dept in
                    Text(dept.name).tag(dept.jamfId)
                }
            }

            // Script picker
            Picker("Script", selection: Binding(get: { template.scriptId ?? -1 }, set: { template.scriptId = $0 == -1 ? nil : $0 })) {
                Text("None").tag(-1)
                ForEach(networkController.scripts, id: \.jamfId) { s in
                    Text(s.name).tag(s.jamfId)
                }
            }

            Toggle("Self Service Enabled", isOn: $template.selfServiceEnabled)

            // Packages multi-select
            Text("Packages to include").font(.subheadline)
            List(networkController.packages, id: \.jamfId) { pkg in
                HStack {
                    Text(pkg.name)
                    Spacer()
                    let bound = Binding(get: { template.selectedPackageIds.contains(pkg.jamfId) }, set: { val in
                        if val { template.selectedPackageIds.append(pkg.jamfId) } else { template.selectedPackageIds.removeAll { $0 == pkg.jamfId } }
                    })
                    Toggle("", isOn: bound).labelsHidden()
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
                Button("Save") {
                    onSave(template)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}
