import SwiftUI


struct ScriptsView: View {

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    
    @State private var searchText = ""
    @State private var debouncedQuery = ""
    @StateObject private var searchDebouncer = Debouncer()
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
                    .onChange(of: searchText) { newValue in
                        // debounce updates to the query used for filtering
                        searchDebouncer.debounce(interval: 0.35) {
                            Task {
                                await MainActor.run {
                                    self.debouncedQuery = newValue
                                }
                            }
                        }
                    }

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
        let query = debouncedQuery.isEmpty ? searchText : debouncedQuery
        if query.isEmpty {
            return networkController.scripts
        } else {
            return networkController.scripts.filter { $0.name.lowercased().contains(query.lowercased())}
        }
    }
}
