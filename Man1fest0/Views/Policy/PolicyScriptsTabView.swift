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
    @State var replacementParameter4 = ""
    @State var replacementParameter5 = ""
    @State var replacementParameter6 = ""
    @State var replacementParameter7 = ""
    @State var replacementParameter8 = ""
    @State var replacementParameter9 = ""
    @State var replacementParameter10 = ""

    //  ########################################################################################
    //  Selections
    //  ########################################################################################
    
    @Binding var computerGroupSelection: Set<ComputerGroup>
    @State private var selection: PolicyScripts? = nil
    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
    @State var listSelection: PolicyScripts = PolicyScripts(id:(UUID(uuidString: "") ?? UUID()) , jamfId: 0, name: "")
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
    @State var priority: String = "Before"
    
    var body: some View {
        
        VStack(alignment: .leading) {
                        
            Group {

// ################################################################################
//              SCRIPTS
// ################################################################################

//              ################################################################################
//              List scripts
//              ################################################################################

                if networkController.currentDetailedPolicy?.policy.scripts?.count ?? 0 > 0 {
                    
                    Text("Scripts").bold()
#if os(macOS)
                    List(networkController.currentDetailedPolicy?.policy.scripts ?? [PolicyScripts](), id: \.self, selection: $listSelection) { script in
                        //                        if script != nil {
                        var currentScript = script
                        //                    }
                        HStack {
                            
                            Text(script.name ?? "")
                            if script.parameter4 != "" {
                                Text("\t\tParams:").bold()

                                Image(systemName: "1.circle")
                                Text(script.parameter4 ?? "" )
                            }
                            if script.parameter5 != "" {
                                Image(systemName: "2.circle")
                                Text(script.parameter5 ?? "" )
                            }
                            if script.parameter6 != "" {
                                Image(systemName: "3.circle")
                                Text(script.parameter6 ?? "" )
                            }
                            if script.parameter7 != "" {
                                Image(systemName: "4.circle")
                                Text(script.parameter7 ?? "" )
                            }
                            if script.parameter8 != "" {
                                Image(systemName: "5.circle")
                                Text(script.parameter8 ?? "" )
                            }
                            if script.parameter9 != "" {
                                Image(systemName: "6.circle")
                                Text(script.parameter9 ?? "" )
                            }
                            if script.parameter10 != "" {
                                Image(systemName: "7.circle")
                                Text(script.parameter10 ?? "" )
                            }
                        }
                    }
                    .frame(minHeight: 100)
                    .frame(minWidth: 100, maxWidth: .infinity)
#else
                    List(networkController.currentDetailedPolicy?.policy.scripts ?? [PolicyScripts](), id: \.self) { script in
                        HStack {
                            Image(systemName: "applescript")
                            Text(script.name ?? "" )
                        }
                    }
                    .frame(minHeight: 50)
#endif
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
                        
                        xmlController.replaceScriptParameter(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: networkController.currentPolicyAsXML, selectedScriptNumber: pickerSelectedScript, parameter4: replacementParameter4, parameter5: replacementParameter5, parameter6: replacementParameter6, parameter7: replacementParameter7, parameter8: replacementParameter8, parameter9: replacementParameter9, parameter10: replacementParameter10)
                    }) {
                        Text("Update Parameter")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    LazyVGrid(columns: layout.threeColumns) {
//
                        Picker("Script", selection: $pickerSelectedScript) {
                            ForEach(1..<10) {
                                Text("\($0)")
                            }
                            Text("You selected: \(pickerSelectedScript)")

                        }
//                        .onChange(of:pickerSelectedScript) { value in
//                            print("Value is:\(value)")
//                        }
                        .onChange(of: pickerSelectedScript) { newValue in
                                       print("pickerSelectedScript changed to \(pickerSelectedScript)")
                                   }
                        .onAppear {
                            print("pickerSelectedScript is currently:\(pickerSelectedScript)")
//                            if pickerSelectedScript.isEmpty != true {
//                                print("Setting numbers picker default")
//                                pickerSelectedScript = 0 }
                        }
                        TextField("", text: $replacementParameter4)
                    }
                }
                
//                HStack {
                    DisclosureGroup("More Parameters") {
                        
                        HStack {
                            LazyVGrid(columns: layout.columns) {
                                TextField("", text: $replacementParameter6)
                                TextField("", text: $replacementParameter7)
                            }
                        }
                        
                        HStack {
                            LazyVGrid(columns: layout.columns) {
                                TextField("", text: $replacementParameter8)
                                TextField("", text: $replacementParameter9)
                                TextField("", text: $replacementParameter10)
                            }
                        }
                    }
              
                    DisclosureGroup("Notes") {
                        VStack() {
                        NotesView()
                    }
                        .frame(minHeight: 60, alignment: .leading)

                        //                    NavigationLink(destination: NotesView())
//                    }
                }
                Divider()
                
                //  ################################################################################
                //              Scripts picker
                //  ################################################################################
                
                LazyVGrid(columns: layout.threeColumns, spacing: 10) {
                    Picker(selection: $selectedScript, label: Text("Scripts")) {
                        ForEach(networkController.scripts, id: \.self) { script in
                            Text(String(describing: script.name))
                                .tag(script as ScriptClassic?)
                                .tag(selectedScript as ScriptClassic?)
                        }
                        .onAppear {
                            if networkController.scripts.isEmpty != true {
                                print("Setting package picker default")
                                selectedScript = networkController.scripts[0] }
                        }
                    }
//                    .onReceive([self.selectedScript].publisher.first()) { (selectedScript) in
//                        print("selectedScript is:\(String(describing: selectedScript.name))")
//                        print("selectedScriptID is:\(String(describing: selectedScript.id))")
//                    }
                }
            }
//            .pickerStyle(SegmentedPickerStyle()) // You can choose the style that suits your UI
            
            //              ################################################################################
            //              Add script
            //              ################################################################################
            
            Group {
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
//                    networkController.readXMLDataFromString(xmlContent: networkController.currentPolicyAsXML)
                    
                    xmlController.addScriptToPolicy(xmlContent: xmlController.xmlDoc,xmlContentString: networkController.currentPolicyAsXML, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyId: String(describing: policyID), scriptName: selectedScript.name, scriptId: String(describing: selectedScript.jamfId),scriptParameter4: scriptParameter4, scriptParameter5: scriptParameter5 , scriptParameter6: scriptParameter6, scriptParameter7: scriptParameter7, scriptParameter8: scriptParameter8, scriptParameter9: scriptParameter9, scriptParameter10: scriptParameter10,scriptParameter11: scriptParameter11, priority: priority,newPolicyFlag: false)
                    
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
            }
            //        }
            //            }
            
            Group {
                Divider()
                LazyVGrid(columns: columns, spacing: 10) {
                    VStack(alignment: .leading) {
                        DisclosureGroup("Parameters") {

//                        Group {
//                            Text("Parameters")
                            TextField("Parameter 4", text: $scriptParameter4)
                            TextField("Parameter 5", text: $scriptParameter5)
                            TextField("Parameter 6", text: $scriptParameter6)
                            TextField("Parameter 7", text: $scriptParameter7)
                            TextField("Parameter 8", text: $scriptParameter8)
                            TextField("Parameter 9", text: $scriptParameter9)
                            TextField("Parameter 10", text: $scriptParameter10)
                            TextField("Parameter 11", text: $scriptParameter11)
                            Text("Priority:")
                            TextField("Before/After?", text: $priority)
                            
                        }
                    }
                }
            }
        }
        .frame(minWidth: 400, alignment: .leading)
        .padding()
        .onAppear() {
            
            if  networkController.scripts.count <= 1 {
                print("Fetching scripts")
                print("Script count is:\(networkController.scripts.count))")
    //            print(networkController.packages.count)
                networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)

            } else {
                
                print("script data is available")
//                print("Count is:\(networkController.scripts.count))")
                
            }
//            if networkController.scripts.count == 0 {
//                      print("Fetching scripts")
//                networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
//            }
        }
    }
}

//}
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
//
//    }
//}
//
//}
//}



//#Preview {
//    PolicyEditTabView()
//}


