import SwiftUI

struct ComputerBasicView: View {
    
    var selectedResourceType: ResourceType
    @State var server: String
    @State var user: String
    @State var password: String
    @State var computers: [Computer] = []
    @State var selection: [Computer] = []
    
    @EnvironmentObject var networkController: NetBrain
    
    @State var currentDetailedPolicy: PolicyCodable? = nil
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.computers.count > 0 {
                NavigationView {
                    List(networkController.computers, selection: $selection) { computer in
                        NavigationLink(destination: ComputerDetailedView(server: server, user: user,password: password, computer: computer)) {
                            
                            HStack {
                                Image(systemName: "desktopcomputer")
                                Text(computer.name).font(.system(size: 12.0)).foregroundColor(.black)
//                              Text(computer.id).font(.system(size: 18.0)).foregroundColor(.black)
//                                Image(systemName: "star")
                            }

                            
                        }
                    }
                    Text("\(networkController.computers.count) total computers")

                }
                .navigationViewStyle(DefaultNavigationViewStyle())
            } else {
                ProgressView {
                    Text("Loading")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                .padding()
                Spacer()
            }
        }
        .frame(width: 800, height: 500, alignment: .leading)
        .onAppear {
            print("ComputerView appeared. Running onAppear")
            print("\(selectedResourceType) View appeared - connecting")
            print("Searching for \(selectedResourceType)")
            
            handleConnect(resourceType: ResourceType.computer)
            computers = networkController.computers
            
            print(computers)
            print("Cheese")
        }
    }

    func handleConnect(resourceType: ResourceType) {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
        networkController.connect(to: server, as: user, password: password, resourceType: ResourceType.computer)
    }
}





//}

//struct TestView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestView()
//    }
//}
