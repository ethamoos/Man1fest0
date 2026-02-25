//  PackageUsageView.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/11/2023.
//

import SwiftUI

struct PackageUsageView: View {
    
    var server: String
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var backgroundTasks: BackgroundTasks
//    // @EnvironmentObject var controller: JamfController
    @State private var searchText = ""
    
    //    ########################################
    //    SUMMARIES
    //    ########################################
    
    @State var totalPackagesNotUsed = 0
    
    //    ########################################
    //    Selections
    //    ########################################
    
    @State var selection = Set<String>()
    @State var selectedKey: [String] = []
    @State var selectedValue: String = ""
    
    @State var fetchedDetailedPolicies: Bool = false
    
    var body: some View {
                
        //    ########################################
        //    PROGRESS BAR
        //    ########################################
        
        if progress.showExtendedProgressView == true {
            
            ProgressView {
                
                HStack {
                    Label("Processing - this may take a while", systemImage: "cup.and.saucer.fill")
                }
                .font(.title)
                .progressViewStyle(.circular)
            }
            .padding()
        }
        
        //    ########################################
        //    PROGRESS BAR - END
        //    ########################################
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header card
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "suitcase.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Package Usage")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Overview of packages assigned to policies and those not used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        VStack(alignment: .trailing) {
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(networkController.allPackages.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        VStack(alignment: .trailing) {
                            Text("Assigned")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(backgroundTasks.assignedPackagesByNameDict.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        VStack(alignment: .trailing) {
                            Text("Unused")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(backgroundTasks.unassignedPackagesArray.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.04)))
                .padding(.bottom, 6)

                // If packages are still downloading show a simple notice
                if networkController.allPoliciesConverted.count != networkController.allPoliciesDetailed.count {
                    if networkController.allPackages.count > 0 {
                        Section(header: Text("All Packages").sectionHeading(style: .pill)) {
                            List {
                                ForEach(searchResults) { package in
                                    HStack {
                                        Image(systemName: "suitcase.fill")
                                        Text(String(describing: package.name ))
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            .listStyle(.inset)
                            .frame(maxHeight: 240)
                            .searchable(text: $searchText)
                        }
                    }
                }

                // Assigned packages
                VStack(alignment: .leading, spacing: 6) {
                    Text("Assigned Packages")
                        .sectionHeading(style: .boxed)

                    List(selection: $selection) {
                        ForEach(backgroundTasks.assignedPackagesByNameDict.keys.sorted(), id: \.self) { package in
                            HStack {
                                Image(systemName: "suitcase.fill")
                                Text(package)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .listStyle(.inset)
                    .frame(minHeight: 120, maxHeight: 260)
                }

                // Unassigned packages
                VStack(alignment: .leading, spacing: 6) {
                    Text("Packages not in use")
                        .sectionHeading(style: .boxed)

                    List(selection: $selection) {
                        ForEach(backgroundTasks.unassignedPackagesArray.sorted(), id: \.self) { package in
                            HStack {
                                Image(systemName: "suitcase.fill")
                                Text(package)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .listStyle(.inset)
                    .frame(minHeight: 120, maxHeight: 260)
                }

                // Actions
                HStack(spacing: 12) {
                    Button(action: {
                        progress.showProgressView = true
                        progress.waitForABit()

                        selectedValue = selection
                            .compactMap { backgroundTasks.allPackagesByNameDict[$0] }
                            .joined(separator: ", ")

                        selectedKey = selection.map{return $0}

                        let selectedValueArray = selectedValue.components(separatedBy: ",")
                        print("selectedValue is: \(selectedValue)")
                        print("selectedKey is: \(selectedKey)")
                        print("selectedValueArray is: \(selectedValueArray)")

                        for eachItem in selectedValueArray {
                            print("Item untrimmed:\(eachItem)")
                            let eachItemTrimmed = eachItem.trimmingCharacters(in: .whitespacesAndNewlines)
                            print("Item trimmed:\(eachItemTrimmed)")

                            networkController.deletePackage(server: server, resourceType: ResourceType.package, itemID: eachItemTrimmed, authToken: networkController.authToken )
                        }

                    }) {
                        Text("Delete Selection")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)

                    Spacer()

                    Button(action: {
                        Task {
                            progress.showExtendedProgress()
                            progress.currentProgress = 0.25

                            backgroundTasks.getPackagesInUse(allPoliciesDetailedArray: networkController.allPoliciesDetailed)
                            backgroundTasks.getPackagesNotInUse(allPoliciesDetailedArray: networkController.allPoliciesDetailed, allPackages: networkController.allPackages)

                            if backgroundTasks.unassignedPackagesArray.count > 0 {
                                progress.currentProgress = 0.5
                            }

                            print("End extended progress")
                            progress.endExtendedProgress()

                        }

                    }) {
                        Text("Analyse Data")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: {
                        networkController.allPoliciesDetailed.removeAll()
                        Task {
                            try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                        }
                    }) {
                        Text("Refresh Policy Data")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.top)

                // Summary card
                Form {
                    Group {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total policies in Jamf:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(networkController.allPoliciesConverted.count)")
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Policy records downloaded:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(networkController.allPoliciesDetailed.count)")
                                        .fontWeight(.bold)
                                }
                            }

                            Divider()

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Packages in Jamf:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(networkController.allPackages.count )")
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Packages in a policy:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(backgroundTasks.assignedPackagesByNameDict.count)")
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Packages not in a policy:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(backgroundTasks.unassignedPackagesArray.count)")
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.02)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.03)))
                .padding(.top)

                if progress.showProgressView == true {
                    ProgressView {
                        Text("Loading")
                            .font(.title)
                            .progressViewStyle(.horizontal)
                    }
                    .padding()
                    Spacer()
                }
            }
            .padding()
        }
        .frame(minHeight: 50)
        .onAppear(){
            
            progress.showProgress()
            progress.waitForABit()
            
            Task {
                try await networkController.getAllPackages(server: server)
                
                try await networkController.getAllPolicies(server: server, authToken: networkController.authToken)
            }

            
            if networkController.fetchedDetailedPolicies == false {
                
                print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
                Task {
                    try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                }
                if networkController.allPoliciesDetailed.count == networkController.policies.count {
                    print("Detailed policies have downloaded - analyse usage")
               
                } else {
                    print("Waiting for detailed policies to download")
                    progress.showExtendedProgress()
                    progress.currentProgress = 0.25
                    if backgroundTasks.unassignedPackagesArray.count > 0 {
                        progress.currentProgress = 0.5
                    }
                    print("End extended progress")
                    progress.endExtendedProgress()
                }

                print("Setting: fetchedDetailedPolicies to true")
                networkController.fetchedDetailedPolicies = true
                
            } else {
                print("fetchedDetailedPolicies has run - ignoring")
            }
        }
    }

    var searchResults: [Package] {
        
        let allPackages = networkController.allPackages
        let allPackagesArray = Array (allPackages)
        
        if searchText.isEmpty {
            // print("Search is empty")
            return networkController.allPackages
        } else {
            print("Search Added")
            return allPackagesArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
            
        }
    }
}


//
//struct PackageUsageViewJson_Previews: PreviewProvider {
//    static var previews: some View {
//        PackageUsageViewJson()
//    }
//}
