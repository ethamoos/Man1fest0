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
//    @State var scriptParameter4 = ""
//    @State var scriptParameter5 = ""
//    @State var scriptParameter6 = ""
//    @State var scriptParameter7 = ""
//    @State var scriptParameter8 = ""
//    @State var scriptParameter9 = ""
//    @State var scriptParameter10 = ""
    @State var priority = ""

    //  ########################################################################################
    //  Selections
    //  ########################################################################################
    
    @Binding var computerGroupSelection: Set<ComputerGroup>
    @State private var selection: PolicyScripts? = nil
    // Picker uses the script's jamfId as the selection to avoid complex generic inference issues
    @State var selectedScriptId: Int = 0
    // Use a single optional selection for the List selection on macOS
    @State var listSelection: PolicyScripts? = nil
    @State var pickerSelectedScript = 0
    @State private var selectedNumber = 0

    //  ########################################################################################
    
    @State var scriptParameter4: String = ""
    @State var scriptParameter5: String = ""
    @State var scriptParameter6: String = ""
    @State var scriptParameter7: String = ""
    @State var scriptParameter8: String = ""
    @State var scriptParameter9: String = ""
    @State var scriptParameter10: String = ""
    @State var scriptParameter11: String = ""
//    @State var priority: String = "Before"
    
    
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
                    
                    if networkController.policyDetailed?.scripts?.count ?? 0 > 0 {
                        Text("Assigned Scripts").bold()

                        // Use a simple ForEach to avoid platform-specific List generic inference problems
                        if let scripts = networkController.policyDetailed?.scripts, !scripts.isEmpty {
                            ForEach(scripts, id: \.jamfId) { script in
                                HStack {
                                    Text(script.name ?? "")
                                    if let p4 = script.parameter4, !p4.isEmpty {
                                        Image(systemName: "4.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p4)
                                    }
                                    if let p5 = script.parameter5, !p5.isEmpty {
                                        Image(systemName: "5.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p5)
                                    }
                                    if let p6 = script.parameter6, !p6.isEmpty {
                                        Image(systemName: "6.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p6)
                                    }
                                    if let p7 = script.parameter7, !p7.isEmpty {
                                        Image(systemName: "7.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p7)
                                    }
                                    if let p8 = script.parameter8, !p8.isEmpty {
                                        Image(systemName: "8.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p8)
                                    }
                                    if let p9 = script.parameter9, !p9.isEmpty {
                                        Image(systemName: "9.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p9)
                                    }
                                    if let p10 = script.parameter10, !p10.isEmpty {
                                        Image(systemName: "10.circle").bold()
                                            .foregroundColor(.red)
                                        Text(p10)
                                    }
                                    if let pr = script.priority, !pr.isEmpty {
                                        Text(pr)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .frame(minHeight: 100)
                            .frame(minWidth: 120, maxWidth: .infinity)
                        }
                    }
                    
                    //  ################################################################################
                    //  Edit scripts parameters
                    //  ################################################################################
                    
                    //    ##################################################
                    //    replaceScriptParameter
                    //    ##################################################
                    
                    //            LazyVGrid(columns: columns4) {
                    
                    //                if currentScript.parameter4 != "" {
                    
                    HStack {
                        Button(action: {
                            print("-----------------------------")
                            print("replaceScriptParameter button was tapped")
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            xmlController.replaceScriptParameter(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML, selectedScriptNumber: pickerSelectedScript, parameter4: scriptParameter4, parameter5: scriptParameter5, parameter6: scriptParameter6, parameter7: scriptParameter7, parameter8: scriptParameter8, parameter9: scriptParameter9, parameter10: scriptParameter10, priority: priority )
                            
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
                                ForEach(0..<10) {
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
                                TextField("parameter7", text: $scriptParameter7)
                                TextField("parameter8", text: $scriptParameter8)
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
                
                
                Group {
                    
                    //  ################################################################################
                    //              Scripts picker
                    //  ################################################################################
                    
                    HStack {
                        
                        LazyVGrid(columns: layout.threeColumns, spacing: 10) {

                            
                            // Mirror the filtered picker below: use the script's jamfId for selection
                            Picker(selection: $selectedScriptId, label: Text("Scripts").bold()) {
                                ForEach(networkController.scripts.filter { script in
                                    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !query.isEmpty else { return true }
                                    return script.name.localizedCaseInsensitiveContains(query)
                                }, id: \.jamfId) { script in
                                    Text(script.name)
                                        .tag(script.jamfId)
                                }
                            }
                            .onAppear {
                                if let first = networkController.scripts.first {
                                    selectedScriptId = first.jamfId
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
                        
                        //  ################################################################################
                        //              Add script
                        //  ################################################################################
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            // Resolve selected script object from the id before calling the xml controller
                            let selectedScriptResolved = networkController.scripts.first(where: { $0.jamfId == selectedScriptId }) ?? ScriptClassic(name: "", jamfId: 0)
                            xmlController.addScriptToPolicy(xmlContent: xmlController.aexmlDoc, xmlContentString: xmlController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID), scriptName: selectedScriptResolved.name, scriptId: String(describing: selectedScriptResolved.jamfId), scriptParameter4: scriptParameter4, scriptParameter5: scriptParameter5, scriptParameter6: scriptParameter6, scriptParameter7: scriptParameter7, scriptParameter8: scriptParameter8, scriptParameter9: scriptParameter9, scriptParameter10: scriptParameter10, scriptParameter11: scriptParameter11, priority: priority, newPolicyFlag: false)
                            
                            print("Adding script:\(selectedScriptResolved.name)")
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
                        
                        
                        //  ################################################################################
                        //              Remove script
                        //  ################################################################################
                        
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            // Pass currently selected script from the list (if any)
                            let selId: Int? = (listSelection?.jamfId == 0) ? nil : listSelection?.jamfId
                            xmlController.removeScriptFromPolicy(xmlContent: xmlController.aexmlDoc, authToken: networkController.authToken, server: server, policyId: String(describing: policyID), selectedScriptName: listSelection?.name ?? "", selectedScriptId: listSelection?.jamfId ?? 0)
                            
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.app.fill")
                                Text("Remove")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .help("Remove the selected script from this policy.")
                        //                    .disabled(listedScript.jamfId == 0 && listedScript.name == "")
                        
                        //  ################################################################################
                        //              Remove all scripts in policy
                        //  ################################################################################
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            
                            networkController.separationLine()
                            print("Removing all scripts in policy:\(String(describing: policyID))")
                            
                            xmlController.removeAllScriptsFromPolicy(xmlContent: xmlController.aexmlDoc, authToken: networkController.authToken, server: server, policyId: String(describing: policyID))
                            
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "minus.square.fill.on.square.fill")
                                Text("Remove All")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .help("Remove all scripts currently assigned to this policy.")
                        
                    }
                }
                
                //            Group {
                //                Divider()
                //                LazyVGrid(columns: columns, spacing: 10) {
                //                    VStack(alignment: .leading) {
                //                        DisclosureGroup("Parameters") {
                //
                //                            TextField("Parameter 4", text: $scriptParameter4)
                //                            TextField("Parameter 5", text: $scriptParameter5)
                //                            TextField("Parameter 6", text: $scriptParameter6)
                //                            TextField("Parameter 7", text: $scriptParameter7)
                //                            TextField("Parameter 8", text: $scriptParameter8)
                //                            TextField("Parameter 9", text: $scriptParameter9)
                //                            TextField("Parameter 10", text: $scriptParameter10)
                //                            TextField("Parameter 11", text: $scriptParameter11)
                //                            Text("Priority:")
                //                            TextField("Before/After?", text: $priority)
                //                        }
                //                    }
                //                }
                //            }
                
                //            Text("Add Individual Command/s To Run In Policy").fontWeight(.bold)
                TextEditor(text: $command)
                    .frame(minHeight: 20)
                    .frame(maxHeight: 40)
                
                    .border(Color.gray)
                
                //  ################################################################################
                //  Add custom command in policy
                //  ################################################################################
                
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
                
                
                
                Spacer()
            }
            .frame(minWidth: 400, alignment: .leading)
            .padding()
            .onAppear() {
                
                if  networkController.scripts.count <= 1 {
                    print("Fetching scripts")
                    print("Script count is:\(networkController.scripts.count))")
                    networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
                    
                } else {
                    
                    print("script data is available")
                }
            }
        }
    }
}

//var searchResults: [Script] {
//    if searchText.isEmpty {
//        // print("Search is empty")
//        //            DEBUG
//        //            print(networkController.scripts)
//        return controller.scripts
//    } else {
//        // print("Search is currently is currently:\(searchText)")
//        //            DEBUG
//        //            print(networkController.scripts)
//        return controller.scripts.filter { $0.name.lowercased().contains(searchText.lowercased())}
//    }
//}


//#Preview {
//    PolicyEditTabView()
//}

