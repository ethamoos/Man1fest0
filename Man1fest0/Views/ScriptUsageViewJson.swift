//
//  ScriptUsageViewJson.swift
//  Manifesto
//
//  Created by Amos Deane on 01/12/2023.
//

import SwiftUI

struct ScriptUsageViewJson: View {
    
    //
    //  PackageUsageViewJson.swift
    //  Manifesto
    //
    //  Created by Amos Deane on 24/11/2023.
    //
    
    
    var server: String
    var user: String
    var password: String
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    
    //        @State var assignedScripts: [Script] = []
    @State var assignedScripts: [PolicyScripts] = []
    @State var assignedScriptsByName: [String] = []
    @State var policyScriptsByName: [String: String] = [:]
    
    //    SUMMARIES
    @State var clippedScripts = Set<String>()
    @State var differentScripts = Set<String>()
    @State var allScriptsByName: [String: String] = [:]
    @State var allScriptsByNameSet = Set<String>()
    @State var policyScriptsByNameSet = Set<String>()
    @State var totalScriptsNotUsed = 0
    
    
    
    var body: some View {
        
                
        VStack(alignment: .leading) {
            
            
            if networkController.scripts.count > 0 {
                
                Section {
                    
                    if networkController.allPoliciesDetailed.count > 0 {
                        
                        Text("Total policies in Jamf:\t\t\t\t\(networkController.policies.count )")
                            .fontWeight(.bold)
                            .padding()
                        
                        Text("Policy records downloaded:\t\t\t\(networkController.allPoliciesDetailed.count)")
                            .fontWeight(.bold)
                            .padding()
                        
                        Text("Total Scripts in Jamf:\t\t\t\t\t\(networkController.scripts.count )")
                            .fontWeight(.bold)
                            .padding()
                        
                        Text("Scripts in a policy:\t\t\t\t\t\(assignedScripts.count)")
                            .fontWeight(.bold)
                            .padding()
                        
                        Text("Scripts not in a policy:\t\t\t\t\(differentScripts.count)")
                            .fontWeight(.bold)
                            .padding()
                    }
                    
                    Button(action: {
                        getScriptsInUse()
                        getValues()
                    }) {
       
                        Text("Get Data")
                            .padding()
                        
                    }
                    .padding()
    
                    List {
                        
                        Section(header: Text("All Scripts").bold()) {
                            
                            ForEach(networkController.scripts, id: \.self) { script in
                                
                                Text(String(describing: script.name))
                                
                            }
                        }
                    }
                }
            
            
            
                List {
                    
                    Section(header: Text("Assigned Scripts").bold()) {
                        
                        ForEach(assignedScripts, id: \.self) { item in
                            
                            Text(item.name ?? "")
                        }
                    }
                    
                }
                
                
                List {
                    
                    Section(header: Text("Scripts not in use").bold()) {
                        
                        ForEach(differentScripts.sorted(), id: \.self) { item in
                            
                            Text(String(describing: item))
                        }
                    }
                }

            } else {
                
                Section {
                    
                    Group {
                        Text("Fetching detailed policies")
                            .fontWeight(.bold)
                            .padding()
                    }
                }
            }
        }.onAppear(){
            
            networkController.getAllPoliciesDetailed(to: server, as: user, password: password, resourceType: ResourceType.policies, policies: networkController.policies)
        }
        
    }
    
    func getScriptsInUse () {
        
        //        totalScriptsNotUsed = networkController.scripts.count - policyScriptsItem.count
        
        let allPoliciesDetailed = networkController.allPoliciesDetailed
        
        for eachPolicy in allPoliciesDetailed {
            
            print("Policy is:\(String(describing: eachPolicy))")
            
            let scriptsFound: [PolicyScripts]? = eachPolicy?.policy.scripts
            
            for script in scriptsFound ?? [] {
                print("Script is:\(script)")
                let scriptName = String(describing: script)
                assignedScripts.append(script)
                assignedScriptsByName.append(scriptName)
                allScriptsByName[script.name ?? "" ] = String(describing: script.jamfId)
                
            }
        }
    }
    
    func getValues() {
        
        //        All scripts in Jamf
        allScriptsByNameSet = Set(Array(allScriptsByName.keys))
        //        All scripts found in policies
        policyScriptsByNameSet = Set(Array(policyScriptsByName.keys))
        
        print(networkController.separationLine())
        print("everything in both - scripts in use")
        let commonScripts = allScriptsByNameSet.intersection(policyScriptsByNameSet)
        //        print(commonScripts)
        print(commonScripts.count)
        
        print(networkController.separationLine())
        print("everything not in both - scripts not in use")
        differentScripts = allScriptsByNameSet.symmetricDifference(policyScriptsByNameSet)
        //        print(differentScripts)
        print(differentScripts.count)
        
        print(networkController.separationLine())
        print("One set minus the contents of another - scripts not in use")
        clippedScripts = allScriptsByNameSet.subtracting(policyScriptsByNameSet)
        //        print(clippedScripts)
        print(clippedScripts.count)
        
        
    }
    
}


//
//struct PackageUsageViewJson_Previews: PreviewProvider {
//    static var previews: some View {
//        PackageUsageViewJson()
//    }
//}
