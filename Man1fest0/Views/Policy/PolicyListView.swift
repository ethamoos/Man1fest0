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
        networkController.allPoliciesDetailed
            .compactMap { $0 } // remove nil entries
            .map { policy in
                let isHighlighted = isPolicyMatch(policy)
                return MatchedPolicyPair(policy: policy, isHighlighted: isHighlighted)
            }
            .filter { $0.isHighlighted } // show only matches
    }
    
    // Helper to update matching IDs (and sync to NetBrain if desired)
    private func updateMatchingIDs() {
        let pairs = computeMatchedPairs()
        // update cached pairs used by the view
        matchedPolicyPairsState = pairs
        // update ids
        let ids = pairs.compactMap { $0.policy.general?.jamfId }
        policiesMatchingItems = ids
        networkController.policiesMatchingItems = ids
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
                    // Show only filtered (matching) policies and use the model's Identifiable id
                    ForEach(matchedPolicyPairsState) { pair in
                        let policy = pair.policy
                        let isHighlighted = pair.isHighlighted
                        PolicyRowView(policy: policy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isHighlighted ? Color.white.opacity(0.12) : Color.clear)
                            .cornerRadius(6)
                            .padding(.horizontal)
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
    
//            . padding()
//            .frame(minWidth: 150, maxWidth: .infinity, minHeight: 70, maxHeight: .infinity)
        
        .onAppear() {
            // If detailed policies haven't been fetched, fetch them (existing behavior)
            if networkController.fetchedDetailedPolicies == false {
                print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
                if networkController.allPoliciesDetailed.count < networkController.allPoliciesConverted.count {
                    print("fetching detailed policies")
                    progress.showProgress()
                    networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
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
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .generalName: return "General: Name"
        case .generalID: return "General: ID"
        case .generalEnabled: return "General: Enabled"
        case .selfServiceDisplayName: return "Self Service: Display Name"
        case .selfServiceDescription: return "Self Service: Description"
        case .selfServiceIconURI: return "Self Service: Icon URI"
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
                match(policy.self_service?.selfServiceIcon?.uri)
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
        }
    }
}
