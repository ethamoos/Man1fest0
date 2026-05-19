import SwiftUI

struct ComputerBasicActionView: View {

        
        @State var server: String
        @State var computersBasic: [ComputerBasicRecord] = []
        @State private var searchText = ""
        @State private var computerGroupFilter: String = ""
        
        //  ########################################################################################
        //  EnvironmentObjects
        //  ########################################################################################
        
        @EnvironmentObject var progress: Progress
        
        @EnvironmentObject var networkController: NetBrain
        @EnvironmentObject var layout: Layout
        
        @State var currentDetailedPolicy: PoliciesDetailed? = nil
        
        @EnvironmentObject var xmlController: XmlBrain
        
        @EnvironmentObject var extensionAttributeController: EaBrain
        
        //  ########################################################################################
        //  Selections
        //  ########################################################################################
        
        @State private var selectionCompGroup: ComputerGroup? = nil
        @State var selection = Set<Int>()
        @State private var usernameToSet: String = ""
        @State private var showUsernameUpdateConfirm: Bool = false
        @State private var isUpdatingUsername: Bool = false
            // Rename tools for computers
            @State private var toolsNameAction: String = "removelast"
            @State private var toolsCountString: String = "1"
            @State private var toolsMatchString: String = ""
            @State private var toolsReplacementString: String = ""
                // Color name used for prominent disclosure chevron in rename tools
                @State private var renameDisclosureColorName: String = "blue"
        
        @State private var selectedEAName = ""
        @State private var eaValue = ""
        
        // Split the large view into smaller computed subviews so the compiler can type-check efficiently.
        var body: some View {
            VStack(alignment: .leading) {
                headerView
                listAndStatsView
                actionPanelView
            }
            .padding()
            .alert("Set username for selected computers?", isPresented: $showUsernameUpdateConfirm) {
                Button("Set") {
                    isUpdatingUsername = true
                    progress.showProgress()
                    progress.waitForABit()
                    let ids = selection.map { String($0) }
                    Task {
                        // TODO: implement actual username update for selected computers.
                        // For now refresh the list after a short delay to simulate work.
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        do {
                            try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                        } catch {
                            print("Failed to refresh computers after username update: \(error)")
                        }
                        progress.endProgress()
                        isUpdatingUsername = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will set the username attribute for the selected computers on the server. Continue?")
            }
        }
        private var headerView: some View {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Computers")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Browse and manage computers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    Task {
                        try await networkController.getComputersBasic(server: server,authToken: networkController.authToken)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    guard !selection.isEmpty else { return }
                    progress.showProgress()
                    progress.waitForABit()

                    let ids = selection.map { String($0) }
                    for id in ids {
                        layout.openURL(urlString: "\(server)/computers.html?id=\(id)&o=r", requestType: "computers")
                    }
                }) {
                    Image(systemName: "safari")
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 6)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.02)))
        }

        private var listAndStatsView: some View {
            Group {
                if networkController.allComputersBasic.computers.count > 0 {
                    NavigationView {
#if os(macOS)
                        // Use the computer's integer `id` for the List selection so it matches
                        // the `selection: Set<Int>` binding used elsewhere in this view.
                        List(searchResults, id: \.id, selection: $selection) { computer in
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundColor(.accentColor)
                                Text(computer.name)
                                    .font(.system(size: 13.0))
                            }
                            .padding(.vertical, 4)
                        }
                        .searchable(text: $searchText)
                        .listStyle(SidebarListStyle())
#else
                        List(searchResults, id: \.self) { computer in
                            HStack {
                                Image(systemName: "desktopcomputer")
                                    .foregroundColor(.accentColor)
                                Text(computer.name)
                                    .font(.system(size: 13.0))
                            }
                            .padding(.vertical, 4)
                        }
                        .searchable(text: $searchText)
#endif
                        Text("\(networkController.computers.count) total computers")
                    }

                    Text("\(networkController.computers.count) total computers")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
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
        }

        var actionPanelView: some View {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    progress.showProgress()
                    progress.waitForABit()
                    guard let compGroup = selectionCompGroup else { return }
                    Task {
                        xmlController.getGroupMembersXML(server: server, groupId: compGroup.id, authToken: networkController.authToken)
                        var attempts = 0
                        while xmlController.computerGroupMembersXML.isEmpty && attempts < 15 {
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            attempts += 1
                        }
                        if xmlController.computerGroupMembersXML.isEmpty {
                            print("Warning: did not receive group members XML in time; proceeding with whatever XML is available")
                        } else {
                            print("Got groupMembers XML")
                        }
                        let selectedRecords = Set(networkController.allComputersBasic.computers.filter { selection.contains($0.id) })
                        xmlController.addMultipleComputersToGroup(xmlContent: xmlController.computerGroupMembersXML,
                                                                  computers: selectedRecords,
                                                                  authToken: networkController.authToken,
                                                                  groupId: String(compGroup.id),
                                                                  resourceType: ResourceType.computerGroup,
                                                                  server: server)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                        Text("Add Selection To Group")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                HStack(spacing: 10) {
                    TextField("Filter", text: $computerGroupFilter)
                        .fixedSize()
                        .frame(minWidth: 160)
                    Picker(selection: $selectionCompGroup, label: Text("Group:").bold()) {
                        ForEach(networkController.allComputerGroups.filter({ computerGroupFilter.isEmpty ? true : $0.name.contains(computerGroupFilter) }), id: \.self) { group in
                            Text(group.name)
                                .tag(group as ComputerGroup?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .fixedSize()
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Update Extension Attribute")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Username to set", text: $usernameToSet)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                guard !selection.isEmpty else { return }
                                showUsernameUpdateConfirm = true
                            }) {
                                HStack {
                                    Image(systemName: "person.fill.questionmark")
                                    Text("Set Username for \(selection.count) computers")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(usernameToSet.isEmpty || selection.isEmpty || isUpdatingUsername)
                        }
                    }
                    .overlay(
                        Group {
                            if isUpdatingUsername {
                                ProgressView("Updating...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.windowBackgroundColor).opacity(0.85)))
                            }
                        }
                    )

                    // Use DisclosureGroup for the rename tools (with color picker in the label)
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Action", selection: $toolsNameAction) {
                                Text("Remove last chars").tag("removelast")
                                Text("Remove first chars").tag("removefirst")
                                Text("Replace last chars").tag("replacelast")
                                Text("Replace first chars").tag("replacefirst")
                                Text("Replace all occurrences").tag("replaceall")
                                Text("Add last characters").tag("addlast")
                                Text("Add first characters").tag("addfirst")
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: 8) {
                                if toolsNameAction == "removelast" || toolsNameAction == "replacelast" || toolsNameAction == "removefirst" || toolsNameAction == "replacefirst" {
                                    TextField("Count", text: $toolsCountString)
                                        .frame(width: 80)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                if toolsNameAction == "replacelast" || toolsNameAction == "replaceall" || toolsNameAction == "replacefirst" || toolsNameAction == "addlast" || toolsNameAction == "addfirst" {
                                    TextField("Replacement", text: $toolsReplacementString)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                if toolsNameAction == "replaceall" {
                                    TextField("Match", text: $toolsMatchString)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                Spacer()
                                Button(action: {
                                    let countInt = Int(toolsCountString) ?? 0
                                    progress.showProgress()
                                    progress.waitForABit()
                                    let ids = selection.map { String($0) }
                                    print("Run on Selected pressed. selection=\(selection) ids=\(ids)")

                                    Task {
                                        for id in ids {
                                            do {
                                                try await networkController.getDetailedComputer(userID: id)
                                            } catch {
                                                print("Failed to load detailed computer for id \(id): \(error)")
                                            }

                                            networkController.updateComputerNameLogical(server: server, authToken: networkController.authToken, resourceType: ResourceType.computerDetailed, computerID: id, action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)

                                            try? await Task.sleep(nanoseconds: 200_000_000)
                                        }
                                        do { try await networkController.getComputersBasic(server: server, authToken: networkController.authToken) } catch { print("Failed to refresh computers after rename: \(error)") }
                                        progress.endProgress()
                                    }
                                }) {
                                    Text("Run on Selected")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(selection.isEmpty)
                            }
                        }
                        .padding()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Rename Tools")
                                .font(.headline)
                            Spacer()
                            // Small inline menu to choose chevron color
                            Menu {
                                ForEach(colorOptions, id: \.self) { name in
                                    Button(action: { renameDisclosureColorName = name }) {
                                        HStack {
                                            Circle()
                                                .fill(colorForName(name))
                                                .frame(width: 10, height: 10)
                                            Text(name.capitalized)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(colorForName(renameDisclosureColorName))
                                        .frame(width: 12, height: 12)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                            }
                            .menuStyle(BorderlessButtonMenuStyle())
                        }
                    }

                    HStack {
                        Text("Extension Attribute:")
                        Picker("", selection: $selectedEAName) {
                            Text("Select...").tag("")
                            ForEach(extensionAttributeController.allComputerExtensionAttributesDict, id: \.self) { ea in
                                Text(ea.name).tag(ea.name)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("Value:")
                        TextField("EA Value", text: $eaValue)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: {
                        progress.showProgress()
                        progress.waitForABit()
                        let computerIds = Set(selection)
                        Task {
                            do {
                                try await extensionAttributeController.updateComputerEAValueMultipleComputers(
                                    server: server,
                                    authToken: networkController.authToken,
                                    computerIds: computerIds,
                                    extAttName: selectedEAName,
                                    updateValue: eaValue
                                )
                            } catch {
                                print("Failed to update EA: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Update EA Value for \(selection.count) computers")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(selectedEAName.isEmpty || selection.isEmpty)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Show a global processing spinner when the shared Progress controller
                // indicates work is in progress. Other action views use the same
                // pattern so the user sees consistent feedback.
                if progress.showProgressView == true {
                    ProgressView {
                        Text("Processing")
                            .padding()
                    }
                    .padding()
                }
            }
            // Attach the onAppear to the VStack (the returned view) rather than to
            // the conditional inside it. Attaching inside the `if` made the
            // compiler interpret the modifier as being applied to a control-flow
            // statement rather than a View, causing the error.
            .onAppear {
                if networkController.allComputersBasic.computers.count == 0 {
                    print("Fetching computers")
                    Task {
                        try await networkController.getComputersBasic(server: server,authToken: networkController.authToken)
                    }
                }
                Task {
                    try await networkController.getAllGroups(server: server, authToken: networkController.authToken)
                }
                if let first = networkController.allComputerGroups.first {
                    selectionCompGroup = first
                } else {
                    selectionCompGroup = nil
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
        
        // Color options available for prominent disclosure chevrons
        private var colorOptions: [String] {
            ["blue", "green", "red", "orange", "purple", "gray"]
        }

        private func colorForName(_ name: String) -> Color {
            switch name.lowercased() {
            case "blue": return .blue
            case "green": return .green
            case "red": return .red
            case "orange": return .orange
            case "purple": return .purple
            case "gray": return .gray
            default: return .accentColor
            }
        }
        

    //struct TestView_Previews: PreviewProvider {
    //    static var previews: some View {
    //        TestView()
    //    }
    //}

//}

}
