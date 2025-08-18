import Foundation
import SwiftUI

struct HorizontalProgressViewStyle: ProgressViewStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
            configuration.label
        }.foregroundColor(.secondary)
    }
}

extension ProgressViewStyle where Self == HorizontalProgressViewStyle {
    static var horizontal: HorizontalProgressViewStyle { .init() }
}



struct PolicyView: View {
    
    var server: String
    var selectedResourceType: ResourceType
    
    //  ########################################################################################
    //  ENVIRONMENT
    //  ########################################################################################
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    //    ########################################################################################
    //    SELECTIONS
    //    ########################################################################################
    
//    @State private var selection = Set<Policy>()
    @State private var selection: Policy = Policy(name: "")
    
    @State var searchText = ""
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.resourceAccess == false {
                Text("Access to this resource is not available")
            } else {
                
                if networkController.policies.count > 0 {
                    NavigationView {
                        
#if os(macOS)
                        List(searchResults, id: \.self, selection: $selection) { policy in
                            NavigationLink(destination: PolicyDetailView(server: server, policy: policy, policyID: policy.jamfId ?? 1)) {
                                
                                HStack {
                                    Image(systemName:"text.justify")
                                    Text("\(policy.name)")
                                }
#if os(macOS)
                                .navigationTitle("JamfPolicy")
#endif
                                .foregroundColor(.blue)
                            }
                        }
#if os(macOS)
                        .frame(minWidth: 300, maxWidth: .infinity)
#endif
                        .toolbar {
                            Button(action: {
                                networkController.connect(server: server,resourceType: ResourceType.policy, authToken: networkController.authToken)
                                xmlController.getPolicyAsXML(server: server, policyID: Int(selection.jamfId ?? 0), authToken: networkController.authToken)
                                print("Refresh policyView - get all policies")
                                networkController.connect(server: server,resourceType: ResourceType.policy, authToken: networkController.authToken)
                                progress.showProgress()
                                progress.waitForABit()
                                if selection.name.isEmpty == false {
                                    print("Policy is selected")
                                    print("Refreshing detailed policy:\(selection.jamfId ?? 0)")
                                    networkController.connectDetailed(server: server, authToken: networkController.authToken, resourceType: ResourceType.policyDetail, itemID: Int(selection.jamfId ?? 0))
                                    print("Refreshing all policies")
                                    networkController.connect(server: server,resourceType: ResourceType.policy, authToken: networkController.authToken)
                                    print("Refresh getPolicyAsXML")
                                        xmlController.getPolicyAsXML(server: server, policyID: Int(selection.jamfId ?? 0), authToken: networkController.authToken)
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        .searchable(text: $searchText)
                        
                        Text("\(networkController.policies.count) total policies")
                            .toolbar {
                            }
#else
//                        List(searchResults, id: \.self) { policy in
//                            NavigationLink(destination: PolicyDetailView_iOS(server: server, policy: policy, policyID: policy.jamfId ?? 1)) {
//                                HStack {
//                                    Image(systemName:"text.justify")
//                                    Text("\(policy.name)")
//                                }
//#if os(macOS)
//                                .navigationTitle("JamfPolicy")
//#endif
//                                .foregroundColor(.blue)
//                            }
//                        }
#endif
                    }
                    
                    .navigationViewStyle(DefaultNavigationViewStyle())
                    
                } else {
                    
                    ProgressView {
                        Text("Loading")
                            .font(.title)
                            .progressViewStyle(.horizontal)
                    }
                }
            }
        }
        
        
        //              ################################################################################
        //              onAppear
        //              ################################################################################
        
        .onAppear {

            networkController.connect(server: server,resourceType: ResourceType.policy, authToken: networkController.authToken)
            
            Task {
                try await scopingController.getLdapServers(server: server, authToken: networkController.authToken)
            }
        }
        .frame(minWidth: 100, minHeight: 100, alignment: .center)
    }
    

    
    private func getAllPolicies() {
        print("Clicking Button")
    }
    
    var searchResults: [Policy] {
        if searchText.isEmpty {
            return networkController.policies
        } else {
            return networkController.policies.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}



//struct ItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        ItemView()
//    }
//}
