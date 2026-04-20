//  PackageUsageView.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/11/2023.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

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
    // Manual override to force-enable Analyse Data (temporary, for debugging / network flakiness)
    @State private var forceEnableAnalyse: Bool = false

    // Computed property: are detailed policies fully downloaded?
    private var detailedPoliciesComplete: Bool {
        let expected = networkController.detailedPoliciesProgress.expected
        let loaded = networkController.detailedPoliciesProgress.loaded
        // If controller flag is set, consider complete
        if networkController.fetchedDetailedPolicies { return true }
        // If we've downloaded at least one detailed policy, allow Analyse (same permissive behavior)
        if loaded > 0 { return true }
        // Exact match
        if expected > 0 && loaded == expected { return true }
        // Allow if only a small number missing (tolerance)
        if expected > 0 && (expected - loaded) <= detailedPoliciesTolerance { return true }
        return false
    }
    
    // Tolerance: allow Analyse to enable when the number of missing detailed policies is <= this threshold
    private var detailedPoliciesTolerance: Int { 20 }
    
    // Helper: show downloaded / expected as string
    private var detailedPoliciesProgressText: String {
        let expected = max(networkController.allPoliciesConverted.count, networkController.policies.count)
        let actual = networkController.allPoliciesDetailed.compactMap { $0 }.count
        if expected > 0 {
            let missing = max(0, expected - actual)
            return "\(actual) / \(expected) (missing: \(missing))"
        } else {
            return "\(actual)"
        }
    }
    
    // Debug visibility for detailed fetch diagnostics (toggleable)
    @State private var showDetailedFetchDebug: Bool = false

    private var detailedFetchDebugView: some View {
        let expected = max(networkController.allPoliciesConverted.count, networkController.policies.count)
        let actual = networkController.allPoliciesDetailed.compactMap { $0 }.count
        let missing = max(0, expected - actual)
        return VStack(alignment: .leading, spacing: 6) {
            HStack { Text("fetchedDetailedPolicies:"); Spacer(); Text(String(describing: networkController.fetchedDetailedPolicies)) }
            HStack { Text("expected:"); Spacer(); Text(String(expected)) }
            HStack { Text("actual (non-nil):"); Spacer(); Text(String(actual)) }
            HStack { Text("missing:"); Spacer(); Text(String(missing)) }
            HStack { Text("retryFailed count:"); Spacer(); Text(String(networkController.retryFailedDetailedPolicyCalls.count)) }
            HStack { Text("detailedPoliciesComplete:"); Spacer(); Text(String(detailedPoliciesComplete)) }
        }
        .font(.caption2)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
    }
    
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

                // Download status
                HStack {
                    if progress.showExtendedProgressView {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        // compute expected/actual/missing locally so we can make the missing count interactive
                        let expected = max(networkController.allPoliciesConverted.count, networkController.policies.count)
                        let actual = networkController.allPoliciesDetailed.compactMap { $0 }.count
                        let missing = max(0, expected - actual)

                        VStack(alignment: .leading) {
                            Text("Downloaded policies:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                if missing > 0 {
                                    // clickable text toggles the debug panel listing failed IDs
                                    Button(action: { showDetailedFetchDebug.toggle() }) {
                                        Text("\(actual) / \(expected) (missing: \(missing))")
                                            .fontWeight(.bold)
                                            .underline()
                                    }
                                    .buttonStyle(.plain)
                                    .help("Click to show failed policy IDs and retry them")
                                } else {
                                    Text("\(actual) / \(expected)")
                                        .fontWeight(.bold)
                                }
                                Spacer()
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.04)))
                        .padding(.bottom, 6)

                        // When the user toggles the debug panel, show failed policy IDs (if any) and a retry action
                        if showDetailedFetchDebug {
                            if networkController.retryFailedDetailedPolicyCalls.count > 0 {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(networkController.retryFailedDetailedPolicyCalls, id: \.self) { policyID in
                                        Text(policyID)
                                            .font(.footnote)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.12)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.04)))
                                .padding(.bottom, 6)
                            } else {
                                Text("No failed policy IDs to show")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 6)
                            }
                        }
                    }
                }
                .padding(.horizontal)
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
                    // Disable the button until all detailed policies have finished downloading
                    .disabled(!(detailedPoliciesComplete || forceEnableAnalyse))

                    // Small control to force-enable Analyse when network fetched is flaky
                    Button(action: { forceEnableAnalyse.toggle() }) {
                        Text(forceEnableAnalyse ? "Analyse forced" : "Force Analyse")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(forceEnableAnalyse ? .green : .primary)
                    .help("Temporarily force-enable Analyse Data if downloads are mostly complete")

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
                                    // Make the label and count red & bold until detailed policies are finished
                                    Text("Policy records downloaded:")
                                        .font(.caption)
                                        .foregroundColor(detailedPoliciesComplete ? .secondary : .red)
                                        .fontWeight(detailedPoliciesComplete ? .regular : .bold)
                                    Text("\(networkController.allPoliciesDetailed.count)")
                                        .fontWeight(.bold)
                                        .foregroundColor(detailedPoliciesComplete ? .primary : .red)
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
                
                try await networkController.getAllPackages()
                
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
