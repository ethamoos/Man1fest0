//
//  PolicyActionsDetailTableView.swift
//  Man1fest0
//
//  Created by Amos Deane on 30/08/2024.
//

import SwiftUI

struct PolicyActionsDetailTableView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String
    
    //  ########################################################################################
    //  BOOLS
    //  ########################################################################################
    
    @State var status: Bool = true
    @State private var showingWarning = false
    @State private var showingWarningDelete = false
    @State var enableDisable: Bool = true
    
    //  ########################################################################################
    //    POLICY SELECTION
    //  ########################################################################################
    
    @State private var selectedPolicyIDs = Set<General.ID>()
    @State private var selectedPolicyjamfIDs = Set<General>()
    @State private var selectedIDs = []
    // Toggle to show failed-policy debug panel (click missing count to toggle)
    @State private var showDetailedFetchDebug: Bool = false
    // policiesSelection mirrors selectedPolicyIDs (used by PoliciesActionScopeTab)
    @State private var policiesSelection = Set<Policy>()
    // Additional state required for scope controls (moved from PoliciesActionView)
    @State var computerGroupFilter: String = ""
    @State private var allComputersStaticEnable = false
    @State private var allComputersSmartEnable = false
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    @State var ldapServerSelection: LDAPServer? = nil
    @State var ldapSearch: String = ""

    @State var searchText = ""
    // Ephemeral banner to indicate basic policies have arrived
    @State private var showBasicPoliciesBanner: Bool = false
    @State private var basicPoliciesBannerText: String = ""
    // explicit tab selection for the detail TabView
    @State private var selectedDetailTab: Int = 0

    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    // Use an optional ComputerGroup binding for pickers
    @State var computerGroupSelectionOptional: ComputerGroup? = nil
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = Icon(id: 0, url: "", name: "")
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    @State var iconFilter: String = ""
    
    @State private var isAscending = true
    
    @State private var sortOrder: [KeyPathComparator<General>] = [
        KeyPathComparator(\General.nameForSort, order: .forward),
        KeyPathComparator(\General.categoryNameForSort, order: .forward),
        KeyPathComparator(\General.enabledInt, order: .forward), // Use Int for sorting
        KeyPathComparator(\General.jamfIdForSort, order: .forward),
        KeyPathComparator(\General.triggerOtherForSort, order: .forward)
    ]
    // Move this computed mapping out of the body to ease compiler type checking
    var selectedPoliciesInt: [Int?] {
        networkController.allPoliciesDetailedGeneral.filter { selectedPolicyIDs.contains($0.id) }.map { $0.jamfId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ephemeral banner area
            if showBasicPoliciesBanner {
                HStack {
                    Text(basicPoliciesBannerText)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: showBasicPoliciesBanner)
            }
            // Header area
            // Compute expected/actual/missing for detailed policies from single source of truth
            let expected = networkController.detailedPoliciesProgress.expected
            let actual = networkController.detailedPoliciesProgress.loaded
            let missing = max(0, expected - actual)
            LazyVGrid(columns: layout.fiveColumns, spacing: 5) {
                VStack(alignment: .leading, spacing: 5) {
                    
                    Text("Total Policies:\t\(networkController.allPoliciesConverted.count)")
                        .fontWeight(.bold)
                    // If there are missing items, make the label clickable to toggle the debug panel
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                
                VStack(alignment: .leading) {
                    Text("Downloaded policies:")
                        .font(.caption)
                        .foregroundColor(.secondary)
//                    Text("Total Policies Downloaded:\t\(networkController.allPoliciesDetailed.count)")

                    
                    HStack {
                        if missing > 0 {
                            // clickable text toggles the debug panel listing failed IDs
                            Button(action: { showDetailedFetchDebug.toggle() }) {
                                Text("\(actual) / \(expected) (missing: \(missing))")
//                                    .fontWeight(.bold)
//                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .help("Click to show failed policy IDs and retry them")
                        } else {
                            Text("\(actual) / \(expected)")
//                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.04)))
                .padding(.bottom, 6)
            }
            
            // Optional debug panel: when toggled, show failed policy IDs and a Retry button
            if showDetailedFetchDebug {
                VStack(alignment: .leading, spacing: 6) {
                    if networkController.detailedPoliciesProgress.failedIDs.isEmpty {
                        Text("No failed detailed policy IDs to show")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(networkController.detailedPoliciesProgress.failedIDs, id: \.self) { id in
                            Text(id)
                                .font(.caption2)
                                .foregroundColor(.red)
                        }

                        HStack {
                            Spacer()
                            Button(action: {
                                Task {
                                    progress.showExtendedProgress()
                                    // Build list of Policy objects that match failed IDs
                                    let failedIDs = networkController.detailedPoliciesProgress.failedIDs
                                    let policiesToRetry = networkController.allPoliciesConverted.filter { p in
                                        guard let pid = p.jamfId else { return false }
                                        return failedIDs.contains(String(pid))
                                    }
                                    if !policiesToRetry.isEmpty {
                                        do {
                                            try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: policiesToRetry)
                                        } catch {
                                            print("Retry failed policies error: \(error)")
                                        }
                                    }
                                    progress.endExtendedProgress()
                                }
                            }) {
                                Text("Retry Failed")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.12)))
                .padding(.bottom, 6)
            }

            // Table fixed at the top
            policyTableView()
                .frame(minHeight: 320)
                .layoutPriority(1)
                .onAppear {
                    convertToallPoliciesDetailedGeneral()
                }
                .searchable(text: $searchText)
                .toolbar { tableToolbar }
                .onChange(of: sortOrder) { newOrder in
                    networkController.allPoliciesDetailedGeneral.sort(using: newOrder)
                }
                .onChange(of: selectedPolicyIDs) { newSelection in
                    if newSelection.isEmpty {
                        policiesSelection.removeAll()
                    } else {
                        // Map selectedPolicyIDs to jamfIds and match policies by jamfId
                        let selectedJamfIds = Set(selectedPoliciesInt.compactMap { $0 })
                        let matched = networkController.policies.filter { p in
                            if let jamf = p.jamfId { return selectedJamfIds.contains(jamf) }
                            return false
                        }
                        policiesSelection = Set(matched)
                        selectedDetailTab = 2
                    }
                }

            Divider()

            // Make only the detail area scrollable so the table stays visible on top
            ScrollView {
                detailArea()
                    .padding(.top, 6)
            }

            if progress.showProgressView {
                ProgressView { Text("Loading").font(.title).progressViewStyle(.horizontal) }
                    .padding()
            }
        }
        .padding()
        .onAppear {
            print("PolicyActionsDetailTableView - getting primary data")
            fetchData()
        }
        // When detailed policies are updated, rebuild the simplified general list so the table fills
        .onReceive(networkController.$allPoliciesDetailed) { _ in
            convertToallPoliciesDetailedGeneral()
        }
        // Show a brief banner when basic policies arrive so the user sees activity
        .onReceive(networkController.$allPoliciesConverted) { newList in
            let count = newList.count
            guard count > 0 else { return }
            basicPoliciesBannerText = "Basic policies downloaded: \(count)"
            withAnimation { showBasicPoliciesBanner = true }
            // Hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { showBasicPoliciesBanner = false }
            }
        }
        // Also log when the simplified general array changes so we can diagnose why the Table may be empty
        .onReceive(networkController.$allPoliciesDetailedGeneral) { newList in
            print("allPoliciesDetailedGeneral changed: count=\(newList.count)")
        }
    }

    // toolbar contents separated for readability
    private var tableToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button(action: {
                print("convertToallPoliciesDetailedGeneral")
                progress.showProgress()
                progress.waitForABit()
                Task { await refreshDetailedPolicySelections(selectedPolicies: selectedPoliciesInt, authToken: networkController.authToken, server: server) }
            }) { Image(systemName: "arrow.clockwise"); Text("Refresh") }
            .buttonStyle(.borderedProminent)

            Button(action: {
                progress.showProgress(); progress.waitForABit(); print("Clearing allPoliciesDetailed")
                networkController.allPoliciesDetailed.removeAll()
                Task { try? await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted) }
                convertToallPoliciesDetailedGeneral()
            }) { Image(systemName: "arrow.clockwise"); Text("Reset") }
            .buttonStyle(.bordered)

            Button(action: {
                let selectedRows = networkController.allPoliciesDetailedGeneral.filter { selectedPolicyIDs.contains($0.id) }
                let rowsString = selectedRows.map { policy in
                    let name = String(policy.name ?? "")
                    let category = policy.category?.name ?? ""
                    let enabled = String(policy.enabled ?? true)
                    let jamfId = String(policy.jamfId ?? 0)
                    let triggerOther = policy.triggerOther ?? ""
                    return [name, category, enabled, jamfId, triggerOther].joined(separator: "\t")
                }.joined(separator: "\n")
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents(); pasteboard.setString(rowsString, forType: .string)
            }) { Image(systemName: "doc.on.doc"); Text("Copy Selected") }
            .buttonStyle(.bordered)
            .disabled(selectedPolicyIDs.isEmpty)
        }
    }

    @ViewBuilder
    private func detailArea() -> some View {
        #if os(macOS)
        VStack(alignment: .leading) {
            HStack {
                Picker(selection: $selectedDetailTab, label: Text("Details")) {
                    Text("General").tag(0)
                    Text("Clear Items").tag(1)
                    Text("Scope").tag(2)
                    Text("Export").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 6)
                Spacer()
            }

            Group {
                switch selectedDetailTab {
                case 0:
                    PolicyDetailGeneralTabView(server: server, selectedPoliciesInt: selectedPoliciesInt, policiesSelection: $policiesSelection)
                case 1:
                    PolicyDetailClearItemsTabView(server: server, selectedPoliciesInt: selectedPoliciesInt)
                case 2:
                    PoliciesActionScopeTab(
                        policiesSelection: $policiesSelection,
                        server: server,
                        computerGroupSelection: $computerGroupSelectionOptional,
                        computerGroupFilter: $computerGroupFilter,
                        allComputersStaticEnable: $allComputersStaticEnable,
                        allComputersSmartEnable: $allComputersSmartEnable,
                        ldapSearchCustomGroupSelection: $ldapSearchCustomGroupSelection,
                        ldapServerSelection: $ldapServerSelection,
                        ldapSearch: $ldapSearch,
                        onUpdateScopeCompGroupSet: { group, _, _ in Task { await xmlController.updateScopeCompGroupSetAsync(groupSelection: group, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policiesSelection: selectedPoliciesInt) } },
                        onUpdatePolicyScopeLimitationsAuto: { group, policyID in Task { await xmlController.updatePolicyScopeLimitationsAuto(groupSelection: group, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: policyID) } },
                        onClearLimitations: { policyID in Task { do { let pidInt = Int(policyID) ?? 0; let policyAsXML = try await xmlController.getPolicyAsXMLaSync(server: server, policyID: pidInt, authToken: networkController.authToken); xmlController.updatePolicyScopeLimitAutoRemove(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: policyID, currentPolicyAsXML: policyAsXML) } catch { print("Fetching detailed policy as xml failed: \(error)") } } },
                        onClearExclusions: { for eachItem in selectedPoliciesInt { let pid = (eachItem ?? 0); xmlController.removeExclusions(server: server, policyID: String(describing: pid), authToken: networkController.authToken) } }
                    )
                case 3:
                    PolicyDetailExportTabView(server: server, selectedPoliciesInt: selectedPoliciesInt)
                default:
                    PolicyDetailGeneralTabView(server: server, selectedPoliciesInt: selectedPoliciesInt, policiesSelection: $policiesSelection)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 340, maxHeight: 800)
            .padding()
        }
        .background(Color.blue.opacity(0.0))
        #endif
    }

    @ViewBuilder
    private func policyTableView() -> some View {
        // If there are no search results yet, show a helpful placeholder so the user can tell data is loading
        if searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("No policies to display yet")
                        .font(.headline)
                    Spacer()
                }
                Text("Policies are being fetched. If this message persists, try Refresh or check connection settings.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            Table(searchResults, selection: $selectedPolicyIDs, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.nameForSort) { policy in
                    let name = policy.name ?? ""
                    Text(name).textSelection(.enabled)
                }
                TableColumn("Category", value: \.categoryNameForSort) { policy in
                    let category = policy.category?.name ?? ""
                    Text(category).textSelection(.enabled)
                }
                TableColumn("Enabled", value: \.enabledInt) { policy in
                    let enabledText = policy.enabled == true ? "true" : "false"
                    Text(enabledText)
                }
                TableColumn("ID", value: \.jamfIdForSort) { policy in
                    let idText = String(policy.jamfId ?? 0)
                    Text(idText).textSelection(.enabled)
                }
                TableColumn("Trigger", value: \.triggerOtherForSort) { policy in
                    let triggerText = policy.triggerOther ?? ""
                    Text(triggerText).textSelection(.enabled)
                }
            }
        }
     }
 
    //  ################################################################################
    //  END
    //  ################################################################################
    
    func convertToallPoliciesDetailedGeneral() {
        
        print("Reset allPoliciesDetailedGeneral and re-add")
 
         // Always update published/UI-state on the main thread
         DispatchQueue.main.async {
             networkController.allPoliciesDetailedGeneral.removeAll()
 
             if networkController.allPoliciesDetailed.isEmpty != true {
                 for eachPolicy in networkController.allPoliciesDetailed {
                     if let eachPolicyGeneral = eachPolicy?.general {
                         networkController.allPoliciesDetailedGeneral.insert(eachPolicyGeneral, at: 0)
                     }
                 }
             }
            print("convertToallPoliciesDetailedGeneral completed - new count=\(networkController.allPoliciesDetailedGeneral.count) | allPoliciesDetailed.count=\(networkController.allPoliciesDetailed.count)")
         }
     }
    
    func refreshDetailedPolicySelections(selectedPolicies: [Int?], authToken: String, server: String) async {
        
        if selectedPolicies.isEmpty {
            print("no selection")
            convertToallPoliciesDetailedGeneral()
        } else {
            print("refreshing detailed policy selections")
            for eachPolicy in selectedPolicies {
                Task {
                    try await networkController.getDetailedPolicy(server: server, authToken: authToken, policyID: String(describing: eachPolicy))
                }
            }
            convertToallPoliciesDetailedGeneral()
        }
    }
    
    
    //  #################################################################################
    //  Master Fetch function
    //  #################################################################################
    
    
    func fetchData() {
        print("Running fetchData")

        Task {
            // Ensure we are connected and have a valid auth token
            print("Ensuring networkController is connected and has a token")
            await networkController.connect()

            let effectiveServer = server.isEmpty ? networkController.server : server
            print("Effective server: \(effectiveServer)")
            print("Controller server: \(networkController.server)")
            print("Controller username: \(networkController.username)")
            print("Controller authToken present: \( !networkController.authToken.isEmpty )")

            guard !effectiveServer.isEmpty else {
                print("No server configured. Skipping fetch.")
                return
            }

            // 1) Ensure we have basic policies (use the central helper which will try JSON API then fallback)
            print("Ensuring policies are loaded via ensurePoliciesLoaded")
            await networkController.ensurePoliciesLoaded(server: effectiveServer, authToken: networkController.authToken)
            print("After ensurePoliciesLoaded: allPoliciesConverted.count=\(networkController.allPoliciesConverted.count), policies.count=\(networkController.policies.count)")

            // 2) Fetch detailed policies (wait for basic to complete first)
            if networkController.fetchedDetailedPolicies == false {
                print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
                if networkController.allPoliciesDetailed.count < networkController.allPoliciesConverted.count {
                    print("fetching detailed policies — will await completion")
                    await MainActor.run { progress.showProgress() }
                    do {
                        try await networkController.getAllPoliciesDetailed(server: effectiveServer, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                        await MainActor.run {
                            convertToallPoliciesDetailedGeneral()
                            progress.waitForABit()
                            networkController.fetchedDetailedPolicies = true
                        }
                        print("Completed getAllPoliciesDetailed: count=\(networkController.allPoliciesDetailed.count)")
                    } catch {
                        print("getAllPoliciesDetailed failed: \(error)")
                        await MainActor.run { progress.endProgress(); networkController.fetchedDetailedPolicies = false }
                    }
                } else {
                    print("Download complete")
                }
            } else {
                print("fetchedDetailedPolicies has run")
            }

            // 3) Other data fetches
            if networkController.categories.isEmpty {
                print("No category data - fetching")
                Task {
                try await networkController.getAllCategories()
            }
            } else {
                print("category data is available")
            }

            if networkController.allIconsDetailed.count <= 1 {
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                networkController.getAllIconsDetailed(server: effectiveServer, authToken: networkController.authToken, loopTotal: 1000)
            } else {
                print("getAllIconsDetailed has already run")
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            }

            if scopingController.allLdapServers.count <= 1 {
                print("getLdapServers is:\(scopingController.allLdapServers.count) - running")
                Task {
                    try await scopingController.getLdapServers(server: effectiveServer, authToken: networkController.authToken)
                }
            } else {
                print("getLdapServers has already run")
                print("getLdapServers is:\(scopingController.allLdapServers.count) - running")
            }

            if networkController.packages.isEmpty {
                print("No package data - fetching")
                
                Task { try await networkController.getAllPackages() }
                
            } else {
                print("package data is available")
            }

            if networkController.allComputerGroups.isEmpty {
                print("No groups data - fetching")
                Task {
                    try await networkController.getAllGroups(server: effectiveServer, authToken: networkController.authToken)
                }
            } else {
                print("groups data is available")
            }
        }
     }
    
    
    var searchResults: [General] {
        let filtered: [General]
        if searchText.isEmpty {
            filtered = networkController.allPoliciesDetailedGeneral
        } else {
            filtered = networkController.allPoliciesDetailedGeneral.filter { $0.name?.lowercased().contains(searchText.lowercased()) ?? false }
        }
        return filtered
    }
}


//struct PolicyActionsDetailTableView_Previews: PreviewProvider {
//    static var previews: some View {
//        PolicyActionsDetailTableView(server: "")
//            .environmentObject (NetBrain())
//            .environmentObject (Progress())
//            .environmentObject (Layout())
//            .environmentObject (ScopingBrain())
//    }
//}
