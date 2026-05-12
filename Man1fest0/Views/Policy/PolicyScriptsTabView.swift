//
//  PolicyScriptsTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 12/07/2024.
//

import SwiftUI
import AEXML

struct PolicyScriptsTabView: View {
    
    var server: String
    var resourceType: ResourceType
    // Local snapshot to avoid following the shared controller directly
    var localPolicyDetailed: PolicyDetailed? = nil
    @State private var searchText = ""

    //    ########################################################################################
    //    EnvironmentObject
    //    ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    //    ########################################################################################
    //    EnvironmentObject - end
    //    ########################################################################################
    
    @State private var selectedResourceType = ResourceType.policyDetail

    @State var computerGroupFilter = ""

    
    //  ########################################################################################
    //  Policy
    //  ########################################################################################
    
    @State var policyName = ""
    var policyID: Int

    //  ########################################################################################
    //  Script
    //  ########################################################################################
    
    @State var scriptName = ""
    @State var scriptID = ""


    //  ########################################################################################
    //  Selections
    //  ########################################################################################
    
    @Binding var computerGroupSelection: Set<ComputerGroup>
    @State private var selection: PolicyScripts? = nil
    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
    @State var listSelection: PolicyScripts = PolicyScripts(id:(UUID(uuidString: "") ?? UUID()) , jamfId: 0, name: "")
    @State var pickerSelectedScript = 0
    @State private var selectedNumber = 0
    // multi-selection of scripts (store jamfId values)
    @State private var selectedScriptIDs: Set<Int> = []
    
    //  ########################################################################################
    
    @State var scriptParameter4: String = ""
    @State var scriptParameter5: String = ""
    @State var scriptParameter6: String = ""
    @State var scriptParameter7: String = ""
    @State var scriptParameter8: String = ""
    @State var scriptParameter9: String = ""
    @State var scriptParameter10: String = ""
    @State var scriptParameter11: String = ""
    @State var priority = ""

    
    @State var command: String = ""
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading) {
                
                Group {
                    
                    // ################################################################################
                    //              SCRIPTS
                    // ################################################################################
                    
                    // ################################################################################
                    //              List scripts
                    // ################################################################################
                    
                    if (localPolicyDetailed ?? networkController.policyDetailed)?.scripts?.count ?? 0 > 0 {
                        Text("Assigned Scripts:\((localPolicyDetailed ?? networkController.policyDetailed)?.scripts?.count ?? 0)").bold()
#if os(macOS)
                        
                        
                        List((localPolicyDetailed ?? networkController.policyDetailed)?.scripts ?? [PolicyScripts](), id: \.self, selection: $listSelection) { script in
                            NavigationLink(destination: PolicyScriptsTabViewDetail(script: script, policyID: policyID, server: server)) {
                                HStack {
                                    
                                    Text(script.name ?? "")
                                    if script.parameter4 != "" {
                                        Image(systemName: "4.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter4 ?? "" )
                                    }
                                    if script.parameter5 != "" {
                                        Image(systemName: "5.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter5 ?? "" )
                                    }
                                    if script.parameter6 != "" {
                                        Image(systemName: "6.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter6 ?? "" )
                                    }
                                    if script.parameter7 != "" {
                                        Image(systemName: "7.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter7 ?? "" )
                                    }
                                    if script.parameter8 != "" {
                                        Image(systemName: "8.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter8 ?? "" )
                                    }
                                    if script.parameter9 != "" {
                                        Image(systemName: "9.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter9 ?? "" )
                                    }
                                    if script.parameter10 != "" {
                                        Image(systemName: "10.circle").bold()
                                            .foregroundColor(.red)
                                        Text(script.parameter10 ?? "" )
                                    }
                                    if script.priority != "" {
                                        Text(script.priority ?? "" )
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 100)
                        .frame(minWidth: 120, maxWidth: .infinity)
#else
                        List((localPolicyDetailed ?? networkController.policyDetailed)?.scripts ?? [PolicyScripts](), id: \.self) { script in
                            HStack {
                                Image(systemName: "applescript")
                                Text(script.name ?? "" )
                            }
                        }
                        .frame(minHeight: 0)
#endif
                    }
                    
                    //  #########################################################################
                    //  Edit scripts parameters
                    //  #########################################################################
                    
                    //    ##################################################
                    //    replaceScriptParameter
                    //    ##################################################
                    
             
                    
                    HStack {
                        Button(action: {
                            print("-----------------------------")
                            print("replaceScriptParameter button was tapped")
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            xmlController.replaceScriptParameter(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML, selectedScriptNumber: pickerSelectedScript, parameter4: scriptParameter4, parameter5: scriptParameter5, parameter6: scriptParameter6, parameter7: scriptParameter7, parameter8: scriptParameter8, parameter9: scriptParameter9, parameter10: scriptParameter10, parameter11: scriptParameter11, priority: priority )
                            
                            // Refresh detailed policy to reflect script parameter changes
                            Task {
                                do {
                                    try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                } catch {
                                    print("Failed to refresh detailed policy after replacing script parameter: \(error)")
                                }
                            }
                        }) {
                            Text("Update Parameter")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .help("Update the chosen script parameter(s) for this policy and refresh details.")
                        
                        LazyVGrid(columns: layout.threeColumns) {
                            //
                            Picker("Script", selection: $pickerSelectedScript) {
                                ForEach(1..<10) {
                                    Text("\($0)")
                                }
                                Text("You selected: \(pickerSelectedScript)")
                                
                            }
                            
                            .onChange(of: pickerSelectedScript) { newValue in
                                print("pickerSelectedScript changed to \(pickerSelectedScript)")
                            }
                            .onAppear {
                                print("pickerSelectedScript is currently:\(pickerSelectedScript)")
                                //                            if pickerSelectedScript.isEmpty != true {
                                //                                print("Setting numbers picker default")
                                //                                pickerSelectedScript = 0 }
                            }
                            TextField("parameter4", text: $scriptParameter4)
                        }
                    }
                    
                    DisclosureGroup("More Parameters") {
                        
                        HStack {
                            LazyVGrid(columns: layout.columns) {
                                TextField("parameter5", text: $scriptParameter5)
                                TextField("parameter6", text: $scriptParameter6)
                            }
                        }
                        
                            HStack {
                                LazyVGrid(columns: layout.columns) {
                                    TextField("parameter4", text: $scriptParameter4)
                                    TextField("parameter5", text: $scriptParameter5)
                                    TextField("parameter6", text: $scriptParameter6)
                                }
                            }
                        HStack {
                            LazyVGrid(columns: layout.columns) {
                                TextField("parameter9", text: $scriptParameter9)
                                TextField("parameter10", text: $scriptParameter10)
                            }
                        }
                        
                        HStack {
                            LazyVGrid(columns: layout.columns) {
                                TextField("before/after", text: $priority)
                            }
                        }
                    }
                    
                    DisclosureGroup("Notes") {
                        VStack() {
                            NotesView()
                        }
                        .frame(minHeight: 60, alignment: .leading)
                    }
                    
                    Divider()
                    
                }
                
                
                DisclosureGroup("Add/Remove Scripts") {
                    
                    //  #########################################################################
                    //              Scripts picker
                    //  #########################################################################
                    
                    HStack {
                        
                        LazyVGrid(columns: layout.threeColumns, spacing: 10) {
                            
                            
                            // Mirror the filtered picker below: allow filtering by name and guard optional names
                            Picker(selection: $selectedScript, label: Text("Scripts").bold()) {
                                ForEach(networkController.scripts.filter { script in
                                    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !query.isEmpty else { return true }
                                    return script.name.localizedCaseInsensitiveContains(query)
                                }, id: \.self) { script in
                                    Text(script.name)
                                        .tag(script)
                                }
                            }
                            .onAppear {
                                if networkController.scripts.isEmpty != true {
                                    print("Setting package picker default")
                                    selectedScript = networkController.scripts[0]
                                }
                            }
                            
                            // Filter field for the Scripts picker
                            TextField("Filter scripts", text: $searchText)
#if os(macOS)
                                .textFieldStyle(.plain)
#else
                                .textFieldStyle(.roundedBorder)
#endif
                                .frame(minWidth: 160)
                                .padding(.bottom, 6)
                        }
                        
                        //  #####################################################################
                        //              Add script
                        //  #####################################################################
                        
                        // Single-add button (existing behavior)
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            
                            xmlController.addScriptToPolicy(xmlContent: xmlController.aexmlDoc, xmlContentString: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID), scriptName: selectedScript.name, scriptId: String(describing: selectedScript.jamfId), scriptParameter4: scriptParameter4, scriptParameter5: scriptParameter5, scriptParameter6: scriptParameter6, scriptParameter7: scriptParameter7, scriptParameter8: scriptParameter8, scriptParameter9: scriptParameter9, scriptParameter10: scriptParameter10, scriptParameter11: scriptParameter11, priority: priority, newPolicyFlag: false)
                            
                            print("Adding script:\(selectedScript.name)")
                            print("parameter 4 is :\(scriptParameter4)")
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.app.fill")
                                Text("Add")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .help("Add the selected script to this policy with provided parameters.")
                        
                    }
                        // Bulk add: multi-select list and Add Selected button
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Or select multiple scripts to add:")
                                .font(.subheadline)
                                .bold()
                            
                            
                            
                            // Scrollable list of filtered scripts with checkboxes
                            ScrollView(.vertical) {
                                LazyVStack(alignment: .leading, spacing: 6) {
                                    ForEach(networkController.scripts.filter { script in
                                        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !query.isEmpty else { return true }
                                        return script.name.localizedCaseInsensitiveContains(query)
                                    }, id: \ .jamfId) { script in
                                        HStack {
                                            Button(action: {
                                                if selectedScriptIDs.contains(script.jamfId) {
                                                    selectedScriptIDs.remove(script.jamfId)
                                                } else {
                                                    selectedScriptIDs.insert(script.jamfId)
                                                }
                                            }) {
                                                Image(systemName: selectedScriptIDs.contains(script.jamfId) ? "checkmark.square.fill" : "square")
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Text(script.name)
                                            Spacer()
                                            Text("id: \(script.jamfId)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)

                        // Action buttons for bulk add / clear selection
                        HStack(spacing: 12) {
                            Button(action: {
                                guard !selectedScriptIDs.isEmpty else { return }
                                progress.showProgress()
                                progress.waitForABit()

                                // Collect selected scripts in the same order as networkController.scripts
                                let selectedScripts = networkController.scripts.filter { selectedScriptIDs.contains($0.jamfId) }

                                xmlController.addMultipleScriptsToPolicy(xmlContent: xmlController.aexmlDoc, xmlContentString: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID), scriptsToAdd: selectedScripts, scriptParameter4: scriptParameter4, scriptParameter5: scriptParameter5, scriptParameter6: scriptParameter6, scriptParameter7: scriptParameter7, scriptParameter8: scriptParameter8, scriptParameter9: scriptParameter9, scriptParameter10: scriptParameter10, scriptParameter11: scriptParameter11, priority: priority, newPolicyFlag: false) {
                                    // completion handler: refresh detailed policy and clear selection
                                    Task {
                                        do {
                                            try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                                        } catch {
                                            print("Failed to refresh detailed policy after adding scripts: \(error)")
                                        }
                                        progress.endProgress()
                                        // Clear the selection after successful upload
                                        selectedScriptIDs.removeAll()
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.rectangle.on.rectangle")
                                    Text("Add Selected")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .help("Add all selected scripts to this policy in a single upload.")

                            Button(action: {
                                selectedScriptIDs.removeAll()
                            }) {
                                Text("Clear Selection")
                            }
                            .help("Clear currently selected scripts without uploading.")
                        }
                        .padding(.top, 6)
                    }
//                    }
                }
                
                
                DisclosureGroup("Add Individual Command/s To Run In Policy") {
                    
                    //  #########################################################################
                    //  Add custom command in policy4
                    //  #########################################################################
                    
                    
                    TextEditor(text: $command)
                        .frame(minHeight: 20)
                        .frame(maxHeight: 40)
                        .border(Color.gray)
              
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.separationLine()
                        print("Add custom command to policy:\(String(describing: policyID))")
                        policyController.addCustomCommand(server: server, authToken: networkController.authToken, policyID: String(describing: policyID), command: command)
                    }) {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Add Individual Command To Policy")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Add a custom shell command to be run by this policy.")
                }
                Spacer()
            }
            .frame(minWidth: 400, alignment: .leading)
            .padding()
            .onAppear() {
                
                if  networkController.scripts.count <= 1 {
                     print("Fetching scripts")
                     print("Script count is:\(networkController.scripts.count))")
      Task { try? await networkController.getAllScripts() }
                 } else {
                     print("script data is available")
                 }
             }
         }
     }
}

// Close PolicyScriptsTabView struct

// Minimal inline detail view so the NavigationLink can resolve the type without
// requiring the file to be added to the Xcode project. This mirrors the
// standalone `PolicyScriptsTabViewDetail` behavior and is intentionally
// lightweight.
#if os(macOS)
struct PolicyScriptsTabViewDetail: View {
    var script: PolicyScripts
    var policyID: Int
    var server: String

    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    @State private var parameter4: String = ""
    @State private var parameter5: String = ""
    @State private var parameter6: String = ""
    @State private var parameter7: String = ""
    @State private var parameter8: String = ""
    @State private var parameter9: String = ""
    @State private var parameter10: String = ""
    @State private var parameter11: String = ""
    @State private var priority: String = ""
    @State private var selectedScriptNumber: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(script.name ?? "").font(.title2).bold()

                Group {
                    HStack { Text("Parameter 4:") ; TextField("parameter4", text: $parameter4) }
                    HStack { Text("Parameter 5:") ; TextField("parameter5", text: $parameter5) }
                    HStack { Text("Parameter 6:") ; TextField("parameter6", text: $parameter6) }
                    HStack { Text("Parameter 7:") ; TextField("parameter7", text: $parameter7) }
                    HStack { Text("Parameter 8:") ; TextField("parameter8", text: $parameter8) }
                    HStack { Text("Parameter 9:") ; TextField("parameter9", text: $parameter9) }
                    HStack { Text("Parameter 10:") ; TextField("parameter10", text: $parameter10) }
                    HStack { Text("Parameter 11:") ; TextField("parameter11", text: $parameter11) }

                    HStack {
                        Text("Priority:")
                        TextField("Before/After", text: $priority).frame(minWidth: 120)
                    }
                }

                HStack {
                    Picker("Script Index", selection: $selectedScriptNumber) {
                        ForEach(1..<10) { i in Text("\(i)") }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Button("Update Parameter") {
                        progress.showProgress()
                        progress.waitForABit()

                        xmlController.replaceScriptParameter(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML, selectedScriptNumber: selectedScriptNumber, parameter4: parameter4, parameter5: parameter5, parameter6: parameter6, parameter7: parameter7, parameter8: parameter8, parameter9: parameter9, parameter10: parameter10, parameter11: parameter11, priority: priority)

                        Task {
                            do {
                                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            } catch {
                                print("Failed to refresh detailed policy after replacing script parameter: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                parameter4 = script.parameter4 ?? ""
                parameter5 = script.parameter5 ?? ""
                parameter6 = script.parameter6 ?? ""
                parameter7 = script.parameter7 ?? ""
                parameter8 = script.parameter8 ?? ""
                parameter9 = script.parameter9 ?? ""
                parameter10 = script.parameter10 ?? ""
                parameter11 = script.parameter11 ?? ""
                priority = script.priority ?? ""
            }
        }
    }
}
#endif

//#Preview {
//    PolicyEditTabView()
//}
