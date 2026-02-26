//
//  ScriptUsageViewJson.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/11/2023.
//

import SwiftUI

struct ScriptUsageView: View {
    
    var server: String
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var policyController: PolicyBrain
    
    @State private var searchText = ""
    @State var assignedScripts: [PolicyScripts] = []
    @State var assignedScriptsArray: [String] = []
    @State var assignedScriptsByNameDict: [String: String] = [:]
    @State var assignedScriptsByNameSet = Set<String>()
    //    ########################################
    //    SUMMARIES
    //    ########################################
    
    @State var clippedScripts = Set<String>()
    @State var unassignedScriptsSet = Set<String>()
    @State var unassignedScriptsArray: [String] = []
    @State var unassignedScriptsByNameDict: [String: String] = [:]
    
    @State var allScripts: [ScriptClassic] = []
    @State var allScriptsByNameDict: [String: String] = [:]
    @State var allScriptsByNameSet = Set<String>()
    @State var totalScriptsNotUsed = 0

    //    ########################################
    //    Selections
    //    ########################################
    
    @State var selection = Set<String>()
    @State var selectedKey: [String] = []
    @State var selectedValue: String = ""

    // Computed cross-platform background color for boxed headings
    private var sectionBoxBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.08)
        #endif
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Script Usage")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Overview of scripts and where they are used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Quick action buttons grouped on the right
                HStack(spacing: 10) {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        getScriptsInUse()
                        getScriptValues()
                    }) {
                        Label("Analyse", systemImage: "chart.bar.doc.horizontal")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: {
                        networkController.allPoliciesDetailed.removeAll()
                        Task {
                            try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                }
            }
            .padding([.top, .horizontal])

            if networkController.scripts.count == 0 {
                VStack(alignment: .center) {
                    Spacer()
                    Text("No scripts available yet — fetching from server...")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(sectionBoxBackground))
                .padding(.horizontal)
            } else {
                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Stats Card
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Total Scripts")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(networkController.scripts.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }

                                HStack {
                                    Text("Scripts in policies")
                                    Spacer()
                                    Text("\(assignedScriptsByNameDict.count)")
                                }

                                HStack {
                                    Text("Scripts not used")
                                    Spacer()
                                    Text("\(unassignedScriptsArray.count)")
                                }
                            }
                            .padding()

                            Spacer()
                        }
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)).shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3))
                        .padding(.horizontal)

                        // All Scripts (searchable)
                        if networkController.allPoliciesConverted.count != networkController.allPoliciesDetailed.count {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("All Scripts")
                                    .font(.headline)
                                    .padding(.horizontal)

                                List {
                                    ForEach(searchResults, id: \ .self) { script in
                                        HStack(spacing: 10) {
                                            Image(systemName: "applescript")
                                                .foregroundColor(.blue)
                                            Text(script.name)
                                                .lineLimit(1)
                                            Spacer()
                                            Text("#\(script.jamfId)")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                }
                                .frame(minHeight: 120, maxHeight: 260)
                                .listStyle(.inset)
                                .searchable(text: $searchText)
                            }
                        }

                        // Assigned Scripts card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assigned Scripts")
                                .font(.headline)
                                .padding(.horizontal)

                            List(selection: $selection) {
                                ForEach(assignedScriptsByNameDict.keys.sorted(), id: \ .self) { script in
                                    HStack {
                                        Label(script, systemImage: "checkmark.seal")
                                        Spacer()
                                        Text(policyController.assignedScriptsByNameDict[script] ?? "")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .frame(minHeight: 140, maxHeight: 320)
                            .listStyle(.inset)
                        }
                        .background(RoundedRectangle(cornerRadius: 10).fill(sectionBoxBackground))
                        .padding(.horizontal)

                        // Unassigned Scripts card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scripts not in use")
                                .font(.headline)
                                .padding(.horizontal)

                            List(selection: $selection) {
                                ForEach(unassignedScriptsSet.sorted(), id: \ .self) { script in
                                    HStack {
                                        Label(script, systemImage: "xmark.circle")
                                            .foregroundColor(.orange)
                                        Spacer()
                                        Text(allScriptsByNameDict[script] ?? "")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .frame(minHeight: 140, maxHeight: 320)
                            .listStyle(.inset)
                        }
                        .background(RoundedRectangle(cornerRadius: 10).fill(sectionBoxBackground))
                        .padding(.horizontal)

                        // Action toolbar at bottom of content
                        HStack(spacing: 12) {
                            Button(action: {
                                // Delete selection
                                progress.showProgress()
                                progress.waitForABit()

                                selectedValue = selection
                                    .compactMap { policyController.allScriptsByNameDict[$0] }
                                    .joined(separator: ", ")

                                selectedKey = selection.map{return $0}

                                let selectedValueArray = selectedValue.components(separatedBy: ",")

                                for eachItem in selectedValueArray {
                                    let eachItemTrimmed = eachItem.trimmingCharacters(in: .whitespacesAndNewlines)
                                    Task {
                                        try await networkController.deleteScript(server: server, resourceType: ResourceType.script, itemID: eachItemTrimmed, authToken: networkController.authToken)
                                    }
                                }
                            }) {
                                Label("Delete Selection", systemImage: "trash")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)

                            Spacer()

                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                getScriptsInUse()
                                getScriptValues()
                            }) {
                                Label("Analyse Data", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                networkController.allPoliciesDetailed.removeAll()
                                Task {
                                    try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                                }
                            }) {
                                Label("Refresh Policy Data", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)

                        if progress.showProgressView == true {
                            ProgressView("Loading…")
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .frame(minHeight: 50)
        .padding()
        .onAppear() {
            
            progress.showProgress()
            progress.waitForABit()
            
            if networkController.fetchedDetailedPolicies == false {
                
                Task {
                    try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                }
                print("Setting: fetchedPolicies to true")
                networkController.fetchedDetailedPolicies = true
            } else {
                print("Fetched detailed policies has run - ignoring")
            }
            
            if networkController.scripts.count == 0 {
                print("Fetching scripts")
                networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
            }
        }
    }
    
    //  ########################################
    //  getScriptsInUse
    //  ########################################
    
    func getScriptsInUse () {
        
        let allPoliciesDetailed = networkController.allPoliciesDetailed
        
        for eachPolicy in allPoliciesDetailed {
            //            print("Policy is:\(String(describing: eachPolicy))")
            
            let scriptsFound: [PolicyScripts]? = eachPolicy?.scripts
            
            for script in scriptsFound ?? [] {
                print("Script is:\(script)")
                
                //        ########################################
                //                Convert to dict
                //        ########################################
                
                assignedScriptsByNameDict[script.name ?? "" ] = String(describing: script.jamfId)
                assignedScripts.insert(script, at: 0)
            }
        }
    }
    
    func getScriptValues() {
        
        //        ########################################
        //                Convert all scripts to dict
        //        ########################################
        
        for script in networkController.scripts {
            //     DEBUG
            //            print("Script is:\(script) - add to allScriptsByNameDict")
            //        ########################################
            //                Convert to dict
            //        ########################################
            allScriptsByNameDict[script.name ] = String(describing: script.jamfId)
        }
        
        print(networkController.separationLine())
        print("assignedScriptsByNameDict initial count is:\(assignedScriptsByNameDict.count)")
        
        //        ########################################
        //        All Scripts - convert to set
        //        ########################################
        
        //        All scripts in Jamf converted to a set
        allScriptsByNameSet = Set(Array(allScriptsByNameDict.keys))
        
        //        ########################################
        //        Assigned Scripts
        //        ########################################
        
        //        All scripts found in policies
        assignedScriptsByNameSet = Set(Array(assignedScriptsByNameDict.keys))
        
        print("Set assignedScriptsArray")
        assignedScriptsArray = Array(assignedScriptsByNameSet)
        
        //        ########################################
        //        SET VARIABLES
        //        ########################################
        
        print("Set assignedScriptsArray variables")
        policyController.assignedScriptsByNameDict = assignedScriptsByNameDict
        print(policyController.assignedScriptsByNameDict.count)
        policyController.assignedScriptsArray = assignedScriptsArray
        print(policyController.assignedScriptsArray.count)
        
        //        ########################################
        //        Unassigned scripts
        //        ########################################
        
        
        print(networkController.separationLine())
        print("everything not in both - scripts not in use")
        unassignedScriptsSet = allScriptsByNameSet.symmetricDifference(assignedScriptsByNameSet)
        //        print(unassignedScriptsSet)
        print(unassignedScriptsSet.count)
        
        print(networkController.separationLine())
        print("unassignedScriptsArray")
        unassignedScriptsArray = Array(unassignedScriptsSet)
        print(unassignedScriptsArray.count)
        print("--------------------------------------------")
        print("unusedScripts are:")
        print(unassignedScriptsByNameDict.count)
        print("Set unassignedScriptsArray variables")
        //            policyController.unassignedScriptsByNameDict = unassignedScriptsByNameDict
        policyController.unassignedScriptsArray = unassignedScriptsArray
        
        print(networkController.separationLine())
        print("One set minus the contents of another - scripts not in use")
        clippedScripts = allScriptsByNameSet.subtracting(assignedScriptsByNameSet)
        print("Clipped scripts")
        print(clippedScripts.count)
        
    }
    
    var searchResults: [ScriptClassic] {
        
        let allScripts = networkController.scripts
        let allScriptsArray = Array (allScripts)
        
        if searchText.isEmpty {
            // print("Search is empty")
            return networkController.scripts
        } else {
            print("Search Added")
            return allScriptsArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
            
        }
    }
}


//
//struct ScriptUsageViewJson_Previews: PreviewProvider {
//    static var previews: some View {
//        ScriptUsageViewJson()
//    }
//}
