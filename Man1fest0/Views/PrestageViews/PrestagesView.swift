//
//  PrestagesView.swift
//  Man1fest0
//
//  Created by Amos Deane on 29/01/2024.
//
//
import SwiftUI
//


let columns = [
    //    GridItem(.fixed(400)),
    
    GridItem(.flexible()),
    GridItem(.flexible())
]


//    #################################################################################
//      All Prestages
//    #################################################################################


struct PrestagesView: View {
    
    @EnvironmentObject var prestageController: PrestageBrain
    @EnvironmentObject var networkController: NetBrain
    @State private var searchText = ""
    
    @State var server: String
    
    @State var showAssignedDevices: Bool = false
    
    @State var allPrestages: [PreStage]
    @State var selectedPrestage: PreStage = PreStage(keepExistingSiteMembership: (0 != 0), enrollmentSiteId: "", id: "", displayName: "")
    
    var body: some View {
        
        VStack(alignment: .leading) {
            // Header: Title, subtitle and quick actions
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prestages").font(.title).fontWeight(.semibold)
                    Text("Manage device prestages and assigned devices").font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            try? await prestageController.getAllPrestages(server: server, authToken: networkController.authToken)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Toggle(isOn: $showAssignedDevices) {
                        Text("Show assigned devices")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }
            .padding([.top, .horizontal])

            // Main content
            if prestageController.allPsComplete == true && prestageController.allPrestages.count > 0 {
                NavigationView {
                    VStack(alignment: .leading) {
#if os(macOS)
                        // Card-like container for the list
                        VStack(spacing: 0) {
                            List(searchResults, id: \.self, selection: $selectedPrestage) { prestage in
                                NavigationLink(destination: PrestagesDetailView(prestage: prestage)) {
                                    HStack() {
                                        HStack {
                                            Image(systemName: "smallcircle.filled.circle")
                                            Text("\(prestage.displayName) ID:\(prestage.id)")
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal)
                                    .foregroundColor(.blue)
                                    .frame(minWidth: 450,alignment: .leading)
#if os(macOS)
                                    .navigationTitle("List all Prestages")
#endif
                                }
                            }
                            .listStyle(.inset)
                            .searchable(text: $searchText)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))
                        .frame(minWidth: 400, minHeight: 200, alignment: .leading)
#else
                        VStack(spacing: 0) {
                            List(searchResults, id: \.self) { prestage in
                                NavigationLink(destination: PrestagesDetailView(prestage: prestage)) {
                                    HStack() {
                                        Image(systemName: "smallcircle.filled.circle")
                                        Text("\(prestage.displayName) ID:\(prestage.id)")
                                    }
                                    .padding(.vertical, 6)
                                    .foregroundColor(.blue)
                                }
                            }
                            .listStyle(.insetGrouped)
                            .searchable(text: $searchText)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)).shadow(radius: 1))
                        .frame(minWidth: 400, minHeight: 200, alignment: .leading)
#endif
                    }

                    if showAssignedDevices == true {
                        if let prestageMembers = prestageController.selectedPrestageScope {
                            if prestageMembers == prestageController.selectedPrestageScope {
                                NavigationView {
                                    List {
                                        ForEach(prestageMembers.assignments, id: \.self) { prestageAssignment in
                                            NavigationLink(destination: PrestageDetailView2(prestageAssignment: prestageAssignment)) {
                                                HStack {
                                                    Image(systemName: "desktopcomputer")
                                                    Text(prestageAssignment.serialNumber)
                                                }
                                            }
                                        }
                                    }
                                    .foregroundColor(.blue)
                                    .frame(minWidth: 400, minHeight: 100, alignment: .leading)
                                    .padding()
                                }
                            } else {
                                ProgressView {
                                    Text("Loading")
                                        .font(.title)
                                }
                                .padding()
                            }
                        }
                    }
                }
            } else {
                if prestageController.allPsComplete == false {
                    ProgressView {
                        Text("Loading")
                            .font(.title)
                            .padding()
                    }
                } else {
                    Text("No Prestages Found")
                        .padding()
                }
            }
        }
        .padding()
        .onAppear {
            print("Hide prestage memebers")
            showAssignedDevices = false
            showPrestage(prestageID: selectedPrestage.id)
            Task {
                print("Running: getAllDevicesPrestageScope")
                try await prestageController.getAllDevicesPrestageScope(server: server, prestageID: selectedPrestage.id, authToken: networkController.authToken)

                print("Running: getAllPrestages")
                try await prestageController.getAllPrestages(server: server, authToken: networkController.authToken)

                showPrestage(prestageID: selectedPrestage.id)
            }
        }
    }
    
    
    func showPrestage(prestageID: String) {
        prestageController.separationLine()
        print("Running: showPrestage")
        Task {
            try await prestageController.getPrestageCurrentScope(jamfURL: prestageController.server, prestageID: prestageID, authToken: networkController.authToken)
        }
    }
    
    
    var searchResults: [PreStage] {
        if searchText.isEmpty {
            // print("Search is empty")
            return prestageController.allPrestages
        } else {
            print("Search Added")
            return prestageController.allPrestages.filter { $0.displayName.contains(searchText) }
        }
    }
}

