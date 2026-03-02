import SwiftUI

struct ComputerActionView: View {
    
    var selectedResourceType = ResourceType.computerBasic
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    
    @State var server: String
    @State var computers: [Computer] = []
    @State var computer: Computer? = nil
    @State var url: URL? = nil
    @State private var searchText = ""
    
    @State var computersBasic: [ComputerBasicRecord] = []
    
    @State var currentDetailedPolicy: PoliciesDetailed? = nil
    
    //              ################################################################################
    //              Selections
    //              ################################################################################
    
    @State var selectionComp = Set<Computer>()

    @State var selection: ComputerBasicRecord = ComputerBasicRecord(id: 0, name: "", managed: false, username: "", model: "", department: "", building: "",macAddress: "", udid: "", serialNumber: "", reportDateUTC: "", reportDateEpoch: 0)
     
    
    @State  var selectionCategory: Category = Category(jamfId: 0, name: "")

    @State  var selectionDepartment: Department = Department(jamfId: 0, name: "")
    
    
    @State var showDetailScreen = true
    
    @State private var showingWarning = false

    
    var body: some View {
        
        VStack(alignment: .leading) {
            // header
            HStack {
                VStack(alignment: .leading) {
                    Text("Computers").font(.title).fontWeight(.semibold)
                    Text("Browse and act on computer records").font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: {
                        networkController.connect(server: server,resourceType: ResourceType.computer, authToken: networkController.authToken)
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding([.top, .horizontal])

            if networkController.allComputersBasic.computers.count > 0 {
                NavigationView {
                    VStack(alignment: .leading, spacing: 10) {

#if os(macOS)
                        Section(header: Text("All Computers").bold().padding(.horizontal)) {
                            // card-like list
                            VStack {
                                List(searchResults, id: \.self, selection: $selection) { computer in
                                    NavigationLink(destination: ComputersBasicDetailedView(server: server, computer: computer, selection: $selection)) {
                                        HStack {
                                            Image(systemName: "desktopcomputer")
                                            Text(computer.name ).font(.system(size: 12.0)).foregroundColor(.blue)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                                .searchable(text: $searchText)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)).shadow(radius: 1))
                            .frame(minHeight: 200)
                        }
#else
                        VStack {
                            List(searchResults, id: \.self) { computer in
                                NavigationLink(destination: ComputersBasicDetailedView(server: server, computer: computer)) {
                                    HStack {
                                        Image(systemName: "desktopcomputer")
                                        Text(computer.name ).font(.system(size: 12.0)).foregroundColor(.blue)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            .searchable(text: $searchText)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemBackground)).shadow(radius: 1))
                        .frame(minHeight: 200)
#endif
                    }
                    .frame(width: 400, alignment: .leading)
                }
            } else {
                ProgressView {
                    Text("Loading data")
                        .font(.title)
                        .progressViewStyle(.horizontal)
                }
                .padding()
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("\(networkController.allComputersBasic.computers.count) total computers")
            }
            .padding(.horizontal)

            Divider()

            // Actions card
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        showingWarning = true
                        progress.showProgress()
                        progress.waitForABit()
                        networkController.processDeleteComputers(selection: selectionComp, server: server, authToken: networkController.authToken, resourceType: ResourceType.policies)
                    }) {
                        Text("Delete Selection")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .alert(isPresented: $showingWarning) {
                        Alert(title: Text("Caution!"), message: Text("This action will delete data.\n Always ensure that you have a backup!"), dismissButton: .default(Text("I understand!")))
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)).shadow(radius: 1))
            .padding([.horizontal, .bottom])

            Divider()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 250)), GridItem(.flexible())]) {

                HStack {
                    Picker(selection: $selectionDepartment, label: Text("Department:").bold()) {
                        Text("").tag("") //basically added empty tag and it solve the case
                        ForEach(networkController.departments, id: \.self) { department in
                            Text(String(describing: department.name))
                        }
                    }

                    Button(action: {
                        networkController.updateComputerDepartment(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, departmentName: selectionDepartment.name, computerID: String(describing: selection.id))
                        progress.showProgress()
                        progress.waitForABit()
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
            .padding()

            Divider()

            if progress.showProgressView == true {
                ProgressView {
                    Text("Processing")
                        .padding()
                }
            } else {
                Text("")
            }
        }
        .onAppear {
            if networkController.allComputersBasic.computers.count == 0 {
                Task {
                    try await networkController.getComputersBasic(server: server,authToken: networkController.authToken)
                }
            }
        }
    }
    
    var searchResults: [ComputerBasicRecord] {
        
        let allComputers = networkController.allComputersBasic.computers
        let allComputersArray = Array (allComputers)
        
        if searchText.isEmpty {
            return networkController.allComputersBasic.computers.sorted { $0.name < $1.name }
        } else {
            print("Search Added")
            return allComputersArray.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
    
    func doBatchProcess(item: String) {
        
        //        let selectionArray = Array (arrayLiteral: $selection)
        //        networkController.processComputersSelected(selectionConverted: selectionArray, operation: NetBrain.downloadFileAsync(url: url!,username: username, password: password) { (path, error) in})
        
        //        func processComputersSelected(selectionConverted: [Computer], operation:(String)->Void) {
        //        (networkController.downloadFileAsync)->Void)
        print("Selection is:\(String(describing: item))")
        print("deleting item:\(item) !!!!!!!!!!!!!!!!!!!!!!")
    }
    
    func hideDetailScreen() {
        showDetailScreen = false
    }
}
