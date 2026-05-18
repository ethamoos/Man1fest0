//
//  ConfigProfileViewMacOS.swift
//  Man1fest0
//
//  Created by Amos Deane on 22/11/2023.
//

import SwiftUI

struct ConfigProfileViewMacOSTable: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var layout: Layout
    
    @State var server: String
    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\ConfigProfileSummary.name, order: .reverse)]
    @State private var showingWarning = false
    
    @State private var selectionID = Set<ConfigProfileSummary.ID>()
    // Rename tools for config profiles
    @State private var toolsNameAction: String = "removelast"
    @State private var toolsCountString: String = "1"
    @State private var toolsMatchString: String = ""
    @State private var toolsReplacementString: String = ""
    @State private var selectedDevice = ""
    @State private var selectedCommand = ""
    @State var selectedGroup: ComputerGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    @State var selectedCategory: Category? = Category(jamfId: 0, name: "")

    
    var body: some View {

            VStack {
                
                if networkController.allConfigProfiles.computerConfigurations?.count ?? 0 > 0 {
                    
                    Table(networkController.allConfigProfiles.computerConfigurations!, selection: $selectionID, sortOrder: $sortOrder) {
                        
                        TableColumn("Name", value: \.name) {
                            profile in
                            Text(String(profile.name))
                        }
                        
                        TableColumn("ID", value: \.jamfId!) {
                            profile in
                            Text(String(profile.jamfId ?? 0))
                        }
                    }
                    .onChange(of: sortOrder) { newOrder in
                        networkController.allConfigProfiles.computerConfigurations! .sort(using: newOrder)
                    }
                    Divider()
                    VStack(alignment: .leading) {

                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            showingWarning = true
                            print("Deleting:\($selectionID)")
                            networkController.deleteConfigProfile(server: server, authToken: networkController.authToken, resourceType: ResourceType.configProfileDetailedMacOS, itemID: String(describing: selectionID))
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        
                        // Rename tools
                        DisclosureGroup("Rename Tools") {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Action", selection: $toolsNameAction) {
                                    Text("Remove last chars").tag("removelast")
                                    Text("Replace last chars").tag("replacelast")
                                    Text("Replace all occurrences").tag("replaceall")
                                }
                                .pickerStyle(.segmented)

                                HStack(spacing: 8) {
                                    if toolsNameAction == "removelast" || toolsNameAction == "replacelast" {
                                        TextField("Count", text: $toolsCountString)
                                            .frame(width: 80)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    if toolsNameAction == "replacelast" || toolsNameAction == "replaceall" {
                                        TextField("Replacement", text: $toolsReplacementString)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    if toolsNameAction == "replaceall" {
                                        TextField("Match", text: $toolsMatchString)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    Spacer()
                                    Button(action: {
                                        let countInt = Int(toolsCountString) ?? 0
                                        progress.showProgress()
                                        progress.waitForABit()
                                        Task {
                                            if let profiles = networkController.allConfigProfiles.computerConfigurations {
                                                let selected = profiles.filter { selectionID.contains($0.id) }
                                                for prof in selected {
                                                    if let pid = prof.jamfId {
                                                        networkController.updateConfigProfileNameLogical(server: server, authToken: networkController.authToken, resourceType: ResourceType.configProfileDetailedMacOS, profileID: String(pid), action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)
                                                        try? await Task.sleep(nanoseconds: 200_000_000)
                                                    }
                                                }
                                            }
                                            progress.endProgress()
                                        }
                                    }) {
                                        Text("Run on Selected")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding()
                        }
                        
                        
                        LazyVGrid(columns: layout.columnsFlex) {
                            
                            Picker(selection: $selectedGroup, label: Text("Computer Group")) {
                                //                                                         //
                                ForEach(networkController.allComputerGroups, id: \.self) { group in
                                    Text(String(describing: group.name)).tag(group.name)
                                        .tag(group as ComputerGroup?)
                                        .tag(selectedGroup as ComputerGroup?)
                                }
                            }
                            .onAppear {
                                
                                if networkController.allComputerGroups.isEmpty != true {
                                    print("Setting groups picker default")
                                    selectedGroup = networkController.allComputerGroups[0]
                                }
                            }
                        }
                        
                        HStack {
                            LazyVGrid(columns: layout.columnsFlex) {
                                Picker("Commands", selection: $selectedCommand) {
                                    ForEach(pushController.flushCommands, id: \.self) {
                                        Text(String(describing: $0)).tag($0)
                                    }
                                }
                            }
                            
                            Button("Flush Commands") {
                                
                                progress.showProgress()
                                progress.waitForABit()
                                
                                Task {
                                    try await pushController.flushCommands(targetId: selectedGroup.id, deviceType: "computergroups", command: selectedCommand, authToken: networkController.authToken, server: server )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                         Spacer()
                        }
                    }
                } else {
                    ProgressView {
                        Text("Loading data")
                            .font(.title)
                            .progressViewStyle(.horizontal)
                    }
                    .padding()
                    Spacer()
                }
        }
        .onAppear {
            
            Task {
                try await networkController.getOSXConfigProfiles(server: server, authToken: networkController.authToken)
            }
            
            Task {
                try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
            }
        }
        .padding()
        .textSelection(.enabled)
    }
    
    var searchResults: [ConfigProfileSummary] {
        if searchText.isEmpty {
            return networkController.allConfigProfiles.computerConfigurations!
        } else {
            print("Search is currently:\(searchText)")
            return networkController.allConfigProfiles.computerConfigurations!.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}



//struct ConfigProfilesView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigProfilesView()
//    }
//}
