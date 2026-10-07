// Retired copy of the iOS-variant PolicyDetailView. The original commented
// variant lived at `Views/Shared/PolicyDetailView_iOS.swift` and was kept for
// reference. Moving it into Retired Files reduces clutter in the active Views
// folder while preserving the original content.

// Original file contents preserved below (left commented as in the original).

////
////  PolicyDetailView_-iOS.swift
////  Man1fest0
////
////  Created by Amos Deane on 19/09/2024.
////
//
//import SwiftUI
//
//struct PolicyDetailView_iOS: View {
// 
//    var server: String
//    
//    //  ########################################################################################
//    //  EnvironmentObjects
//    //  ########################################################################################
//    
//    @EnvironmentObject var networkController: NetBrain
//    
//    @EnvironmentObject var scopingController: ScopingBrain
//    
//    @EnvironmentObject var progress: Progress
//    
//    @EnvironmentObject var policyController: PolicyBrain
//    
//    @EnvironmentObject var layout: Layout
//    
//    //  ########################################################################################
//    
//    @State var selectedResourceType = ResourceType.policyDetail
//    
//    @State var selection: Package? = nil
//    
//    @State var categoryName = ""
//    
//    @State private var categoryID = ""
//    
//    @State var categories: [Category] = []
//    
//    @State private var computers: [ Computer ] = []
//    
//    @State var computerID = ""
//    
//    @State var computerUDID = ""
//    
//    @State var computerName = ""
//    
//    //  ########################################################################################
//    //  GROUPS
//    //  ########################################################################################
//
//    @State private var computerGroupSelection = Set<ComputerGroup>()
//    
//    @State var computerGroupFilter = ""
//    
//    //  ########################################################################################
//    //  LDAP
//    //  ########################################################################################
//    
//    @State var ldapUserGroupName = ""
//    
//    @State var ldapUserGroupId = ""
//    
//    @State var ldapUserGroupName2 = ""
//    
//    @State var ldapUserGroupId2 = ""
//    
//    //  ########################################################################################
//    //  Packages
//    //  ########################################################################################
//    
//    @State var packageSelection = Set<Package>()
//    
//    @State var packageFilter = ""
//    
//    @State private var packageID = ""
//    
//    @State private var packageName = ""
//    
//    //  ########################################################################################
//    //  Policies
//    //  ########################################################################################
//    
//    var policy: Policy
//    
//    var policyID: Int
//    
//    @State var policyName = ""
//    
//    @State var policyNameInitial = ""
//    
//    @State var policyCustomTrigger = ""
//
//    //    ########################################################################################
//    //    ########################################################################################
//    //    VARIABLES
//    //    ########################################################################################
//    //    ########################################################################################
//    
//    @State var currentDetailedPolicy: PoliciesDetailed? = nil
//    
//    @State var scriptName = ""
//    
//    @State var scriptID = ""
//    
//    @State var enableDisableButton: Bool = true
//    
//    @State var enableDisableStatus: Bool = true
//    
//    @State var enableDisableSelfServiceStatus: Bool = true
//    
//    @State var enableDisableSelfService: Bool = true
//    
//    //    ########################################################################################
//    //    Selections
//    //    ########################################################################################
//    
//    @State var selectedComputer: Computer = Computer(id: 0, name: "")
//    
//    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
//    
//    @State var selectedDepartment: Department = Department(jamfId: 0, name: "")
//    
//    @State var selectedScript: ScriptClassic = ScriptClassic(name: "", jamfId: 0)
//    
//    @State var selectedPackage: Package = Package(jamfId: 0, name: "", udid: nil)
//    
//    //    ########################################################################################
//    //    Script parameters
//    //    ########################################################################################
//    
//    @State var scriptParameter4: String = ""
//    
//    @State var scriptParameter5: String = ""
//    
//    @State var scriptParameter6: String = ""
//    
//    @State  var tempUUID = (UUID(uuidString: "") ?? UUID())
//    
//    @State private var showingWarning = false
//    
//    //    ########################################################################################
//    //    ########################################################################################
//    //    MAIN BODY
//    //    ########################################################################################
//    //    ########################################################################################
//    
//                                   
//    var body: some View {
//        
//        VStack(alignment: .leading) {
//            
//                if networkController.currentDetailedPolicy != nil {
//                    VStack(alignment: .leading) {
//                        
//                        Text("Jamf Name:\t\t\t\t\(networkController.policyDetailed?.general?.name ?? \"Blank\")\n")
//                        Text("Enabled Status:\t\t\t\(String(describing: networkController.policyDetailed?.general?.enabled ?? true))\n")
//                        Text("Policy Trigger:\t\t\t\t\(networkController.policyDetailed?.general?.triggerOther ?? \"\")\n")
//                        Text("Category:\t\t\t\t\t\(networkController.policyDetailed?.general?.category?.name ?? \"\")\n")
//                        Text("Jamf ID:\t\t\t\t\t\(String(describing: networkController.policyDetailed?.general?.jamfId ?? 0))" )
//                    }
//                    .textSelection(.enabled)
//                    .foregroundColor(.blue)
//                }
//            }
//        }
