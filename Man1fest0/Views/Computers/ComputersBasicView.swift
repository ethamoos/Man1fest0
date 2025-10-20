

import SwiftUI

struct ComputersBasicView: View {
    
//    var selectedResourceType = ResourceType.computerBasic
    
    @State var server: String
    @State var computersBasic: [ComputerBasicRecord] = []
    
    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################

    @EnvironmentObject var progress: Progress

    @EnvironmentObject var networkController: NetBrain
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    
    //  ########################################################################################
    //  Selections
    //  ########################################################################################
    
    @State var selection = Set<ComputerBasicRecord>()
//    @State var selection: ComputerBasicRecord

    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.allComputersBasic.computers.count > 0 {
                
                NavigationView {
#if os(macOS)
                    List(networkController.allComputersBasic.computers, id: \.self, selection: $selection) { computer in
//                        NavigationLink(destination: ComputersBasicDetailedView(server: server, computer: computer, selection: $selection)) {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text(computer.name).font(.system(size: 12.0))
                            }
                            .foregroundColor(.blue)
//                        }
                    }
#else
                    List(networkController.allComputersBasic.computers, id: \.self) { computer in
                        HStack {
                            Image(systemName: "apple.logo")
                            Text(computer.name).font(.system(size: 12.0))
                        }
                        .foregroundColor(.blue)
                    }
#endif
                    Text("\(networkController.computers.count) total computers")
                }

                .toolbar {
                    
                    Button(action: {
                        networkController.connect(server: server,resourceType: ResourceType.computer, authToken: networkController.authToken)
                        progress.showProgress()
                        progress.waitForABit()
                        print("Refresh")
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                }
                
                Text("\(networkController.computers.count) total computers")
                
                .navigationViewStyle(DefaultNavigationViewStyle())
            
            } else {
                
                ProgressView {
                    Text("Loading data")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                .padding()
                Spacer()
            }
        }
        
        .frame(minWidth: 200, minHeight: 100, alignment: .leading)
        
        .onAppear {
            
            networkController.refreshComputers()
            
//            if networkController.computers.count < 0 {
//                print("Fetching computers")
//                networkController.connect(server: server,resourceType: ResourceType.computer, authToken: networkController.authToken)
//            }
//            if networkController.computers.count < 0 {
//                print("Fetching basic computers")
//                //                networkController.allComputersBasic.computers
//            }
        }
    }
    
    func handleConnect(resourceType: ResourceType) async {
        print("Running handleConnect. resourceType is set as:\(resourceType)")
    }
}


//struct TestView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestView()
//    }
//}
