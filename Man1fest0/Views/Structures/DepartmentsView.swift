//
//  DepartmentsView.swift
//  Man1fest0
//
//  Created by Amos Deane on 28/09/2023.
//

import SwiftUI

struct DepartmentsView: View {
    
    
    @EnvironmentObject var networkController: NetBrain
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var progress: Progress
    
    var selectedResourceType: ResourceType
    @State var server: String
    @State var selection: Department? = nil

    @State var departments: [Department] = []
    @State private var searchText = ""
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.departments.count > 0 {
                
                NavigationView {
                    
                #if os(macOS)
                    // macOS: show a small search field above the list
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Search departments", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding([.top, .horizontal], 6)

                        List(searchResults, selection: $selection) { department in
                            NavigationLink(destination: DepartmentsDetailedView(server: server, department: department)) {
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(department.name ).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .blue : .blue)
                            }
                            .background(Color.gray.opacity(0.05))
                            .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(minWidth: 300, maxWidth: .infinity)
                #else
                    List(searchResults, id: \.self, selection: $selection) { department in
                        NavigationLink(destination: DepartmentsDetailedView(server: server, department: department)) {
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(department.name ).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .blue : .blue)
                            }
                            .background(Color.gray.opacity(0.05))
                            .foregroundColor(.blue)
                        }
                    }
                    .searchable(text: $searchText)
                #endif
                    
                    
                    Text("\(networkController.departments.count) total departments")
                }
                .navigationViewStyle(DefaultNavigationViewStyle())
#if os(macOS)
//                .searchable(text: $searchText)
#endif

            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
            }
        }

        .frame(minWidth: 300, minHeight: 100, alignment: .leading)

        .onAppear {
            print("Departments View appeared. Running onAppear")

            
            print("Departments View appeared. Running getAllDepartments")
                    
                            Task {
                                try await networkController.getAllDepartments()
                            }
            
        }
    }
    
    var searchResults: [Department] {
        let allDepartments = networkController.departments
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return allDepartments
        }
        let lower = searchText.lowercased()
        return allDepartments.filter { $0.name.lowercased().contains(lower) }
    }
 
    
    //struct DepartmentsView_Previews: PreviewProvider {
    //    static var previews: some View {
    //        DepartmentsView()
    //    }
    
    
}
