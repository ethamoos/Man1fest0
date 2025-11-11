//
//  PackagesDetailView.swift
//  PackageTourist
//
//  Created by Amos Deane on 15/09/2022.
//

import SwiftUI

struct PackageDetailView: View {
    
    var package: Package
    var server: String
    
    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    //  ########################################################################################
    //  Selections
    //  ########################################################################################

    // Use jamfId-based selection for Category to avoid Picker tag/selection mismatches
    @State var selectedCategoryId: Int? = nil
    private var selectedCategory: Category? {
        networkController.categories.first(where: { $0.jamfId == selectedCategoryId })
    }
    
    @State private var showingWarning = false
    
    var body: some View {
        
        let currentPackage = networkController.packageDetailed

        VStack(alignment: .leading, spacing: 20) {
                        
            if currentPackage?.name != "" {
                Section(header: Text("Package Detail").bold()) {
                    
                    Text("Name:\t\t\(String(describing: currentPackage?.name ?? "") )")
                    Text("ID:\t\t\t\(String(describing: currentPackage?.id ?? 0) )")
                    Text("Filename:\t\(String(describing: currentPackage?.filename ?? "") )")
                    Text("Category:\t\(String(describing: currentPackage?.category ?? "") )")
                    Text("Info:\t\t\t\(String(describing: currentPackage?.info ?? "") )")
                    Text("Notes:\n\n\(String(describing: currentPackage?.notes ?? "") )")
                    Text("Priority:\t\t\(String(describing: currentPackage?.priority ?? 10) )")
                    Text("Fill Template:\t\(String(describing: currentPackage?.fillUserTemplate ?? false) )")
                    Text("Fill Users:\t\(String(describing: currentPackage?.fillExistingUsers ?? false) )")
                }
                
                Button(action: {
                    showingWarning = true
                    progress.showProgressView = true
                    progress.waitForABit()
                }) {
                    
                    HStack(spacing:10) {
                        Image(systemName: "delete.left.fill")
                        Text("Delete")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                }
                
                .alert(isPresented: $showingWarning) {
                    Alert(
                        title: Text("Caution!"),
                        message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                        primaryButton: .destructive(Text("I understand!")) {
                            // Code to execute when "Yes" is tapped
                            networkController.deletePackage( server: server, resourceType: ResourceType.package, itemID: String(describing: currentPackage?.id ?? 0), authToken: networkController.authToken)
                            
                            print("Yes tapped")
                        },
                        secondaryButton: .cancel()
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                //              ####################################################################
                //              CATEGORY
                //              ####################################################################
                
                    Divider()

                LazyVGrid(columns: layout.columnsFlex) {
                    HStack {
                        
                        Picker(selection: $selectedCategoryId, label: Text("Category").fontWeight(.bold)) {
                            Text("No category selected").tag(nil as Int?)
                            ForEach(networkController.categories, id: \.self) { category in
                                Text(String(describing: category.name))
                                    .tag(category.jamfId as Int?)
                            }
                        }
                        .onAppear {
                            if selectedCategoryId == nil {
                                selectedCategoryId = networkController.categories.first?.jamfId
                            }
                        }
                        
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                           
                            if let cat = selectedCategory {
                                networkController.updateCategory(server: server,authToken: networkController.authToken, resourceType: ResourceType.package, categoryID: String(describing: cat.jamfId), categoryName: String(describing: cat.name), updatePressed: true, resourceID: String(describing: currentPackage?.id ?? 0))
                            } else {
                                print("No category selected")
                            }

                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Update")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
            }
        }
        .multilineTextAlignment(.leading)
        .padding(30)
        .textSelection(.enabled)
        .frame(minWidth: 400, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    Color.black.opacity(0.4),
                    style: StrokeStyle()
                )
        )
        
        .onAppear() {
            Task {
                try await networkController.getDetailedPackage(server: server, authToken: networkController.authToken, packageID: String(describing: package.jamfId))
            }
            if networkController.categories.count <= 1 {
                print("No categories - fetching")
                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            }
        }
    }
}


//}

//struct PackagesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesDetailView()
//    }
//}
