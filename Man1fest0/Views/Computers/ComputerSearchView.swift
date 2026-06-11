import SwiftUI

struct ComputerSearchView: View {
    var server: String

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    @State private var searchString: String = ""
    enum MatchMode: String, CaseIterable {
        case contains
        case startsWith
        var displayName: String { self == .contains ? "Contains" : "Starts With" }
    }
    @State private var matchMode: MatchMode = .contains
    @State private var caseSensitive: Bool = false
    @State private var selectedField: ComputerSearchField = .all

    private struct MatchedComputerPair: Identifiable {
        let computer: ComputerFull
        let isHighlighted: Bool
        var id: String {
            // Ensure we never return an empty id (Jamf sometimes returns an empty string).
            if let id = computer.general?.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return id
            }
            return UUID().uuidString
        }
    }

    // Sortable column types
    enum SortColumn: String {
        case name, id, serial, ip, user
        var displayName: String {
            switch self {
            case .name: return "Name"
            case .id: return "ID"
            case .serial: return "Serial"
            case .ip: return "IP"
            case .user: return "User"
            }
        }
    }

    // State for list management
    @State private var sortColumn: SortColumn = .name
    @State private var sortAscending: Bool = true
    @State private var currentFetchTask: Task<Void, Never>? = nil

    private func computeMatchedPairs() -> [MatchedComputerPair] {
        let detailed = networkController.allComputersDetailedFull
        let nonNil = detailed.compactMap { $0 }
        return nonNil.map { c in MatchedComputerPair(computer: c, isHighlighted: isComputerMatch(c)) }
    }

    @State private var matchedPairsState: [MatchedComputerPair] = []

    private func updateMatchingIDs() {
        let pairs = computeMatchedPairs()
        matchedPairsState = pairs
    }

    private var sortedAndFilteredPairs: [MatchedComputerPair] {
        let trimmed = searchString.trimmingCharacters(in: .whitespacesAndNewlines)
        let activeFilter = !trimmed.isEmpty || matchMode != .contains || caseSensitive || selectedField != .all
        let filtered = activeFilter ? matchedPairsState.filter { $0.isHighlighted } : matchedPairsState
        
        return filtered.sorted { a, b in
            let comp1 = a.computer
            let comp2 = b.computer
            let ascending = sortAscending
            
            switch sortColumn {
            case .name:
                let n1 = comp1.general?.name ?? ""
                let n2 = comp2.general?.name ?? ""
                return ascending ? (n1 < n2) : (n1 > n2)
            case .id:
                let i1 = comp1.general?.id ?? ""
                let i2 = comp2.general?.id ?? ""
                return ascending ? (i1 < i2) : (i1 > i2)
            case .serial:
                let s1 = comp1.general?.serial_number ?? ""
                let s2 = comp2.general?.serial_number ?? ""
                return ascending ? (s1 < s2) : (s1 > s2)
            case .ip:
                let ip1 = comp1.general?.ip_address ?? ""
                let ip2 = comp2.general?.ip_address ?? ""
                return ascending ? (ip1 < ip2) : (ip1 > ip2)
            case .user:
                let u1 = comp1.location?.username ?? comp1.general?.username ?? ""
                let u2 = comp2.location?.username ?? comp2.general?.username ?? ""
                return ascending ? (u1 < u2) : (u1 > u2)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search and filter controls
            HStack {
                TextField("Search...", text: $searchString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 320)

                Picker("Field", selection: $selectedField) {
                    ForEach(ComputerSearchField.allCases, id: \.self) { f in Text(f.displayName) }
                }
                .pickerStyle(MenuPickerStyle())

                Picker("Match", selection: $matchMode) {
                    ForEach(MatchMode.allCases, id: \.self) { m in Text(m.displayName) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 220)

                Toggle("Case", isOn: $caseSensitive).toggleStyle(SwitchToggleStyle())

                Button(action: {
                    // Cancel any running fetch
                    if let task = currentFetchTask {
                        task.cancel()
                        currentFetchTask = nil
                    } it
                    
                    progress.showProgress()
                    let fetchTask = Task {
                        do {
                            try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                            try await networkController.getAllComputersDetailedFull(server: server)
                            updateMatchingIDs()
                        } catch {
                            networkController.publishError(error, title: "Failed to fetch detailed inventory")
                        }
                        progress.waitForABit()
                        currentFetchTask = nil
                    }
                    currentFetchTask = fetchTask
                }) {
                    HStack { Image(systemName: "arrow.down.doc") ; Text("Fetch Full Inventory") }
                }
                .buttonStyle(.borderedProminent)

                // Cancel button visible during fetch
                if networkController.isFetchingDetailedComputers {
                    Button(action: {
                        if let task = currentFetchTask {
                            task.cancel()
                            currentFetchTask = nil
                        }
                        networkController.messageStore?.show("Fetch cancelled by user", level: .info)
                    }) {
                        HStack { Image(systemName: "stop.circle.fill") ; Text("Cancel") }
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                Spacer()
            }
            .padding()

            // Progress bar while fetching
            if networkController.isFetchingDetailedComputers {
                VStack(alignment: .leading, spacing: 8) {
                    let compProgress = networkController.detailedComputersProgress
                    let percentage = compProgress.expected > 0
                        ? Double(compProgress.loaded) / Double(compProgress.expected)
                        : 0.0
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Loading detailed computer inventory…")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Loaded \(compProgress.loaded) of \(compProgress.expected)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: percentage)
                                .tint(.blue)
                            HStack(spacing: 8) {
                                Text("\(Int(percentage * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                if compProgress.failedIDs.count > 0 {
                                    Text("Failed: \(compProgress.failedIDs.count)")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .padding([.leading, .trailing, .bottom])
            }

            // Finished progress header with optional retry button
            let compProgress = networkController.detailedComputersProgress
            if compProgress.expected > 0 && !networkController.isFetchingDetailedComputers {
                HStack(spacing: 12) {
                    Text("Loaded \(compProgress.loaded) of \(compProgress.expected)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    if compProgress.failedIDs.count > 0 {
                        Text("Failed: \(compProgress.failedIDs.count)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Button(action: {
                            let retryTask = Task {
                                await networkController.retryFailedComputerDetails(server: server)
                                updateMatchingIDs()
                            }
                            currentFetchTask = retryTask
                        }) {
                            Text("Retry Failed (\(compProgress.failedIDs.count))")
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                }
                .padding([.leading, .trailing, .bottom])
            }

            // Sortable list
            if sortedAndFilteredPairs.isEmpty {
                VStack {
                    if networkController.allComputersDetailedFull.isEmpty {
                        Text("No detailed computers loaded. Use 'Fetch Full Inventory' to begin.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text("No computers match the current filters.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    Spacer()
                }
            } else {
                List(sortedAndFilteredPairs, id: \.id) { pair in
                    // Only show navigation link if we have a valid Jamf ID
                    let jamfId = pair.computer.general?.id ?? ""
                    if !jamfId.isEmpty {
                        NavigationLink(destination: ComputersDetailedView(server: server, computerID: jamfId)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pair.computer.general?.name ?? "(no name)")
                                            .font(.headline)
                                        Text("ID: \(jamfId)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 16) {
                                    if let serial = pair.computer.general?.serial_number, !serial.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Serial")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text(serial)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    if let ip = pair.computer.general?.ip_address, !ip.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("IP")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text(ip)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    if let user = pair.computer.location?.username ?? pair.computer.general?.username, !user.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("User")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text(user)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        // Show disabled item if no ID available
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pair.computer.general?.name ?? "(no name)")
                                        .font(.headline)
                                    Text("ID: (unavailable)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                Spacer()
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.red)
                            }
                            
                            HStack(spacing: 16) {
                                if let serial = pair.computer.general?.serial_number, !serial.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Serial")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(serial)
                                            .font(.caption)
                                    }
                                }
                                
                                if let ip = pair.computer.general?.ip_address, !ip.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("IP")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(ip)
                                            .font(.caption)
                                    }
                                }
                                
                                if let user = pair.computer.location?.username ?? pair.computer.general?.username, !user.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("User")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(user)
                                            .font(.caption)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 8)
                        .opacity(0.5)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            
                print("Fetching required data for ComputersView")
                Task {
                    try await networkController.getComputersBasic(server: server,authToken: networkController.authToken)
                }
            
            
            // Load persisted sort preference
            let persistedSort = UserDefaults.standard.string(forKey: "computerListSortColumn") ?? SortColumn.name.rawValue
            if let col = SortColumn(rawValue: persistedSort) {
                sortColumn = col
            }
            sortAscending = UserDefaults.standard.bool(forKey: "computerListSortAscending") ?? true
            
            // prepare initial matched state
            matchedPairsState = computeMatchedPairs()

            // If we don't yet have detailed computer data, kick off an automatic
            // fetch so users see devices when they open this view. Respect any
            // existing fetch in progress.
            if networkController.allComputersDetailedFull.isEmpty && !networkController.isFetchingDetailedComputers {
                // If we don't have a basic list, fetch basics first.
                progress.showProgress()
                let fetchTask = Task {
                    do {
                        if networkController.allComputersBasic.computers.isEmpty {
                            try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                        }
                        try await networkController.getAllComputersDetailedFull(server: server)
                        // update matching state after fetch completes
                        updateMatchingIDs()
                    } catch {
                        networkController.publishError(error, title: "Failed to fetch detailed inventory")
                    }
                    progress.waitForABit()
                    currentFetchTask = nil
                }
                currentFetchTask = fetchTask
            }
        }
        .onChange(of: sortColumn) { newVal in
            UserDefaults.standard.set(newVal.rawValue, forKey: "computerListSortColumn")
        }
        .onChange(of: sortAscending) { newVal in
            UserDefaults.standard.set(newVal, forKey: "computerListSortAscending")
        }
        .onChange(of: searchString) { _ in updateMatchingIDs() }
        .onChange(of: selectedField) { _ in updateMatchingIDs() }
        .onChange(of: matchMode) { _ in updateMatchingIDs() }
        .onChange(of: caseSensitive) { _ in updateMatchingIDs() }
        .onReceive(networkController.$allComputersDetailedFull) { _ in updateMatchingIDs() }
        .onDisappear {
            // Cancel any running fetch when view is dismissed
            if let task = currentFetchTask {
                task.cancel()
                currentFetchTask = nil
            }
        }
    }

    // Simple matching helper
    private func isComputerMatch(_ c: ComputerFull) -> Bool {
        let trimmed = searchString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        func match(_ value: String?) -> Bool {
            guard let v = value else { return false }
            if caseSensitive {
                switch matchMode {
                case .contains: return v.contains(trimmed)
                case .startsWith: return v.hasPrefix(trimmed)
                }
            } else {
                let lhs = v.lowercased()
                let rhs = trimmed.lowercased()
                switch matchMode { case .contains: return lhs.contains(rhs); case .startsWith: return lhs.hasPrefix(rhs) }
            }
        }

        switch selectedField {
        case .all:
            return match(c.general?.name) || match(c.general?.serial_number) || match(c.general?.udid) || match(c.general?.ip_address) || match(c.general?.model) || match(c.location?.username) || match(c.location?.department) || match(c.location?.building)
        case .name:
            return match(c.general?.name)
        case .id:
            return match(c.general?.id)
        case .serial:
            return match(c.general?.serial_number)
        case .udid:
            return match(c.general?.udid)
        case .username:
            return match(c.location?.username ?? c.general?.username)
        case .department:
            return match(c.location?.department)
        case .building:
            return match(c.location?.building)
        case .model:
            return match(c.hardware?.model ?? c.general?.model)
        case .ip:
            return match(c.general?.ip_address)
        }
    }
}

enum ComputerSearchField: String, CaseIterable {
    case all, name, id, serial, udid, username, department, building, model, ip
    var displayName: String {
        switch self {
        case .all: return "All"
        case .name: return "Name"
        case .id: return "ID"
        case .serial: return "Serial"
        case .udid: return "UDID"
        case .username: return "Username"
        case .department: return "Department"
        case .building: return "Building"
        case .model: return "Model"
        case .ip: return "IP"
        }
    }
}

struct ComputerSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ComputerSearchView(server: "https://example.jamf.com")
            .environmentObject(NetBrain())
            .environmentObject(Progress())
            .environmentObject(Layout())
    }
}
