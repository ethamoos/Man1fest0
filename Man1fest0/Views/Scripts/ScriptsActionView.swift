//
//  ScriptsActionView.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/05/2025.
//


import SwiftUI


struct ScriptsActionView: View {
        
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    
    @State private var searchText = ""
    @State var selection = Set<ScriptClassic>()
    @State private var showingWarning = false
    
    var server: String

    @State var scripts: [ScriptClassic] = []
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.scripts.count > 0 {
                
                // Removed inner NavigationView to avoid creating duplicate NSToolbar search items.
                List(searchResults, id: \.self, selection: $selection) { script in
                    HStack {
                        Image(systemName: "applescript")
                        Text("\(script.name)").font(.system(size: 12.0)).foregroundColor(.blue)
                    }
#if os(macOS)
                    .navigationTitle("Scripts")
#endif
                    .foregroundColor(.blue)
                }
#if os(macOS)
                .frame(minWidth: 300, maxWidth: .infinity)
#endif
                .toolbar {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        print("Refresh")
                        networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                }
                .searchable(text: $searchText)
                
                //              ################################################################################
                //              Toolbar - END
                //              ################################################################################
                
                #if os(macOS)
                
                VStack(alignment: .leading) {
                    
                    Text("Selections").fontWeight(.bold)
                    List(Array(selection), id: \.self) { script in
                        Text(script.name )
                    }
                    
                    //              ################################################################################
                    //              DELETE
                    //              ################################################################################
                    
                    HStack(spacing:20) {
                        Button(action: {
                            showingWarning = true
                       
                        }) {
                            Text("Delete")
                        }
                        .alert(isPresented: $showingWarning) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    // Code to execute when "Yes" is tapped
                                    progress.showProgressView = true
                                    progress.waitForABit()
                                    Task {
                                        try await networkController.batchDeleteScripts(selection: selection, server: server, authToken: networkController.authToken, resourceType: ResourceType.script)
                                    }
                                    print("Yes tapped")
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        .frame(height: 50)
                    }
                }
                .padding()
#endif
            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                }
            }
        }
        
//        .frame(minWidth: 200, minHeight: 100, alignment: .leading)
        
        .frame(minWidth: 300, minHeight: 100, alignment: .leading)

        .onAppear {
            networkController.separationLine()
            print("ScriptsView appeared.")
            print(networkController.scripts.count)
            if networkController.scripts.count == 0 {
                      print("Fetching scripts")
                networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
            }
        }
        
        if progress.showProgressView == true {
            
            ProgressView {
                
                Text("Processing")
                    .padding()
            }
        } else {
            Text("")
        }
    }
    
    var searchResults: [ScriptClassic] {
        if searchText.isEmpty {
            return networkController.scripts
        } else {
            return networkController.scripts.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}
