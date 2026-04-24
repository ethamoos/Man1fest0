import SwiftUI

struct ComputersView: View {
    
    @State var server: String
    @State var computersBasic: [ComputerBasicRecord] = []
    @State private var searchText = ""
    @State private var computerGroupFilter: String = ""
    
    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var networkController: NetBrain
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var prestageController: PrestageBrain
    
    //  ########################################################################################
    //  Selections
    //  ########################################################################################
    
    @State var selection = Set<ComputerBasicRecord.ID>()
    // single selected computer for the detail pane
    @State private var selectedComputer: ComputerBasicRecord? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Computers")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Browse and manage computers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        try await networkController.getComputersBasic(server: server,authToken: networkController.authToken)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 6)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.02)))
            
            if networkController.allComputersBasic.computers.count > 0 {
                
                // Use a two-pane split view on macOS (master list on the left, detail pane on the right)
#if os(macOS)
                NavigationSplitView {
                    // Master list (supports multi-selection via `selection` for batch operations)
                    List(selection: $selection) {
                        ForEach(searchResults) { computer in
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text(computer.name)
                                        .font(.system(size: 13.0))
                                    HStack(spacing: 8) {
                                        Text("Serial: \(computer.serialNumber)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        // Show prestage if known
                                        if let psId = prestageController.allPrestagesScope?.serialsByPrestageID[computer.serialNumber] ?? prestageController.serialPrestageAssignment[computer.serialNumber] {
                                            let psName = prestageController.allPrestages.first(where: { $0.id == psId })?.displayName ?? "(id:\(psId))"
                                            Text("Prestage: \(psName)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .tag(computer.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // update the single-selection used by the detail pane
                                selectedComputer = computer
                                // also update the List's selection set so the row is highlighted
                                selection = [computer.id]
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .frame(minWidth: 300)
                    .searchable(text: $searchText)
                    // Keep the selectedComputer in sync if the list selection changes via keyboard/other interactions
                    .onChange(of: selection) { newSelection in
                        if let firstId = newSelection.first,
                           let found = networkController.allComputersBasic.computers.first(where: { $0.id == firstId }) {
                            selectedComputer = found
                        } else {
                            selectedComputer = nil
                        }
                    }
                } detail: {
                    // Detail pane - show selected computer detail or a placeholder
                    if let comp = selectedComputer {
                        ComputersDetailedView(server: server, computerID: String(comp.id))
                            .id(comp.id)
                            .environmentObject(networkController)
                            .environmentObject(xmlController)
                            .environmentObject(progress)
                            .environmentObject(prestageController)
                    } else {
                        Text("Select a computer to view details")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationViewStyle(DefaultNavigationViewStyle())
#else
                // On other platforms, fall back to the existing list with NavigationLinks
                List(searchResults, id: \.self) { computer in
                    NavigationLink(destination: ComputersDetailedView(server: server, computerID: String(computer.id))
                                    .environmentObject(networkController)
                                    .environmentObject(xmlController)
                                    .environmentObject(progress)
                                    .environmentObject(prestageController)) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(computer.name)
                                    .font(.system(size: 13.0))
                                Text("Serial: \(computer.serialNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .searchable(text: $searchText)
#endif
                
                // Footer count
                Text("\(networkController.computers.count) total computers")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
                    .navigationViewStyle(DefaultNavigationViewStyle())
                
            } else {
                
                ProgressView {
                    Text("Loading data")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                .padding()
                Spacer()
                
                    .onAppear {
                        print("Fetching computers")
                        Task {
                            try await networkController.getComputersBasic(server: server,authToken: networkController.authToken)
                        }
                    }
            }
        }
        .padding()
    }
    
    var searchResults: [ComputerBasicRecord] {
        let allComputers = networkController.allComputersBasic.computers
        let allComputersArray = Array(allComputers)
        if searchText.isEmpty {
            return networkController.allComputersBasic.computers.sorted { $0.name < $1.name }
        } else {
            return allComputersArray.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}
