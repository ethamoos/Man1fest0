
//
//  CategoriesDetailed.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/09/2023.
//

import SwiftUI

struct CategoriesDetailedView: View {
    
    var server: String
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    
    @State private var selection: Category? = nil
    
    @State var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    @State var category: Category
    
    @State private var categories: [ Category ] = []
    
    @State var categoryName = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 7.0) {
            
            Text("Category Name:\(String(describing:category.name ))")
            Text("Jamf ID:\(String(describing:category.jamfId ))")
            
            //              ################################################################################
            //              UPDATE NAME
            //              ################################################################################
            
            Divider()
            
            VStack(alignment: .leading) {
                
                VStack(alignment: .leading) {
                    
                    Text("Update name:").fontWeight(.bold)
                    
                    LazyVGrid(columns: layout.fourColumns, spacing: 20) {
                        
                        HStack {
                            
                            TextField(String(describing:category.name ), text: $categoryName)
                            //                                  TextField("Filter", text: $computerGroupFilter)
                            
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updateCategoryName(server: server, authToken: networkController.authToken, resourceType: ResourceType.categoryDetailed, categoryID: String(describing:category.jamfId ), categoryName: categoryName, updatePressed: true)
                                networkController.separationLine()
                                print("Renaming Category:\(categoryName)")
                            }) {
                                Text("Rename")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        
                        Button(action: {
                            print("Refresh Categories")
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    
                    //  ################################################################################
                    //  Category picker
                    //  ################################################################################
                    
                    
                    
//                    LazyVGrid(columns: layout.columnsFlex) {
//                        
//                        HStack {
//                            Picker(selection: $selectedCategory, label: Text("Category").fontWeight(.bold)) {
//                                ForEach(networkController.categories, id: \.self) { category in
//                                    Text(String(describing: category.name))
//                                        .tag(category as Category?)
//                                        .tag(selectedCategory as Category?)
//                                }
//                            }
//                            .onAppear {
//                                if networkController.categories.isEmpty != true {
//                                    print("Setting categories picker default")
//                                    selectedCategory = networkController.categories[0] }
//                            }
//                        }
//                    }
                    
                    if progress.showProgressView == true {
                        
                        ProgressView {
                            Text("Processing")
                                .padding()
                        }
                        
                    } else {
                        Text("")
                    }
                    
                    Button(action: {
                        print("Delete")
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "delete.left.fill")
                            Text("Delete")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    Spacer()
                }
            }
        }
        .padding()
        .textSelection(.enabled)
    }
}
