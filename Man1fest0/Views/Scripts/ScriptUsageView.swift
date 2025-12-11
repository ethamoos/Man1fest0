//
//  ScriptUsageViewJson.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/11/2023.
//
//

import SwiftUI

struct ScriptUsageView: View {
    
    var server: String
    // var username: String
    // var password: String
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var deletionController: DeletionBrain
    @EnvironmentObject var policyController: PolicyBrain
    // @EnvironmentObject var controller: JamfController
    
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
    
    //    @State var fetchedDetailedPolicies: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.scripts.count > 0 {
                
                //        ########################################
                //        All scripts
                //        ########################################
                
                if networkController.allPoliciesConverted.count != networkController.allPoliciesDetailed.count {
                    
                    Section(header: Text("All Scripts").bold().padding()) {
                        
                        List {
                            
                            ForEach(searchResults, id: \.self) { script in
                                
                                HStack {
                                    Image(systemName: "applescript")
                                    Text(String(describing: script.name))
                                }
                            }
                        }
                        .searchable(text: $searchText)
                        .foregroundColor(.blue)
                    }
                }
                
                //        ########################################
                //        Assigned scripts
                //        ########################################
                
//                if networkController.allPoliciesConverted.count == networkController.allPoliciesDetailed.count {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        
                        Section(header: Text("Assigned Scripts").bold().padding()) {
                            
                            List(selection: $selection) {
                                ForEach(assignedScriptsByNameDict.keys.sorted(), id: \.self) { script in
                                    HStack {
                                        Text(script)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    //        ########################################
                    //        Unassigned scripts
                    //        ########################################
                    
                    Section(header: Text("Scripts not in use").bold().padding()) {
                                                
                        List(selection: $selection) {
                            ForEach(unassignedScriptsSet.sorted(), id: \.self) { script in
                                HStack {
                                    Text(script)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        print("Selection is:")
                        print(selection)
                        
                        selectedValue = selection
                            .compactMap { policyController.allScriptsByNameDict[$0] }
                            .joined(separator: ", ")
                        
                        selectedKey = selection.map{return $0}
                        
                        let selectedValueArray = selectedValue.components(separatedBy: ",")
                        
                        print("selectedValue is: \(selectedValue)")
                        print("selectedKey is: \(selectedKey)")
                        print("selectedValueArray is: \(selectedValueArray)")
                        
                        for eachItem in selectedValueArray {
                            print("Item untrimmed:\(eachItem)")
                            let eachItemTrimmed = eachItem.trimmingCharacters(in: .whitespacesAndNewlines)
                            print("Item trimmed:\(eachItemTrimmed)")
                            Task {
                                try await deletionController.deleteScript(server: server, resourceType: ResourceType.script, itemID: eachItemTrimmed, authToken: networkController.authToken)
                            }
                        }
                    }) {
                        Text("Delete Selection")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .padding()
//                }
                
                
                Group {
                    
                    if networkController.allPoliciesDetailed.count > 0 {
                        
                        VStack(alignment: .leading, spacing: 5) {
                            
                            Text("Total policies in Jamf:\t\t\t\t\(networkController.allPoliciesConverted.count )")
                                .fontWeight(.bold)
                            
                            Text("Policy records downloaded:\t\t\t\(networkController.allPoliciesDetailed.count)")
                                .fontWeight(.bold)
                            
                            Text("Total Scripts in Jamf:\t\t\t\t\t\(networkController.scripts.count )")
                            
                                .fontWeight(.bold)
                            
                            Text("Scripts in a policy:\t\t\t\t\t\(assignedScriptsByNameDict.count)")
                                .fontWeight(.bold)
                            
                            
                            Text("Scripts not in a policy:\t\t\t\t\(unassignedScriptsArray.count)")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .border(.blue)
                    }
                }
                
                    HStack {
                        
//                        if networkController.allPoliciesConverted.count == networkController.allPoliciesDetailed.count {
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                
                                getScriptsInUse()
                                getScriptValues()
                            }) {
                                Text("Analyse Data")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
//                        }
                        
                        Button(action: {
                            
                            networkController.allPoliciesDetailed.removeAll()
                            Task {
                                try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                            }
                        }) {
                            Text("Refresh Policy Data")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding()
                
                if progress.showProgressView == true {
                    
                    ProgressView {
                        Text("Loading")
                            .font(.title)
                            .progressViewStyle(.horizontal)
                    }
                    .padding()
                    Spacer()
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
