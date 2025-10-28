import SwiftUI

struct PolicyListView: View {
    
    var server: String

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress

    @State private var searchString: String = ""
    @State private var searchField: SearchField = .all
    @State private var searchForEmptyField: SearchField? = nil
    
    @State var policiesMatchingItems: [Int] = []
    @State var policiesMissingItems: [Int] = []

    @State var selection = Set<PolicyDetailed>()
    @State var selectionMatching = ""
    @State var selectionMissing = ""

    
    var body: some View {
        
        var filteredPolicies: [PolicyDetailed?] {
            networkController.allPoliciesDetailed.enumerated().compactMap { idx, policy in
                let isMatch = isPolicyMatch(policy!)
                print("isMatch is:\(isMatch)")
                return isMatch ? policy : nil
            }
        }
        
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
                    ForEach(networkController.allPoliciesDetailed.indices, id: \.self) { idx in
                        if let policy = networkController.allPoliciesDetailed[idx] {
                            let isHighlighted = isPolicyMatch(policy)
                            PolicyRowView(policy: policy)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(isHighlighted ? Color.yellow.opacity(0.12) : Color.clear)
                                .cornerRadius(6)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            
            /*
            List(networkController.allPoliciesDetailed, id: \\.self, selection: $selection) { policy in
                let isHighlighted = isPolicyMatch(policy!)
                PolicyRowView(policy: policy)
                    .listRowBackground(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
            }
            */
            
            Text("Matching Policies")

//            List(networkController.policiesMatchingItem, id: \.self, selection: $selectionMatching) { policy in
//
//                Text("Policy ID:\(policy)")
//            }
            
            Text("Policies Missing Item")

            List {
                ForEach(networkController.policiesMissingItems, id: \.self) { policy in
                    Text("Policy ID:\(policy)")
                }
            }
            
            
            
            .onAppear() {
                if networkController.fetchedDetailedPolicies == false {
                    
                    print("fetchedDetailedPolicies is set to false - running getAllPoliciesDetailed")
                    
                    if networkController.allPoliciesDetailed.count < networkController.allPoliciesConverted.count {
                        
                        print("fetching detailed policies")
                        
                        progress.showProgress()
                        
                        networkController.getAllPoliciesDetailed(server: server, authToken: networkController.authToken, policies: networkController.allPoliciesConverted)
                        
//                        convertToallPoliciesDetailedGeneral()
                    
                        progress.waitForABit()
                        
                        networkController.fetchedDetailedPolicies = true
                        
                    } else {
                        print("Download complete")
                    }
                } else {
                    print("fetchedDetailedPolicies has run")
                }
                
            }
        }
    }
    
    // MARK: - Matching Logic
    func isPolicyMatch(_ policy: PolicyDetailed) -> Bool {
        if let emptyField = searchForEmptyField, searchString.isEmpty {
//            print("searchString is emptyField:\(emptyField)
            print("Missing policy is:\(String(describing: policy.general?.name ?? ""))")
//            networkController.policiesMissingItems.insert(policy.general?.jamfId ?? 0, at: 0)
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
            (policy.self_service?.selfServiceIcon?.uri?.localizedCaseInsensitiveContains(search) ?? false)
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
            return policy.self_service?.selfServiceIcon?.uri?.localizedCaseInsensitiveContains(search) ?? false
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
            return (policy.self_service?.selfServiceIcon?.uri?.isEmpty ?? true)
        }
    }
}
