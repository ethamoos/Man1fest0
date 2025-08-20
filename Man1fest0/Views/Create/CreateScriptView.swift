//
//  CreateScriptView.swift
//  Man1fest0
//
//  Created by Amos Deane on 23/05/2025.
//


import SwiftUI

struct CreateScriptView: View {
    
    //    var script: ScriptClassic
    var scriptID: Int = 0
    var server: String
    
//    @State private var title: String = ""
    @State private var bodyText: String = ""
    
    //    @Binding
    //    var isNewNotePresented: Bool
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var policyController: PolicyBrain
    
    
    //              ################################################################################
    //              categories
    //              ################################################################################
    
    @State var categoryName = ""
    
    @State private var categoryID = ""
    
    @State var categories: [Category] = []
   
    //              ################################################################################
    //              Scripts
    //              ################################################################################
    
    @State var newScriptName = ""
    
    //    @State var scriptID = ""
    
    @State var scriptParameter4: String = ""
    @State var scriptParameter5: String = ""
    @State var scriptParameter6: String = ""
    @State var scriptParameter7: String = ""
    @State var scriptParameter8: String = ""
    @State var scriptParameter9: String = ""
    @State var scriptParameter10: String = ""
    @State var scriptParameter11: String = ""
    @State var info: String = ""
//    @State var filename: String = ""
    @State var notes: String = ""
    @State var os_requirements: String = ""
    @State var script_contents_encoded: String = ""
    @State var priority: String = ""
    @State var script_contents: String = ""
    
    
    //              ################################################################################
    //              Selections
    //              ################################################################################
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {

            LazyVGrid(columns: columns, spacing: 30) {
                
                HStack {
                    Image(systemName:"hammer")
                    TextField("Script Name", text: $newScriptName)
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        layout.separationLine()
                        print("Creating New Script:\(newScriptName)")
                        print("Category:\(selectedCategory.name)")
//                        print("Department:\(selectedDepartment.name)")
                        
                        xmlController.createScript(name: newScriptName, category: selectedCategory.name, filename: newScriptName, info: info, notes: notes, priority: priority, parameter4: scriptParameter4, parameter5: scriptParameter5, parameter6: scriptParameter6, parameter7: scriptParameter7, parameter8: scriptParameter8, parameter9: scriptParameter10, parameter10: scriptParameter4, parameter11: scriptParameter11, os_requirements: os_requirements, script_contents: bodyText, script_contents_encoded: script_contents_encoded, scriptID: "0", server: server, authToken: networkController.authToken)
                        
                        
                    }) {
                        Text("Create")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            
            Text("Note: All Fields Must Be Filled")
            
            
            // ##########################################################################################
            //                        Category
            // ##########################################################################################
            Divider()
            
            Group {
                LazyVGrid(columns: columns, spacing: 30) {
                    Picker(selection: $selectedCategory, label: Text("Category")) {
                        ForEach(networkController.categories, id: \.self) { category in
                            Text(String(describing: category.name))
                        }
                    }
                }
            }
            
            Divider()
            
            Group {
                
                
                // ######################################################################################
                //                        Script parameters
                // ######################################################################################
                
                LazyVGrid(columns: layout.threeColumnsAdaptive, spacing: 5) {
                    
                    HStack(spacing: 20) {
                        TextField("Parameter 4", text: $scriptParameter4)
                        TextField("Parameter 5", text: $scriptParameter5)
                        TextField("Parameter 6", text: $scriptParameter6)
                    }
                }
            }
            
        }
        .padding()
        
        Group {
            
            Divider()
            
            
            VStack(alignment: .leading, spacing: 10) {
                TextField("Title", text: $newScriptName)
                    .padding(4)
                    .border(Color.blue)
                TextField("Info", text: $info)
                    .padding(4)
                    .border(Color.blue)
                 TextField("Notes", text: $notes)
                    .padding(4)
                    .border(Color.blue)
                
                TextEditor(text: $bodyText)
                    .border(Color.blue)
                
            }
            .padding()
        }
        
//    }
//    . padding()
//    .frame(minWidth: 100, maxWidth: 600, minHeight: 70, maxHeight: .infinity)
//
//        
//            
//            
//        }
        //        .padding()
        //
        //        .overlay(
        //            RoundedRectangle(cornerRadius: 8)
        //                .strokeBorder(
        //                    Color.black.opacity(0.4),
        //                    style: StrokeStyle()
        //                )
        //        )
        //        .multilineTextAlignment(.leading)
        //        .padding(30)
        //        .frame(minWidth: 140, alignment: .leading)
        //        .padding()
        //        .foregroundColor(.blue)
        //        .textSelection(.enabled)
        
        
        .onAppear() {
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            }
        }
        
        
        //  ################################################################################
        //  Progress view via showProgress
        //  ################################################################################
        
        if progress.showProgressView == true {
            
            ProgressView {
                Text("Processing")
            }
            .padding()
        } else {
            Text("")
        }
        //
        //            Task {
        //                try await networkController.getDetailedScript(server: server, scriptID: scriptID, authToken: networkController.authToken)
        //            }
        //        }
    }
}
