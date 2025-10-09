//
//  CategoryView.swift
//  Man1fest0
//
//  Created by Amos Deane on 25/10/2023.
//

import SwiftUI

struct CategoriesView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var progress: Progress
    
    var selectedResourceType: ResourceType
    
    @State var server: String

    @State var computers: [Computer] = []
    @State var selection: Computer? = Computer(id: 0, name: "")
    @State private var searchText = ""

    @State var categories: [Category] = []
    @State var authToken = ""
    
    @EnvironmentObject var networkController: NetBrain
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.categories.count > 0 {
                
                NavigationView {
                    
                    List(searchResults, id: \.self, selection: $selection) { category in
                        
                        NavigationLink(destination: CategoriesDetailedView(server: server, category: category)) {
                            
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(category.name ).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .blue : .blue)
                            }
                            .textSelection(.enabled)
                            .background(Color.gray.opacity(0.05))
                            .foregroundColor(.blue)
#if os(macOS)
                            .navigationTitle("Categories")
#endif
                        }
                    }
                    .searchable(text: $searchText)
#if os(macOS)
                        .frame(minWidth: 300, maxWidth: .infinity)
#endif
                    Text("\(networkController.categories.count) total categories")
                }
                .navigationViewStyle(DefaultNavigationViewStyle())

            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                .padding()
            }
        }
        .frame(minWidth: 300, minHeight: 100, alignment: .leading)
        
        .onAppear {
            print("Categories View appeared. Running onAppear")
            Task {
                try await networkController.getCategories(server: server, authToken: networkController.authToken)
            }
        }
    }
    
    var searchResults: [Category] {
        
        let allCategories = networkController.categories
        let allCategoriesArray = Array (allCategories)
        
        if searchText.isEmpty {
            // print("Search is empty")
            return networkController.categories
        } else {
            print("Search Added")
            return allCategoriesArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
            
        }
    }
}


//struct CategoriesView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoriesView()
//    }
