

import SwiftUI

struct ComputerView: View {
    
    var selectedResourceType: ResourceType
    
    @State var server: String
    @State var computers: [Computer] = []
    @State var selection: Computer = Computer(id: 0, name: "")
    
    @State var searchText = ""

    @EnvironmentObject var networkController: NetBrain
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.computers.count > 0 {
                
                NavigationView {
#if os(macOS)
                    List(searchResults, id: \.self, selection: $networkController.selectedSimpleComputer) { computer in

                            HStack {
                                Image(systemName: "apple.logo")
                                Text(computer.name).font(.system(size: 12.0))
                            }
                            .foregroundColor(.blue)
                    }
                    .searchable(text: $searchText)

#else
                        List(searchResults, id: \.self) { computer in
                            HStack {
                                Image(systemName: "apple.logo")
                                Text(computer.name).font(.system(size: 12.0))
                            }
                            .foregroundColor(.blue)
                        }
                        .searchable(text: $searchText)
#endif
                    Text("\(networkController.computers.count) total computers")
                }

            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                Spacer()
            }
        }
        
        #if os(macOS)
                .navigationTitle("Computers")
        #else
        
                .navigationViewStyle(DefaultNavigationViewStyle())

#endif

        .onAppear {
            print("ComputerView appeared. Running onAppear")

                        
            Task { try await networkController.getAllComputers() }
            
            computers = networkController.computers
            
//            ##########################################################
//            DEBUG
//            ##########################################################

//            print(computers)
        }
    }
    
    var searchResults: [Computer] {
        
        let allComputers = networkController.computers
        let allComputersArray = Array (allComputers)
        
        if searchText.isEmpty {
//            print("ComputerView Search is empty")
//            print(networkController.computers)
            return networkController.computers.sorted { $0.name < $1.name }
        } else {
            print("ComputerView Search Added")
            return allComputersArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}





//}

//struct TestView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestView()
//    }
//}
