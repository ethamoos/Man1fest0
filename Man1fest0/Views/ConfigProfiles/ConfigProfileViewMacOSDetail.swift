//
//  ConfigProfileDetailView.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/11/2023.
//

import SwiftUI

struct ConfigProfileViewMacOSDetail: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var pushController: PushBrain
    @EnvironmentObject var layout: Layout

    // selection is a lightweight summary (ConfigProfileSummary)
    @State var selection: ConfigProfileSummary
    @State private var selectedDevice = 0
//    @State private var selectedCommand = ""
    // Make currentProfile optional so we can represent "not loaded" state
    @State private var currentProfile: OSXConfigProfileDetailed? = nil

    @State var server: String
    
//    @State var deviceTypes = [ "computer", "mobile" ]
//    @State var flushCommands = [ "Pending", "Failed", "Pending+Failed" ]
    
    @State private var showingWarning = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Section(header: Text("Config Profile Detail").bold()) {
              
                // Safely unwrap and display profile fields. Avoid interpolating whole structs.
                if let general = currentProfile?.general {
                    Text("Name:\t\(general.name ?? "")")
                    if let id = general.id {
                        Text("ID:\t\(id)")
                    } else {
                        Text("ID:\t(none)")
                    }
                } else {
                    Text("Name:\t")
                    Text("ID:\t")
                }

                // Display a compact summary of scope
                if let scope = currentProfile?.scope {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 20) {
                            Text("All Computers: \(scope.allComputers == true ? "Yes" : "No")")
                            Text("All Users: \(scope.allJssUsers == true ? "Yes" : "No")")
                        }

                        // Helper to render arrays of ConfigCategoryElement
                        Group {
                            if let computers = scope.computers, !computers.isEmpty {
                                Text("Computers:").font(.subheadline).bold()
                                ForEach(computers, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }

                            if let buildings = scope.buildings, !buildings.isEmpty {
                                Text("Buildings:").font(.subheadline).bold()
                                ForEach(buildings, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }

                            if let departments = scope.departments, !departments.isEmpty {
                                Text("Departments:").font(.subheadline).bold()
                                ForEach(departments, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }

                            if let groups = scope.computerGroups, !groups.isEmpty {
                                Text("Computer Groups:").font(.subheadline).bold()
                                ForEach(groups, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }

                            if let users = scope.jssUsers, !users.isEmpty {
                                Text("JSS Users:").font(.subheadline).bold()
                                ForEach(users, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }

                            // jss_user_groups is a dictionary – show values if present
                            if let jssUserGroups = scope.jssUserGroups, !jssUserGroups.isEmpty {
                                Text("JSS User Groups:").font(.subheadline).bold()
                                ForEach(Array(jssUserGroups.values), id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                        }

                        // Limitations
                        if let lim = scope.limitations {
                            if let users = lim.users, !users.isEmpty {
                                Text("Limitations - Users:").font(.subheadline).bold()
                                ForEach(users, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                            if let userGroups = lim.userGroups, !userGroups.isEmpty {
                                Text("Limitations - User Groups:").font(.subheadline).bold()
                                ForEach(userGroups, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                            if let networks = lim.networkSegments, !networks.isEmpty {
                                Text("Limitations - Network Segments:").font(.subheadline).bold()
                                ForEach(networks, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                            if let ibeacons = lim.ibeacons, !ibeacons.isEmpty {
                                Text("Limitations - iBeacons:").font(.subheadline).bold()
                                ForEach(ibeacons, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                        }

                        // Exclusions
                        if let exc = scope.exclusions {
                            if let computers = exc.computers, !computers.isEmpty {
                                Text("Exclusions - Computers:").font(.subheadline).bold()
                                ForEach(computers, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                            if let buildings = exc.buildings, !buildings.isEmpty {
                                Text("Exclusions - Buildings:").font(.subheadline).bold()
                                ForEach(buildings, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                            if let departments = exc.departments, !departments.isEmpty {
                                Text("Exclusions - Departments:").font(.subheadline).bold()
                                ForEach(departments, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                            if let groups = exc.computerGroups, !groups.isEmpty {
                                Text("Exclusions - Computer Groups:").font(.subheadline).bold()
                                ForEach(groups, id: \.self) { item in
                                    Text("• \(item.name ?? String(describing: item.id ?? 0))")
                                }
                            }
                        }
                    }
                } else {
                    Text("Scope: (not loaded)")
                }
            }

//            LazyVGrid(columns: layout.columnsFlex) {
//                Picker("Devices", selection: $selectedDevice) {
//                    ForEach(pushController.deviceTypes, id: \.self) {
//                        Text(String(describing: $0))
//                    }
//                }
//            }
//
//            LazyVGrid(columns: layout.columnsFlex) {
//                Picker("Commands", selection: $selectedCommand) {
//                    ForEach(pushController.flushCommands, id: \.self) {
//                        Text(String(describing: $0))
//                    }
//                }
//            }
//
//            Button("Flush Commands") {
//
//                progress.showProgress()
//                progress.waitForABit()
//
//                Task {
//                   try await pushController.flushCommands(deviceId: selection.jamfId!, deviceType: selectedDevice, command: selectedCommand, authToken: networkController.authToken, server: server )
//                }
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(.blue)
//            .shadow(color: .gray, radius: 2, x: 0, y: 2)
            
            Button(action: {
                progress.showProgress()
                progress.waitForABit()
                showingWarning = true
                // Use selection (not $selection which is a Binding) in debug output
                print("Deleting:\(selection)")
                networkController.deleteConfigProfile(server: server, authToken: networkController.authToken, resourceType: ResourceType.configProfileDetailedMacOS, itemID: String(describing: selection.jamfId ?? 0))
                print("Deleting ConfigProfile:\(String(describing: selection.jamfId ?? 0))")
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                    Text("Delete Profile")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .shadow(color: .gray, radius: 2, x: 0, y: 2)

            Spacer()
        }
  
        .padding(20)
        .onAppear() {
            // Initialize currentProfile from the network controller if present and kick off any async work
            currentProfile = networkController.OSXConfigProfileDetailed
            if let jamfId = selection.jamfId {
                Task {
                    do {
                        try await networkController.getDetailOSXConfigProfile(userID: String(jamfId))
                        // update local currentProfile after fetch
                        currentProfile = networkController.OSXConfigProfileDetailed
                    } catch {
                        print("Failed to load config profile\(jamfId) - detail: \(error)")
                    }
                }
            }
        }
    }
    
}
    //struct ConfigProfileDetailView_Previews: PreviewProvider {
    //    static var previews: some View {
    //        ConfigProfileDetailView()
    //    }
    //}
