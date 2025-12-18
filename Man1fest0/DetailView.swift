import SwiftUI

// ##################################
// UNUSED - Struct
// ##################################
struct PolicyDetailLegacyView: View {
    
    var server: String
    var user: String
    var password: String
    var itemID: Int

    @EnvironmentObject var networkController: NetBrain

    @State private var selectedResourceType = ResourceType.policyDetail

    @State var currentDetailedPolicy: PolicyCodable? = nil

    @State private var packageSelection = Set<Package>()

    @State private var selection: Package? = nil

    @State private var packages: [ Package ] = []

    @State var enableDisable: Bool = true

    var policy: Policies

    var body: some View {
        
        
        VStack(alignment: .leading) {
            
            Text("Jamf Name:\t\t\(networkController.policyDetailed?.policy.general?.name ?? "Blank")\n")
            Text("Policy Trigger:\t\(networkController.policyDetailed?.policy.general?.trigger ?? "")\n")
            Text("Jamf ID:\t\t\t\(String(describing: networkController.policyDetailed?.policy.general?.jamfId ?? 0))" )

            if let detailed = networkController.policyDetailed {
                
                if let packages = detailed.policy.package_configuration?.packages {
                    
                    List(packages, id: \.self, selection: $selection) { package in
                        
                        HStack {
                            Text(package.name ?? "")
                        }
                    }
                }

                VStack(alignment: .leading) {
                  

                    Button(action: {
                        print("Delete")
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "delete.left.fill")
                            Text("Delete")
                        }
                    }
                    
                    Button(action: {
                        print("Clone")
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Clone")
                        }
                    }
                    
//                    Button(action: {
//                        print("Assigning package")
//                        for package in packages {
//                            print("Assigning package:\(package)")
//                            networkController.addToAssignedPackages(package: package)
//                        }
//                    }) {
//                        HStack(spacing: 10) {
//                            Image(systemName: "plus.square.fill.on.square.fill")
//                            Text("Assign")
//                        }
//                    }
                    
                    HStack(spacing: 10) {

                        Toggle("", isOn: $enableDisable)
                            .toggleStyle(SwitchToggleStyle(tint: .red))
                        
                            .onChange(of: enableDisable) { value in
                                                            networkController.togglePolicyOnOff(to: server, as: user, password: password, resourceType: selectedResourceType, itemID: itemID, policyToggle: enableDisable)
//                                 policyToggle = false
                                         print("Value is:\(value)")
                                     }
                        
                        
                        
                        if enableDisable {
                            Text("Enabled")
                        } else {
                            Text("Disabled")

                        }
                    }
                    
                    
                    Button(action: {
                            print("Assigning package:\(packageSelection)")
                        if let selection {
                            networkController.addToAssignedPackages(package: selection)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("Assign")
                        }
                    }
                                        
                    Text("\(networkController.allPackagesAssigned.count) total packages in use")

                }
                .frame(width: 400, height: 100, alignment: .leading)
            }
        }
        .onAppear {
            
            print("PolicyDetailView appeared - connecting")

            handleConnect(resourceType: selectedResourceType)

                        if let detailed = networkController.policyDetailed {
                            if let packages = detailed.policy.package_configuration?.packages {
                                for package in packages {
                                    print("Assigning package:\(package)")
                                    networkController.addToAssignedPackages(package: package)
                                }
                            }
                        }
        }
        .padding()
        Spacer()
    }
    
    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        networkController.connectDetailed(to: server, as: user, password: password, resourceType: selectedResourceType, itemID: itemID)
    }
}





//struct PolicyDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PolicyDetailView()
//    }
//}
