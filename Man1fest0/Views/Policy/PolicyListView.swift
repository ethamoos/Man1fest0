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
    @State private var searchField: SearchField = .all
    @State private var searchForEmptyField: SearchField? = nil
    
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
            HStack {
                TextField("Search...", text: $searchString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                Picker("Field", selection: $searchField) {
                    ForEach(SearchField.allCases, id: \.self) { field in
                        Text(field.displayName)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Button("Find Empty Field") {
                    searchForEmptyField = searchField
                }
                Button("Clear Empty Field Search") {
                    searchForEmptyField = nil
                }
                
                Spacer()
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
     
            
            Text("Icons").bold()
            
#if os(macOS)
            List(networkController.allIconsDetailed, id: \.self, selection: $selectedIcon) { icon in
                HStack {
                    Image(systemName: "photo.circle")
                    Text(String(describing: icon.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black)
                    AsyncImage(url: URL(string: icon.url ?? "" )) { image in
                        image.resizable().frame(width: 15, height: 15)
                    } placeholder: {
                    }
                }
                .foregroundColor(.gray)
                .listRowBackground(selectedIconString == icon.name
                                   ? Color.green.opacity(0.3)
                                   : Color.clear)
                .tag(icon)
            }
            .cornerRadius(8)
            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 200, alignment: .leading)
#else
            
            List(networkController.allIconsDetailed, id: \.self) { icon in
                HStack {
                    Image(systemName: "photo.circle")
                    Text(String(describing: icon?.name ?? "")).font(.system(size: 12.0)).foregroundColor(.black)
                    AsyncImage(url: URL(string: icon.url ?? "" )) { image in
                        image.resizable().frame(width: 15, height: 15)
                    } placeholder: {
                    }
                }
            }
#endif
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
            }
        }
        
        
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
            // Update the matching IDs when the view appears
            updateMatchingIDs()
        }
        // Keep matching IDs up to date when inputs change
        .onChange(of: searchString) { _ in updateMatchingIDs() }
        .onChange(of: searchField) { _ in updateMatchingIDs() }
        .onChange(of: searchForEmptyField) { _ in updateMatchingIDs() }
        // Also update if the underlying policies array changes
        .onReceive(networkController.$allPoliciesDetailed) { _ in updateMatchingIDs() }
    }
    
    // MARK: - Matching Logic
    func isPolicyMatch(_ policy: PolicyDetailed) -> Bool {
        if let emptyField = searchForEmptyField, searchString.isEmpty {
            print("Missing policy is:\(String(describing: policy.general?.name ?? ""))")
            return emptyField.isFieldEmpty(in: policy)
        }
        if searchString.isEmpty { return true }
        print("Matching policy is:\(String(describing: policy.general?.name ?? ""))")
        //        networkController.policiesMatchingItems.insert(policy.general?.jamfId ?? 0, at: 0)
        return searchField.isMatch(in: policy, search: searchString)
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
    
    func isMatch(in policy: PolicyDetailed, search: String) -> Bool {
        let search = search.lowercased()
        switch self {
        case .all:
            return
            (policy.general?.name?.localizedCaseInsensitiveContains(search) ?? false) ||
            (policy.general?.jamfId != nil && "\(policy.general!.jamfId!)".contains(search)) ||
            (policy.general?.enabled != nil && "\(policy.general!.enabled!)".localizedCaseInsensitiveContains(search)) ||
            (policy.self_service?.selfServiceDisplayName?.localizedCaseInsensitiveContains(search) ?? false) ||
            (policy.self_service?.selfServiceDescription?.localizedCaseInsensitiveContains(search) ?? false) ||
            ((policy.self_service?.selfServiceIcon?.uri ?? "").localizedCaseInsensitiveContains(search))
        case .generalName:
            return policy.general?.name?.localizedCaseInsensitiveContains(search) ?? false
        case .generalID:
            return policy.general?.jamfId != nil && "\(policy.general!.jamfId!)".contains(search)
        case .generalEnabled:
            return policy.general?.enabled != nil && "\(policy.general!.enabled!)".localizedCaseInsensitiveContains(search)
        case .selfServiceDisplayName:
            return policy.self_service?.selfServiceDisplayName?.localizedCaseInsensitiveContains(search) ?? false
        case .selfServiceDescription:
            return policy.self_service?.selfServiceDescription?.localizedCaseInsensitiveContains(search) ?? false
        case .selfServiceIconURI:
            return (policy.self_service?.selfServiceIcon?.uri ?? "").localizedCaseInsensitiveContains(search)
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
