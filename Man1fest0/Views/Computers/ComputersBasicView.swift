

import SwiftUI

struct ComputersBasicView: View {
    
    //    var selectedResourceType = ResourceType.computerBasic
    
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
    
    //  ########################################################################################
    //  Selections
    //  ########################################################################################
    
    @State private var selectionCompGroup: ComputerGroup? = nil
    
    @State var selection = Set<ComputerBasicRecord>()
    //    @State var selection: ComputerBasicRecord
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.allComputersBasic.computers.count > 0 {
                
                NavigationView {
#if os(macOS)
                    List(networkController.allComputersBasic.computers, id: \.self, selection: $selection) { computer in
                        HStack {
                            Image(systemName: "apple.logo")
                            Text(computer.name).font(.system(size: 12.0))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    
                    
                    //                    List(searchResults, id: \.self, selection: $selection) { computer in
                    //
                    //                            HStack {
                    //                                Image(systemName: "desktopcomputer")
                    //                                Text(computer.name ).font(.system(size: 12.0)).foregroundColor(.blue)
                    //                            }
                    //                            .foregroundColor(.blue)
                    //                    }
                    //
                    
#else
                    List(networkController.allComputersBasic.computers, id: \.self) { computer in
                        HStack {
                            Image(systemName: "apple.logo")
                            Text(computer.name).font(.system(size: 12.0))
                        }
                        .foregroundColor(.blue)
                    }
#endif
                    Text("\(networkController.computers.count) total computers")
                }
                
//                .toolbar {
//
//                    Button(action: {
//                        networkController.connect(server: server,resourceType: ResourceType.computer, authToken: networkController.authToken)
//                        progress.showProgress()
//                        progress.waitForABit()
//                        print("Refresh")
//                    }) {
//                        HStack(spacing: 10) {
//                            Image(systemName: "arrow.clockwise")
//                            Text("Refresh")
//                        }
//                    }
//                }
                
                Text("\(networkController.computers.count) total computers")
                
                    .navigationViewStyle(DefaultNavigationViewStyle())
                
                //  ##########################################################################
                //  processUpdateAddComputersToGroup
                //  ##########################################################################
                
                Button(action: {
                    
                    progress.showProgress()
                    progress.waitForABit()
                    
                    // Call the real update group function and show progress
                    guard let compGroup = selectionCompGroup else {
                        // No group selected - nothing to do
                        return
                    }
                    
                    // Request group members XML then call addMultipleComputersToGroup when the XML is available.
                    Task {
                        xmlController.getGroupMembersXML(server: server, groupId: compGroup.id, authToken: networkController.authToken)
                        
                        // wait for the xmlController to populate computerGroupMembersXML (timeout after ~3s)
                        var attempts = 0
                        while xmlController.computerGroupMembersXML.isEmpty && attempts < 15 {
                            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                            attempts += 1
                        }
                        
                        if xmlController.computerGroupMembersXML.isEmpty {
                            print("Warning: did not receive group members XML in time; proceeding with whatever XML is available")
                        } else {
                            print("Got groupMembers XML")
                        }
                        
//                        xmlController.addMultipleComputersToGroup(xmlContent: xmlController.computerGroupMembersXML,
//                                                                  computers: selection,
//                                                                  authToken: networkController.authToken,
//                                                                  groupId: String(compGroup.id),
//                                                                  resourceType: ResourceType.computerGroup,
//                                                                  server: server)
                    }
                    
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                        Text("Add Selection To Group")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                HStack(spacing: 10) {
                    TextField("Filter", text: $computerGroupFilter)
                    Picker(selection: $selectionCompGroup, label: Text("Group:").bold()) {
                        ForEach(networkController.allComputerGroups.filter({ computerGroupFilter.isEmpty ? true : $0.name.contains(computerGroupFilter) }), id: \.self) { group in
                            Text(group.name)
                                .tag(group as ComputerGroup?)
                        }
                    }
                    .onAppear {
                        if let first = networkController.allComputerGroups.first {
                            selectionCompGroup = first
                        } else {
                            selectionCompGroup = nil
                        }
                    }
                }
                
            }
//                .padding()
            
            
            
            
            
            
        }
        
        //        } else {
        //
        //            ProgressView {
        //                Text("Loading data")
        //                    .font(.title)
        //                    .progressViewStyle(.horizontal)
        //            }
        //            .padding()
        //            Spacer()
        //        }
        //    }
        
        //        .frame(minWidth: 200, minHeight: 100, alignment: .leading)
        
        //        .onAppear {
        //
        //            networkController.refreshComputers()
        //
        //            //            if networkController.computers.count < 0 {
        //            //                print("Fetching computers")
        //            //                networkController.connect(server: server,resourceType: ResourceType.computer, authToken: networkController.authToken)
        //            //            }
        //            //            if networkController.computers.count < 0 {
        //            //                print("Fetching basic computers")
        //            //                //                networkController.allComputersBasic.computers
        //            //            }
        //        }
        //}
        
    }
    
    func handleConnect(resourceType: ResourceType) async {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
    }
    
    
    var searchResults: [ComputerBasicRecord] {
        
        let allComputers = networkController.allComputersBasic.computers
        let allComputersArray = Array (allComputers)
        
        if searchText.isEmpty {
            return networkController.allComputersBasic.computers.sorted { $0.name < $1.name }
        } else {
            print("Search Added")
            return allComputersArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
    
}


//struct TestView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestView()
//    }
//}
