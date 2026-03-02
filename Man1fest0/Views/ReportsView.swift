////
////  OptionsView.swift
////  JamfListApp
////
////  Created by Amos Deane on 16/04/2024.
////
//
import SwiftUI
import UniformTypeIdentifiers

struct ReportsView: View {
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password = ""
    
    //    ########################################################################################
    //    EnvironmentObject
    //    ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var backgroundTasks: BackgroundTasks
    
    // @EnvironmentObject var controller: JamfController
    
    @EnvironmentObject var exportController: ImportExportBrain
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    //    ########################################################################################
    
    @State private var sortOrder = [KeyPathComparator(\Policy.jamfId)]
    @State private var selection = Set<Policy.ID>()
    
    //    ########################################################################################
    //    Text exporting
    //    ########################################################################################

    @State private var exporting = false

    
    var body: some View {
        
        let text = String(describing: networkController.allPackages)
        let document = TextDocument(text: text)

        Form {
            
            Group {
                
                if networkController.allPoliciesDetailed.count > 0 {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        
                        Text("Jamf server is:\t\t\t\t\t\t\(server)")
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        Text("Total policies in Jamf:\t\t\t\t\(networkController.allPoliciesConverted.count)")
                            .fontWeight(.bold)
                        
                        Text("Policy records downloaded:\t\t\t\(networkController.allPoliciesDetailed.count)")
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        Text("Total Packages in Jamf:\t\t\t\t\(networkController.allPackages.count )")
                            .fontWeight(.bold)
                        
                        Text("Packages in a policy:\t\t\t\t\t\(backgroundTasks.assignedPackagesByNameDict.count)")
                            .fontWeight(.bold)
                        
                        Text("Packages not in a policy :\t\t\t\t\(backgroundTasks.unassignedPackagesArray.count)")
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        Text("Total Scripts in Jamf:\t\t\t\t\t\(networkController.scripts.count)")
                            .fontWeight(.bold)
                        
                        Text("Scripts in a policy:\t\t\t\t\t\(policyController.assignedScriptsByNameDict.count)")
                            .fontWeight(.bold)
                        
                        Text("Scripts not in a policy:\t\t\t\t\(policyController.unassignedScriptsArray.count)")
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        Text("Current date is:\t\t\t\t\t\t\(layout.date)")
                            .fontWeight(.bold)
                        
                        //                        Table(networkController.allPoliciesConverted, selection: $selection, sortOrder: $sortOrder) {
                        //
                        //                            TableColumn("Name", value: \.name)
                        ////                            TableColumn("Category", value: \.category)
                        //                            TableColumn("ID") {
                        //                                policy in
                        //                                Text(String(policy.jamfId ?? 0))
                        //                            }
                        //                        }
                        //                        .onChange(of: sortOrder) { newOrder in
                        //                            networkController.allPoliciesConverted.sort(using: newOrder)
                        //                        }
                        
                        Button("Export Text") {
                            exporting = true
                            print("Export text pressed")
//                            print(text)
                        }
                        .fileExporter(
                            isPresented: $exporting,
                            document: document,
                            contentType: .plainText
                        ) { result in
                            switch result {
                            case .success(let file):
                                print("File:\(file) has exported")
                            case .failure(let error):
                                print(error)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    }
                    .padding()
                    .border(.blue)
//                }
            } else {
                Spacer()
                VStack(alignment: .leading) {
                    Text("No usage tasks performed yet\n")
                    Text("Select:\n")
                    Text("Packages/Package Usage\n").fontWeight(.bold)
                    Text("or:\n")
                    Text("Scripts/Script Usage").fontWeight(.bold)
                }
                .padding()
            
               
                .font(.system(size: 22))
                Spacer()
            }
            }
        }
    }
    
    
    
//    let id = UUID()
//    var jamfId: Int
//    var name: String
//    @Published var allComputerRecordsInit: ComputerGroupMembers = ComputerGroupMembers(computer: ComputerMember(id: 0, name: "") )

    
//    var id = UUID()
//    let jamfId: Int?
//    let name: String?
//    let enabled: Bool?
//    let trigger: String?
//    let triggerCheckin, triggerEnrollmentComplete, triggerLogin, triggerLogout: Bool?
//    let triggerNetworkStateChanged, triggerStartup: Bool?
//    let triggerOther, frequency: String?
//    let locationUserOnly: Bool?
//    let targetDrive: String?
//    let offline: Bool?
//        let category: Category?
//    //    let dateTimeLimitations: DateTimeLimitations?
//    //    let networkLimitations: NetworkLimitations?
//    //    let overrideDefaultSettings: OverrideDefaultSettings?
//    let networkRequirements: String?
//    //    let site: Category?
//    let mac_address: String?
//    let ip_address: String?
//    let payloads: String?
//    
}
