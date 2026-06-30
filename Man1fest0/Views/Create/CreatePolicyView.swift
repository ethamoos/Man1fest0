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

    // Local layout constants and helpers
    private let selectionListHeight: CGFloat = 100
    private let packageListHeight: CGFloat = 300
    private let columns: [GridItem] = [GridItem(.flexible())]

    // Compose the packages section used in the main body
    private var packagesSection: some View {
        VStack(spacing: 8) {
            packagesHeader
            Group {
                #if os(macOS)
                packagesTable
                #else
                packagesListView
                #endif
            }
            .frame(height: packageListHeight)
        }
    }

    // Sorted packages according to local sort selections
    private var sortedPackages: [Package] {
        let src = networkController.packages
        switch packageSortBy {
        case .name:
            return src.sorted { packageSortAscending ? $0.name.lowercased() < $1.name.lowercased() : $0.name.lowercased() > $1.name.lowercased() }
        case .id:
            return src.sorted { packageSortAscending ? $0.jamfId < $1.jamfId : $0.jamfId > $1.jamfId }
        }
    }

    // Template persistence helpers (simple implementations)
    private func saveCurrentAsTemplate() {
        let tpl = PolicyTemplate(name: newTemplateName,
                                 policyName: newPolicyName,
                                 selectedPackageIds: Array(packageMultiSelection),
                                 categoryId: selectedCategoryId,
                                 departmentId: selectedDepartmentId,
                                 scriptId: selectedScriptId,
                                 selfServiceEnabled: selfServiceEnable,
                                 iconId: selectedIconId)
        templates.append(tpl)
        persistTemplates()
        newTemplateName = ""
    }

    private func exportTemplatesToDownloads() {
        // Build a sensible default filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let suggestedName = "Man1fest0_templates_\(dateStr).json"

        guard let url = importExportBrain.showSavePanel(suggestedName: suggestedName, allowedExtensions: ["json"]) else {
            print("exportTemplates: user cancelled save panel")
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(templates)
            try data.write(to: url, options: .atomic)
            networkController.messageStore?.show("Templates exported", level: .success, details: "Saved \(templates.count) template(s) to \(url.lastPathComponent)")
            print("Exported templates to: \(url.path)")
        } catch {
            networkController.messageStore?.show("Export failed", level: .error, details: error.localizedDescription)
            print("Failed exporting templates: \(error)")
        }
    }

    private func importTemplatesFromFile() {
        guard let url = importExportBrain.showOpenPanel() else {
            print("importTemplatesFromFile: no file selected")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode([PolicyTemplate].self, from: data)
            templates.append(contentsOf: imported)
            persistTemplates()
            networkController.messageStore?.show("Templates imported successfully", level: .success, details: "Imported \(imported.count) template(s) from \(url.lastPathComponent)")
            print("importTemplatesFromFile: imported \(imported.count) templates from \(url.path)")
        } catch {
            networkController.messageStore?.show("Template import failed", level: .error, details: error.localizedDescription)
            print("Failed to import templates: \(error)")
        }
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

    private func deleteTemplate(_ tpl: PolicyTemplate) {
        templates.removeAll { $0.id == tpl.id }
        persistTemplates()
    }

    private func persistTemplates() {
        do {
            let key = "com.man1fest0.templates.\(server)"
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to persist templates: \(error)")
        }
    }

    @State private var templates: [PolicyTemplate] = []
    @State private var newTemplateName: String = ""
    @State private var editingTemplate: PolicyTemplate? = nil
    // Template pending deletion (used to show confirmation alert)
    @State private var templateToDelete: PolicyTemplate? = nil
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
                .onAppear() {
                    
                    Task {
                        try await networkController.getAllPackages()
                        try await networkController.getAllScripts()
                    }
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
                            
                            Toggle(isOn: $createDepartmentIsChecked) {
                                Text("New Dept")
                            }
                            .toggleStyle(.checkbox)
                            
                            Toggle(isOn: $enableSelfService) {
                                Text("Self Service")
                            }
                            .toggleStyle(.checkbox)
                        }
                            
                            // Script picker: choose a script to attach to the new policy
                            HStack {
                                Text("Script").bold()
                                Picker("Script", selection: Binding(get: { selectedScriptId ?? -1 }, set: { selectedScriptId = $0 == -1 ? nil : $0 })) {
                                    Text("None").tag(-1)
                                    ForEach(networkController.scripts, id: \.jamfId) { s in
                                        Text(s.name).tag(s.jamfId)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 300)
                                Spacer()
                            }
                            
//                        }
                    }
                    
#if os(macOS)
                    // File import controls - Select a local XML file and import as a policy
                    
                    ProminentDisclosure(indicatorColor: .accentColor) {
                        Text("Import Policy from XML").font(.headline)
                    } content: {
                        
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
                    ProminentDisclosure(indicatorColor: .accentColor) {
                        Text("Policy Templates").font(.headline)
                    } content: {
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
                                        Button("Delete") {
                                            // Ask for confirmation before deleting template
                                            templateToDelete = t
                                        }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                    }
                                }
                            }
                        }
                        // Confirmation alert for deleting a saved template
                        .alert(item: $templateToDelete) { tpl in
                            Alert(title: Text("Confirm Delete"),
                                  message: Text("Delete template '\(tpl.name)'? This action cannot be undone."),
                                  primaryButton: .destructive(Text("Delete")) {
                                deleteTemplate(tpl)
                            }, secondaryButton: .cancel())
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
                            } // end HStack
                        } // end LazyVGrid
                    } // end VStack(alignment: .leading)
                    } // end Group
                } // end VStack

            } // end body
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
