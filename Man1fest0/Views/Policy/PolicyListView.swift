//
//  PolicyListView.swift
//  Man1fest0
//
//  (Updated to add scoped text search + selected-field empty toggle)
//

import SwiftUI

struct PolicyListView: View {
    
    var server: String
    
    
    //  ########################################################################################
    //    EnvironmentObject
    //  ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var xmlController: XmlBrain
    
    
    @State private var searchString: String = ""
    // New: replace the previous simple searchField/searchForEmptyField with explicit controls:
    private enum TextSearchScope: String, CaseIterable {
        case title
        case all
        case selectedField
        var displayName: String {
            switch self {
            case .title: return "Title"
            case .all: return "All Fields"
            case .selectedField: return "Selected Field"
            }
        }
    }
    @State private var textSearchScope: TextSearchScope = .title
    @State private var selectedFieldForFilter: SearchField = .generalName
    @State private var selectedFieldIsEmpty: Bool = false
    
    // Match-mode and case sensitivity
    enum MatchMode: String, CaseIterable {
        case contains
        case startsWith
        var displayName: String {
            switch self {
            case .contains: return "Contains"
            case .startsWith: return "Starts With"
            }
        }
    }
    @State private var matchMode: MatchMode = .contains
    @State private var caseSensitive: Bool = false
    
    @State var policiesMatchingItems: [Int] = []
    @State var policiesMissingItems: [Int] = []
    @State var policyName = ""
    @State var policyID: Int = 0
    @State private var selectedResourceType = ResourceType.policyDetail
    
    
    @State var newSelfServiceName = ""
    
    //  ########################################################################################
    //    SELECTIONS
    //  ########################################################################################
    
    @State var selection = Set<PolicyDetailed>()
    @State var selectionMatching = ""
    @State var selectionMissing = ""
    @State var iconFilter = ""
    @State var selectedIcon: Icon? = Icon(id: 0, url: "", name: "")
    @State var selectedIconString = ""
    
    // Identifiable wrapper so ForEach can use the pairs directly as data
    private struct MatchedPolicyPair: Identifiable {
        let policy: PolicyDetailed
        let isHighlighted: Bool
        var id: UUID { policy.id }
    }
    
    // Cached matched pairs so matching logic runs once per update
    @State private var matchedPolicyPairsState: [MatchedPolicyPair] = []
    
    // Compute matched policies (policy + isHighlighted)
    private func computeMatchedPairs() -> [MatchedPolicyPair] {
        let detailed = networkController.allPoliciesDetailed
        print("computeMatchedPairs: allPoliciesDetailed count=\(detailed.count)")
        let nonNil = detailed.compactMap { $0 }
        print("computeMatchedPairs: non-nil detailed count=\(nonNil.count); allPoliciesConverted count=\(networkController.allPoliciesConverted.count)")
        let pairs = nonNil.map { policy in
            let isHighlighted = isPolicyMatch(policy)
            return MatchedPolicyPair(policy: policy, isHighlighted: isHighlighted)
        }
        return pairs
            // Previously we filtered out non-highlights here which hid all items when filters matched none.
            // Return all pairs so the UI can display every policy and use `isHighlighted` only for styling.
    }

    // Helper to update matching IDs (and sync to NetBrain if desired)
    private func updateMatchingIDs() {
        let pairs = computeMatchedPairs()
        print("updateMatchingIDs: computed pairs=\(pairs.count)")
        // update cached pairs used by the view
        matchedPolicyPairsState = pairs
        // update ids to only include highlighted (matching) policies
        let ids = pairs.filter { $0.isHighlighted }.compactMap { $0.policy.general?.jamfId }
        policiesMatchingItems = ids
        networkController.policiesMatchingItems = ids
    }
    
    // Computed displayed pairs depending on active filter
    private var displayedPairs: [MatchedPolicyPair] {
        let trimmedSearch = searchString.trimmingCharacters(in: .whitespacesAndNewlines)
        let activeFilter = !trimmedSearch.isEmpty || selectedFieldIsEmpty || matchMode != .contains || caseSensitive
        return activeFilter ? matchedPolicyPairsState.filter { $0.isHighlighted } : matchedPolicyPairsState
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Search...", text: $searchString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 300)
                    
                    // Text search scope segmented control
                    Picker("Search", selection: $textSearchScope) {
                        ForEach(TextSearchScope.allCases, id: \.self) { scope in
                            Text(scope.displayName)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 300)
                    
                    // Selected-field picker (used when scope is .selectedField or to choose which field to check for emptiness)
                    Picker("Field", selection: $selectedFieldForFilter) {
                        ForEach(SearchField.allCases.filter { $0 != .all }, id: \.self) { field in
                            Text(field.displayName)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                }
                
                HStack {
                    // Match mode segmented control (Contains / Starts With)
                    Picker("Match Mode", selection: $matchMode) {
                        ForEach(MatchMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 240)
                    
                    // Case sensitivity toggle
                    Toggle(isOn: $caseSensitive) {
                        Text("Case Sensitive")
                    }
                    .toggleStyle(SwitchToggleStyle())
                    
                    // Toggle to check selected field is empty. Can be combined with text search scope.
                    Toggle(isOn: $selectedFieldIsEmpty) {
                        Text("Selected Field is Empty")
                    }
                    .toggleStyle(SwitchToggleStyle())
                    
                    Spacer()
                }
            }
            .padding()
            
            // Use ScrollView + LazyVStack so rows can expand naturally (List enforces row sizing on macOS which can clip expanded content).
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if matchedPolicyPairsState.isEmpty {
                        // If there are basic policies available but no detailed policies, show a basic list and allow fetching details
                        if !networkController.allPoliciesConverted.isEmpty && networkController.allPoliciesDetailed.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Detailed policies not loaded yet — showing basic policy list")
                                    .foregroundColor(.secondary)
                                Text("Total basic policies: \(networkController.allPoliciesConverted.count)")
                                    .foregroundColor(.secondary)

                                ForEach(networkController.allPoliciesConverted, id: \.jamfId) { p in
                                    HStack {
                                        Text(p.name)
                                            .font(.body)
                                        Spacer()
                                        Text("id: \(p.jamfId ?? 0)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal)
                                }

                                HStack {
                                    Button("Fetch detailed policies") {
                                        progress.showProgress()
                                        Task {
                                            do {
                                                try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                                                networkController.fetchedDetailedPolicies = true
                                                updateMatchingIDs()
                                            } catch {
                                                print("Error fetching detailed policies: \(error)")
                                            }
                                            progress.waitForABit()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)

                                    Spacer()
                                }
                                .padding(.top)
                            }
                            .padding()
                        } else {
                            // helpful placeholder so user knows why nothing is showing
                            VStack(alignment: .leading) {
                                Text("No detailed policies loaded")
                                    .foregroundColor(.secondary)
                                Text("allPoliciesDetailed.count = \(networkController.allPoliciesDetailed.count)")
                                    .foregroundColor(.secondary)
                                Text("allPoliciesConverted.count = \(networkController.allPoliciesConverted.count)")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    // Show only filtered (matching) policies and use the model's Identifiable id
                    ForEach(displayedPairs) { pair in
                        // Make the row itself tappable for expansion by PolicyRowView.
                        // Provide a small trailing NavigationLink button for navigation so row taps are not swallowed.
                        HStack(spacing: 8) {
                            PolicyRowView(policy: pair.policy)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(pair.isHighlighted ? Color.white.opacity(0.12) : Color.clear)
                                .cornerRadius(6)
                                .padding(.leading)
                                .contentShape(Rectangle())

                            NavigationLink(destination: PolicyDetailView(server: server, policy: {
                                var basicPolicy = Policy(name: pair.policy.general?.name ?? "")
                                basicPolicy.jamfId = pair.policy.general?.jamfId
                                return basicPolicy
                            }(), policyID: pair.policy.general?.jamfId ?? 0)) {
                                Image(systemName: "arrow.right.circle")
                                    .imageScale(.large)
                                    .foregroundColor(.secondary)
                                    .padding(.trailing)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                     }
                }
                .padding(.vertical)
            }
            
            
            
            // ################################################################################
            //                       Print Matching IDs
            // ################################################################################
            
            
            // Button to run an operation on all matching items (prints their jamf IDs)
//            Button("Print Matching IDs") {
//                // Recompute matches to ensure we have the latest set
//                updateMatchingIDs()
//                // Print the IDs (and paired names for convenience)
//                let ids = policiesMatchingItems
//                let names = matchedPolicyPairsState.map { $0.policy.general?.name ?? "(no name)" }
//                print("Matching policy jamf IDs: \(ids)")
//                print("Matching policy names: \(names)")
//            }
     
            
            
//#if os(macOS)
//            List(networkController.allIconsDetailed, id: \.self, selection: $selectedIcon) { icon in
//                HStack {
//                    Image(systemName: "photo.circle")
//                    Text(icon.name).font(.system(size: 12.0)).foregroundColor(.black)
//                    AsyncImage(url: URL(string: icon.url )) { image in
//                        image.resizable().frame(width: 15, height: 15)
//                    } placeholder: {
//                    }
//                }
//                .foregroundColor(.gray)
//                .listRowBackground(selectedIconString == icon.name
//                                   ? Color.green.opacity(0.3)
//                                   : Color.clear)
//                .tag(icon)
//            }
//            .cornerRadius(8)
//            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 200, alignment: .leading)
//#else
//
//            List(networkController.allIconsDetailed, id: \.self) { icon in
//                HStack {
//                    Image(systemName: "photo.circle")
//                    Text(icon.name).font(.system(size: 12.0)).foregroundColor(.black)
//                    AsyncImage(url: URL(string: icon.url )) { image in
//                        image.resizable().frame(width: 15, height: 15)
//                    } placeholder: {
//                    }
//                }
//            }
//#endif
            //                                    .background(.gray)
            //        }
            
            
            // ################################################################################
            //                        Icons - picker
            // ################################################################################
            
            
            LazyVGrid(columns: layout.columns, spacing: 10) {
                
                
                HStack {
                    TextField("Filter", text: $iconFilter)
                    Picker(selection: $selectedIcon, label: Text("").bold()) {
                        Text("No icon selected").tag(nil as Icon?)
                        ForEach(networkController.allIconsDetailed.filter { iconFilter.isEmpty ? true : $0.name.lowercased().contains(iconFilter.lowercased()) }, id: \.self) { icon in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(minWidth: 32, maxWidth: 32, minHeight: 32, maxHeight: 32)
                                    AsyncImage(url: URL(string: icon.url ))  { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(minWidth: 32, maxWidth: 32, minHeight: 32, maxHeight: 32)
                                            .clipped()
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                Text(String(describing: icon.name))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(height: 36)
                            .frame(minWidth: 32, maxWidth: 32, minHeight: 32, maxHeight: 32)
                            .tag(icon as Icon?)
                        }
                    }
                    .onAppear {
                        if !networkController.allIconsDetailed.isEmpty {
                            // Only set selectedIcon if the first icon exists
                            selectedIcon = networkController.allIconsDetailed.first
                        } else {
                            selectedIcon = nil
                        }
                    }
                    .onChange(of: networkController.allIconsDetailed) { newIcons in
                        if !newIcons.isEmpty {
                            selectedIcon = newIcons.first
                        } else {
                            selectedIcon = nil
                        }
                    }
                }
                
                
                //                ############################################################
                //                Update Icon Button
                //                ############################################################
                
                
                
                
                HStack {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        if let icon = selectedIcon {
                                                    xmlController.updateIconBatch(selectedPoliciesInt: policiesMatchingItems , server: server, authToken: networkController.authToken, iconFilename: String(describing: icon.name), iconID: String(describing: icon.id), iconURI: String(describing: icon.url))
                        } else {
                            print("No icon selected")
                        }
                    }) {
                        Text("Update Icon")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                HStack {
                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 20000)                        }) {
                            Text("Refresh Icons")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
                
                
                //  ##########################################################################
                //  Progress view via showProgress
                //  ##########################################################################
                
                if progress.showProgressView == true {
                    
                    ProgressView {
                        Text("Processing")
                    }
                    .padding()
                } else {
                    Text("")
                }
            }
            .padding()
        }
        
        
         .onAppear() {
            // If basic policies are missing, try fetching them so the list can show something
            if networkController.allPoliciesConverted.isEmpty {
                print("PolicyListView: allPoliciesConverted empty onAppear — fetching basic policies")
                Task {
                    do {
                        try await networkController.getAllPolicies(server: server)
                        updateMatchingIDs()
                    } catch {
                        print("PolicyListView: failed to fetch basic policies: \(error)")
                    }
                }
            }

            // If detailed policies haven't been fetched, fetch them (existing behavior)
            if networkController.fetchedDetailedPolicies == false {
                print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
                if networkController.allPoliciesDetailed.count < networkController.allPoliciesConverted.count {
                    print("fetching detailed policies")
                    progress.showProgress()
                    Task {
                        try await networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                    }
                    progress.waitForABit()
                    networkController.fetchedDetailedPolicies = true
                } else {
                    print("Download complete")
                }
            } else {
                print("fetchedDetailedPolicies has run")
            }
            
            
            if networkController.allIconsDetailed.count <= 1 {
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 1000)
            } else {
                print("getAllIconsDetailed has already run")
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            }
            
            
            
            
            
            // Update the matching IDs when the view appears
            updateMatchingIDs()
        }
        // Keep matching IDs up to date when inputs change
        .onChange(of: searchString) { _ in updateMatchingIDs() }
        .onChange(of: textSearchScope) { _ in updateMatchingIDs() }
        .onChange(of: selectedFieldForFilter) { _ in updateMatchingIDs() }
        .onChange(of: selectedFieldIsEmpty) { _ in updateMatchingIDs() }
        .onChange(of: matchMode) { _ in updateMatchingIDs() }
        .onChange(of: caseSensitive) { _ in updateMatchingIDs() }
         // Also update if the underlying policies array changes
         .onReceive(networkController.$allPoliciesDetailed) { _ in updateMatchingIDs() }
         // Also update when the basic policies list arrives so the UI can show fallback list immediately
         .onReceive(networkController.$allPoliciesConverted) { _ in updateMatchingIDs() }
    }
    
    // MARK: - Matching Logic
    func isPolicyMatch(_ policy: PolicyDetailed) -> Bool {
        // Evaluate empty-field filter (if requested)
        let emptyFieldMatches: Bool = {
            if selectedFieldIsEmpty {
                return selectedFieldForFilter.isFieldEmpty(in: policy)
            } else {
                return true
            }
        }()
        
        // Evaluate text search filter (if provided) according to the selected scope
        let textFilterMatches: Bool = {
            let trimmed = searchString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return true }
            // Helper to match a single text value according to options
            func matchText(_ value: String?) -> Bool {
                guard let value = value else { return false }
                if caseSensitive {
                    switch matchMode {
                    case .contains:
                        return value.contains(trimmed)
                    case .startsWith:
                        return value.hasPrefix(trimmed)
                    }
                } else {
                    let lhs = value.lowercased()
                    let rhs = trimmed.lowercased()
                    switch matchMode {
                    case .contains:
                        return lhs.contains(rhs)
                    case .startsWith:
                        return lhs.hasPrefix(rhs)
                    }
                }
            }

            switch textSearchScope {
            case .title:
                return matchText(policy.general?.name)
            case .all:
                return SearchField.all.isMatch(in: policy, search: trimmed, matchMode: matchMode, caseSensitive: caseSensitive)
            case .selectedField:
                return selectedFieldForFilter.isMatch(in: policy, search: trimmed, matchMode: matchMode, caseSensitive: caseSensitive)
            }
        }()
        
        // Both filters must pass to be considered a match
        return emptyFieldMatches && textFilterMatches
    }
}

// Search fields and logic for matching
enum SearchField: String, CaseIterable {
    case all
    case generalName
    case generalID
    case generalEnabled
    case selfServiceDisplayName
    case selfServiceDescription
    case selfServiceIconURI

    // New scope-related fields
    case scopeAllComputers
    case scopeAllJSSUsers
    case scopeComputers
    case scopeComputerGroups
    case scopeBuildings
    case scopeDepartments
    case scopeLimitToUsers
    case scopeLimitationsUsers
    case scopeExclusions

    var displayName: String {
        switch self {
        case .all: return "All"
        case .generalName: return "General: Name"
        case .generalID: return "General: ID"
        case .generalEnabled: return "General: Enabled"
        case .selfServiceDisplayName: return "Self Service: Display Name"
        case .selfServiceDescription: return "Self Service: Description"
        case .selfServiceIconURI: return "Self Service: Icon URI"
        case .scopeAllComputers: return "Scope: All Computers"
        case .scopeAllJSSUsers: return "Scope: All JSS Users"
        case .scopeComputers: return "Scope: Computers"
        case .scopeComputerGroups: return "Scope: Computer Groups"
        case .scopeBuildings: return "Scope: Buildings"
        case .scopeDepartments: return "Scope: Departments"
        case .scopeLimitToUsers: return "Scope: Limit To Users"
        case .scopeLimitationsUsers: return "Scope: Limitations: Users"
        case .scopeExclusions: return "Scope: Exclusions"
        }
    }

    func isMatch(in policy: PolicyDetailed, search: String, matchMode: PolicyListView.MatchMode = .contains, caseSensitive: Bool = false) -> Bool {
        // Normalize inputs depending on case sensitivity
        let targetSearch = caseSensitive ? search : search.lowercased()
        func match(_ value: String?) -> Bool {
            guard let v = value else { return false }
            let subject = caseSensitive ? v : v.lowercased()
            switch matchMode {
            case .contains:
                return subject.contains(targetSearch)
            case .startsWith:
                return subject.hasPrefix(targetSearch)
            }
        }

        switch self {
        case .all:
            // include general, self-service and scope related fields
            return
                match(policy.general?.name) ||
                (policy.general?.jamfId != nil && {
                    let idStr = String(describing: policy.general!.jamfId!)
                    let subject = caseSensitive ? idStr : idStr.lowercased()
                    switch matchMode {
                    case .contains: return subject.contains(targetSearch)
                    case .startsWith: return subject.hasPrefix(targetSearch)
                    }
                }()) ||
                (policy.general?.enabled != nil && {
                    let enabledStr = String(describing: policy.general!.enabled!)
                    let subject = caseSensitive ? enabledStr : enabledStr.lowercased()
                    switch matchMode {
                    case .contains: return subject.contains(targetSearch)
                    case .startsWith: return subject.hasPrefix(targetSearch)
                    }
                }()) ||
                match(policy.self_service?.selfServiceDisplayName) ||
                match(policy.self_service?.selfServiceDescription) ||
                match(policy.self_service?.selfServiceIcon?.uri) ||
                // scope checks: match basic boolean/string forms and any names inside scope arrays
                (policy.scope?.allComputers != nil && {
                    let s = String(describing: policy.scope!.allComputers!)
                    let subject = caseSensitive ? s : s.lowercased()
                    switch matchMode { case .contains: return subject.contains(targetSearch); case .startsWith: return subject.hasPrefix(targetSearch) }
                }()) ||
                (policy.scope?.all_jss_users != nil && {
                    let s = String(describing: policy.scope!.all_jss_users!)
                    let subject = caseSensitive ? s : s.lowercased()
                    switch matchMode { case .contains: return subject.contains(targetSearch); case .startsWith: return subject.hasPrefix(targetSearch) }
                }()) ||
                (policy.scope?.computers?.contains { match($0.name) } ?? false) ||
                (policy.scope?.computerGroups?.contains { match($0.name ?? "") } ?? false) ||
                (policy.scope?.buildings?.contains { match($0.name) } ?? false) ||
                (policy.scope?.departments?.contains { match($0.name) } ?? false) ||
                (policy.scope?.limitToUsers?.users?.contains { match($0.name) } ?? false) ||
                (policy.scope?.limitations?.users?.contains { match($0.name) } ?? false) ||
                // exclusions: check common exclusion arrays for matching names
                (policy.scope?.exclusions?.computers?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.computerGroups?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.buildings?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.departments?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.users?.contains { match($0.name) } ?? false)

        case .generalName:
            return match(policy.general?.name)
        case .generalID:
            if let id = policy.general?.jamfId { let idStr = String(describing: id); return caseSensitive ? idStr.contains(search) : idStr.lowercased().contains(targetSearch) }
            return false
        case .generalEnabled:
            if let enabled = policy.general?.enabled { let s = String(describing: enabled); return caseSensitive ? s.contains(search) : s.lowercased().contains(targetSearch) }
            return false
        case .selfServiceDisplayName:
            return match(policy.self_service?.selfServiceDisplayName)
        case .selfServiceDescription:
            return match(policy.self_service?.selfServiceDescription)
        case .selfServiceIconURI:
            return match(policy.self_service?.selfServiceIcon?.uri)

        // Scope-specific cases
        case .scopeAllComputers:
            if let val = policy.scope?.allComputers { let s = String(describing: val); let subject = caseSensitive ? s : s.lowercased(); switch matchMode { case .contains: return subject.contains(targetSearch); case .startsWith: return subject.hasPrefix(targetSearch) } }
            return false
        case .scopeAllJSSUsers:
            if let val = policy.scope?.all_jss_users { let s = String(describing: val); let subject = caseSensitive ? s : s.lowercased(); switch matchMode { case .contains: return subject.contains(targetSearch); case .startsWith: return subject.hasPrefix(targetSearch) } }
            return false
        case .scopeComputers:
            return policy.scope?.computers?.contains { match($0.name) } ?? false
        case .scopeComputerGroups:
            return policy.scope?.computerGroups?.contains { match($0.name ?? "") } ?? false
        case .scopeBuildings:
            return policy.scope?.buildings?.contains { match($0.name) } ?? false
        case .scopeDepartments:
            return policy.scope?.departments?.contains { match($0.name) } ?? false
        case .scopeLimitToUsers:
            return policy.scope?.limitToUsers?.users?.contains { match($0.name) } ?? false
        case .scopeLimitationsUsers:
            return policy.scope?.limitations?.users?.contains { match($0.name) } ?? false
        case .scopeExclusions:
            return (
                (policy.scope?.exclusions?.computers?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.computerGroups?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.buildings?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.departments?.contains { match($0.name) } ?? false) ||
                (policy.scope?.exclusions?.users?.contains { match($0.name) } ?? false)
            )
        }
    }

    func isFieldEmpty(in policy: PolicyDetailed) -> Bool {
        switch self {
        case .all:
            return false
        case .generalName:
            return (policy.general?.name?.isEmpty ?? true)
        case .generalID:
            return policy.general?.jamfId == nil
        case .generalEnabled:
            return policy.general?.enabled == nil
        case .selfServiceDisplayName:
            return (policy.self_service?.selfServiceDisplayName?.isEmpty ?? true)
        case .selfServiceDescription:
            return (policy.self_service?.selfServiceDescription?.isEmpty ?? true)
        case .selfServiceIconURI:
            return (policy.self_service?.selfServiceIcon?.uri ?? "").isEmpty

        // Scope emptiness checks
        case .scopeAllComputers:
            return policy.scope?.allComputers == nil
        case .scopeAllJSSUsers:
            return policy.scope?.all_jss_users == nil
        case .scopeComputers:
            return (policy.scope?.computers?.isEmpty ?? true)
        case .scopeComputerGroups:
            return (policy.scope?.computerGroups?.isEmpty ?? true)
        case .scopeBuildings:
            return (policy.scope?.buildings?.isEmpty ?? true)
        case .scopeDepartments:
            return (policy.scope?.departments?.isEmpty ?? true)
        case .scopeLimitToUsers:
            return (policy.scope?.limitToUsers?.users?.isEmpty ?? true)
        case .scopeLimitationsUsers:
            return (policy.scope?.limitations?.users?.isEmpty ?? true)
        case .scopeExclusions:
            let ex = policy.scope?.exclusions
            let hasAny = (ex?.computers?.isEmpty == false) || (ex?.computerGroups?.isEmpty == false) || (ex?.buildings?.isEmpty == false) || (ex?.departments?.isEmpty == false) || (ex?.users?.isEmpty == false)
            return !hasAny
        }
    }
}
