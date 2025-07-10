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
    @State var computers: [Computer] = []
    @State var selection: Computer = Computer(id: 0, name: "")
    @State var departments: [Department] = []
    @State private var searchText = ""
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.departments.count > 0 {
                
                NavigationView {
                    
#if os(macOS)
                    List(searchResults, id: \.self, selection: $selection) { department in
                        NavigationLink(destination: DepartmentsDetailedView(server: server, department: department)) {
                            
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(department.name ).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .blue : .blue)
                            }
                            .background(Color.gray.opacity(0.05))
                            .foregroundColor(.blue)
                            .navigationTitle("Departments")
                            .frame(width: 600, alignment: .leading)


                        }
                    }
                        .frame(minWidth: 400, maxWidth: .infinity)
#endif
                    Text("\(networkController.departments.count) total departments")
                }
                .navigationViewStyle(DefaultNavigationViewStyle())
                .searchable(text: $searchText)

            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
//                .padding()
//                Spacer()
            }
        }

        .frame(minWidth: 300, minHeight: 100, alignment: .center)

        .onAppear {
            print("Departments View appeared. Running onAppear")
            print("\(selectedResourceType) View appeared - connecting")
            print("Searching for \(selectedResourceType)")
            handleConnect(resourceType: ResourceType.department)
        }
    }
    
    var searchResults: [Department] {
        
        let allDepartments = networkController.departments
        let allDepartmentsArray = Array (allDepartments)
        
        if searchText.isEmpty {
            // print("Search is empty")
            return networkController.departments
        } else {
            print("Search Added")
            return allDepartmentsArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
 
    
    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        networkController.connect(server: server,resourceType: ResourceType.department, authToken: networkController.authToken)
    }
    
    
    //struct DepartmentsView_Previews: PreviewProvider {
    //    static var previews: some View {
    //        DepartmentsView()
    //    }
    
    
}
