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
    @EnvironmentObject var deletionController: DeletionBrain
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
        
        VStack(alignment: .leading) {
            
            if networkController.allPoliciesConverted.count != networkController.allPoliciesDetailed.count {
                
                if networkController.allPackages.count > 0 {
                    
                    //        ########################################
                    //        All packages - show initially
                    //        ########################################
                    
                    Section(header: Text("All Packages").bold().padding(.leading)) {
                        
                        List {
                            
                            ForEach(searchResults, id: \.self) { package in
                                
                                HStack {
                                    Image(systemName: "suitcase.fill")
                                    Text(String(describing: package.name ))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .searchable(text: $searchText)
                    }
                }
            }
            
            
//            if networkController.allPoliciesConverted.count == networkController.allPoliciesDetailed.count {
                
                //        ########################################
                //        Assigned packages
                //        ########################################
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    Section(header: Text("Assigned Packages").bold().padding()) {
                        
                        List(selection: $selection) {
                            ForEach(backgroundTasks.assignedPackagesByNameDict.keys.sorted(), id: \.self) { package in
                                HStack {
                                    Image(systemName: "suitcase.fill")
                                    Text(package)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                //        ########################################
                //        Unassigned packages
                //        ########################################
                
                Section(header: Text("Packages not in use").bold().padding(.leading)) {
                    
                    List(selection: $selection) {
                        ForEach(backgroundTasks.unassignedPackagesArray.sorted(), id: \.self) { package in
                            
                            HStack {
                                Image(systemName: "suitcase.fill")
                                Text(package)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
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

                        deletionController.deletePackage(server: server, resourceType: ResourceType.package, itemID: eachItemTrimmed, authToken: networkController.authToken )
                    }
                    
                }) {
                    Text("Delete Selection")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
                .padding()
//            }
                
            Form {
                
                Group {
                    
//                    if networkController.allPoliciesDetailed.count > 0 {
                        
                        VStack(alignment: .leading, spacing: 5) {
                            
                            Text("Total policies in Jamf:\t\t\t\t\(networkController.allPoliciesConverted.count)")
                                .fontWeight(.bold)
                            
                            Text("Policy records downloaded:\t\t\t\(networkController.allPoliciesDetailed.count)")
                                .fontWeight(.bold)
                            
                            Text("Total Packages in Jamf:\t\t\t\t\(networkController.allPackages.count )")
                                .fontWeight(.bold)
                            
                            Text("Packages in a policy:\t\t\t\t\t\(backgroundTasks.assignedPackagesByNameDict.count)")
                                .fontWeight(.bold)
                            
                            Text("Packages not in a policy :\t\t\t\t\(backgroundTasks.unassignedPackagesArray.count)")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .border(.blue)
//                    }
                }
            }
                
                //        ########################################
                //        Analyse Data
                //        ########################################
            
            HStack {
//                if networkController.allPoliciesConverted.count == networkController.allPoliciesDetailed.count {
                    
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
                    .padding()
//                }
                
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
                .padding()
            }
            
            
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
        .frame(minHeight: 50)
        .padding()

        .onAppear(){
            
            progress.showProgress()
            progress.waitForABit()
            
            Task {
                try await networkController.getAllPackages(server: server)
                
                try await networkController.getAllPolicies(server: server)
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
