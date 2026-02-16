import SwiftUI


struct ScriptsView: View {

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    
    @State private var searchText = ""
    @State var selection = Set<ScriptClassic>()
    
//    var selectedResourceType: ResourceType
    
    var server: String

    @State var scripts: [ScriptClassic] = []
//    @State var scripts: [Script] = []
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.scripts.count > 0 {
                
                NavigationView {
                    
                    List(searchResults, selection: $selection) { script in
                        NavigationLink(destination: ScriptsDetailView(script: script, scriptID: script.jamfId, server: server)) {
                            
                            HStack {
                                Image(systemName: "applescript")
                                Text("\(script.name)").font(.system(size: 12.0)).foregroundColor(.blue)
                            }
#if os(macOS)
                            .navigationTitle("Scripts")
#endif
                            .foregroundColor(.blue)
                        }
                    }
                    
#if os(macOS)
                        .frame(minWidth: 300, maxWidth: .infinity)
#endif
                    
                    //              ################################################################################
                    //              Toolbar
                    //              ################################################################################
                    
                    .toolbar {
                        
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            print("Refresh")
//                            Task {
//                               try await networkController.getAllScripts(server: server, authToken: networkController.authToken)
//                            }
                            networkController.connect(server: server,resourceType: ResourceType.scripts, authToken: networkController.authToken)
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                    }
                    
                    //              ################################################################################
                    //              Toolbar - END
                    //              ################################################################################
                    
                    .searchable(text: $searchText)

                    Text("\(networkController.scripts.count) total scripts")
                }
                
                #if os(macOS)
                .navigationTitle("Scripts")
#endif
                .navigationViewStyle(DefaultNavigationViewStyle())
                
            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                }
            }
        }
        
        .frame(minWidth: 200, minHeight: 100, alignment: .leading)

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
            // print("Search is empty")
//            DEBUG
//            print(networkController.scripts)
            return networkController.scripts
        } else {
            // print("Search is currently is currently:\(searchText)")
//            DEBUG
//            print(networkController.scripts)
            return networkController.scripts.filter { $0.name.lowercased().contains(searchText.lowercased())}
            
        }
    }
}
