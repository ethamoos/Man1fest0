//
//  GroupDetailView.swift
//  Man1fest0
//
//  Created by Amos Deane on 15/02/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct GroupDetailView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var layout: Layout
    
//    @State var selection: ComputerGroup
    @State var group: ComputerGroup
    @State var server: String
    // CSV import states
    @State private var showingFileImporter: Bool = false
    @State private var importMatches: [ComputerBasicRecord] = []
    @State private var importUnmatched: [String] = []
    @State private var importSelection: Set<Int> = []
    @State private var showingImportReview: Bool = false
    // CSV column-picker states
    @State private var importedRawRows: [[String]] = []
    @State private var csvHasHeader: Bool = true
    @State private var csvHeaders: [String] = []
    @State private var csvSelectedColumnIndex: Int = 0
    @State private var showingColumnPicker: Bool = false
    @State private var csvRowIncluded: [Bool] = []
    // Debug / fuzzy matching options
    @State private var importDebugLogging: Bool = false
    @State private var enableFuzzyMatching: Bool = true
    @State private var fuzzyThreshold: Double = 0.75
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if networkController.compGroupComputers.count >= 1 {
//                VStack {
                Text("Group Members for:\(group.name)").bold()
//                Section(header: Text("Group Members for group:\(group.name)").bold()) {
//                    
//                    Spacer()dis
                    
                    List( networkController.compGroupComputers, id: \.self ) { computer in
                        Text(String(describing: computer.name))
                    }
//                }

                // Open in Browser button (matches style used in ScriptsDetailView & ComputerExtAttDetailView)
                HStack {
//                    Spacer()
                    Button(action: {
                        let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                        var base = trimmedServer
                        if base.hasSuffix("/") { base.removeLast() }
                        // Construct Jamf UI URL for this group
                        let uiURL =
                        "\(base)/staticComputerGroups.html?id=\(group.id)&o=r"
                        print("Opening group UI URL: \(uiURL)")
                        layout.openURL(urlString: uiURL)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                            Text("Open in Browser")
                        }
                    }
                    .help("Open this group in the Jamf web interface in your default browser.")
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 6)
                    Button(action: {
                        showingFileImporter = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down.on.square")
                            Text("Import CSV")
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 6)
//                    Spacer()
                }
                .padding()
                .textSelection(.enabled)
                
            } else {
                Text("No members found")
            }
            
//            Spacer()
        
                
        }
        .onAppear {
            Task {
                await runGetGroupMembers(selection: group, authToken: networkController.authToken)
            }
        }
        // File importer for CSV
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                handleImportedFile(url: url)
            case .failure(let err):
                print("CSV import failed: \(err)")
            }
        }
        // Column picker sheet shown after importing a CSV so the user can choose which
        // column contains the identifier (serial/name/etc.). This mirrors the UX in ComputersBasicTableView.
        .sheet(isPresented: $showingColumnPicker) {
            VStack(alignment: .leading) {
                HStack {
                    Toggle("Has header row", isOn: $csvHasHeader)
                        .onChange(of: csvHasHeader) { newVal in
                            // Recompute headers/inclusion flags
                            if newVal {
                                csvHeaders = importedRawRows.first ?? []
                                csvRowIncluded = Array(repeating: true, count: max(0, importedRawRows.count - 1))
                            } else {
                                csvHeaders = []
                                csvRowIncluded = Array(repeating: true, count: importedRawRows.count)
                            }
                            csvSelectedColumnIndex = 0
                        }
                    Spacer()
                }
                .padding()

                // Column picker
                HStack {
                    Text("Identifier column:")
                    Picker("Column", selection: $csvSelectedColumnIndex) {
                        let maxCols = importedRawRows.map { $0.count }.max() ?? 1
                        ForEach(0..<max(1, maxCols), id: \.self) { idx in
                            if csvHasHeader && idx < csvHeaders.count {
                                Text(csvHeaders[idx]).tag(idx)
                            } else {
                                Text("Column \(idx)").tag(idx)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    Spacer()
                }
                .padding([.leading, .trailing])

                // Debug and fuzzy matching options
                HStack(spacing: 12) {
                    Toggle("Debug logging", isOn: $importDebugLogging)
                    Toggle("Fuzzy matching", isOn: $enableFuzzyMatching)
                    if enableFuzzyMatching {
                        HStack {
                            Text(String(format: "Threshold: %.2f", fuzzyThreshold))
                            Slider(value: $fuzzyThreshold, in: 0.4...0.95, step: 0.01)
                                .frame(maxWidth: 200)
                        }
                    }
                    Spacer()
                }
                .padding([.leading, .trailing])

                // Preview rows with toggles to include/exclude
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        let previewRows = csvHasHeader ? Array(importedRawRows.dropFirst()) : importedRawRows
                        ForEach(0..<previewRows.count, id: \.self) { idx in
                            HStack {
                                Toggle(isOn: Binding(get: {
                                    if idx < csvRowIncluded.count { return csvRowIncluded[idx] }
                                    return true
                                }, set: { newVal in
                                    if idx >= csvRowIncluded.count {
                                        csvRowIncluded.append(contentsOf: Array(repeating: true, count: idx - csvRowIncluded.count + 1))
                                    }
                                    csvRowIncluded[idx] = newVal
                                })) {
                                    let row = previewRows[idx]
                                    let display = csvSelectedColumnIndex < row.count ? row[csvSelectedColumnIndex] : row.joined(separator: ",")
                                    Text(display).lineLimit(1).font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                }

                HStack {
                    Spacer()
                    Button("Cancel") { showingColumnPicker = false }
                    Button("Run Match") {
                        // Generate tokens from selected column and included rows, then run match
                        var tokens: [String] = []
                        let previewRows = csvHasHeader ? Array(importedRawRows.dropFirst()) : importedRawRows
                        for (i, row) in previewRows.enumerated() {
                            if i < csvRowIncluded.count && !csvRowIncluded[i] { continue }
                            let cell = csvSelectedColumnIndex < row.count ? row[csvSelectedColumnIndex] : row.joined(separator: ",")
                            let trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty { tokens.append(trimmed) }
                        }
                        showingColumnPicker = false
                        parseTokensAndMatch(tokens: tokens)
                    }
                    .disabled(importedRawRows.isEmpty)
                }
                .padding()
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        // Review sheet to show matches and allow selection
        .sheet(isPresented: $showingImportReview) {
            VStack(alignment: .leading) {
                Text("Import review — matched computers")
                    .font(.headline)
                    .padding()

                // Debug helper: print current matches/selection when sheet appears
                .onAppear {
                    if importDebugLogging {
                        print("[ImportReview.sheet.onAppear] importMatches=\(importMatches.count) importSelection=\(importSelection.count) importUnmatched=\(importUnmatched.count)")
                    }
                }

                if importDebugLogging {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Debug: matched \(importMatches.count) items, selected \(importSelection.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // Show selected IDs and a short preview of matched records for on-screen verification
                        Text("Selected IDs: \(Array(importSelection).sorted())")
                            .font(.caption2)
                            .foregroundColor(.red)
                        // Preview first 12 matched items with id:name to help visually confirm mapping
                        let preview = Array(importMatches.prefix(12))
                        ForEach(preview, id: \.id) { c in
                            Text("\(c.id): \(c.name)")
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding([.leading, .bottom])
                }

                if importMatches.isEmpty {
                    Text("No matches found in inventory for provided CSV rows.")
                        .padding()
                } else {
                    List(importMatches, id: \.id) { comp in
                        HStack {
                            Toggle(isOn: Binding(get: { importSelection.contains(comp.id) }, set: { newVal in
                                if newVal { importSelection.insert(comp.id) } else { importSelection.remove(comp.id) }
                            })) {
                                VStack(alignment: .leading) {
                                    Text(comp.name)
                                    Text("Serial: \(comp.serialNumber)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                if !importUnmatched.isEmpty {
                    Divider()
                    Text("Unmatched rows")
                        .font(.subheadline)
                        .padding([.leading, .top])
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(importUnmatched, id: \.self) { row in
                                Text(row).font(.caption).foregroundColor(.secondary)
                            }
                        }.padding()
                    }.frame(maxHeight: 200)
                }

                HStack {
                    Spacer()
                    Button("Cancel") { showingImportReview = false }
                    Button("Add Selected to Group") {
                        showingImportReview = false
                        Task {
                            await networkController.processAddComputersToGroupAsync(selection: Set(importSelection), server: server, authToken: networkController.authToken, resourceType: .computerGroup, computerGroup: group)
                            await runGetGroupMembers(selection: group, authToken: networkController.authToken)
                        }
                    }
                    .disabled(importSelection.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .frame(minWidth: 400, minHeight: 300)
        }
        .padding()
        .textSelection(.enabled)
    }
    func runGetGroupMembers(selection: ComputerGroup, authToken: String) async {
        
        let mySelection = String(describing: selection.name)
        
        do {
            try await networkController.getGroupMembers(server: server, name: mySelection)
        } catch {
            print("Error getting GroupMembers")
            print(error)
        }
        xmlController.getGroupMembersXML(server: server, groupId: selection.id, authToken: networkController.authToken)
    }

    // MARK: - CSV import helpers
    private func handleImportedFile(url: URL) {
        do {
            // For file URLs returned by the system fileImporter on macOS, we may need
            // to call startAccessingSecurityScopedResource() to get permission to read.
            var didStart = false
            #if os(macOS)
            didStart = url.startAccessingSecurityScopedResource()
            #endif
            defer {
                #if os(macOS)
                if didStart { url.stopAccessingSecurityScopedResource() }
                #endif
            }

            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                print("Unable to decode CSV file as text")
                return
            }
            // Parse CSV into raw rows and show the column-picker so user can pick the identifier column
            let raw = parseContentToRawRows(content: content)
            if raw.isEmpty {
                print("Parsed CSV contains no rows")
                return
            }
            DispatchQueue.main.async {
                self.importedRawRows = raw
                if self.csvHasHeader {
                    self.csvHeaders = raw.first ?? []
                    self.csvRowIncluded = Array(repeating: true, count: max(0, raw.count - 1))
                } else {
                    self.csvHeaders = []
                    self.csvRowIncluded = Array(repeating: true, count: raw.count)
                }
                self.csvSelectedColumnIndex = 0
                self.showingColumnPicker = true
            }
        } catch {
            // If reading failed due to permissions, give a clearer log message.
            print("Failed to read CSV file: \(error)")
            // On macOS, advise the user to grant read permission in Finder (or choose a file in Downloads).
        }
    }

    // Normalize tokens/serials: lowercase + remove non-alphanumeric characters
    private func normalizeToken(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let filtered = s.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered)).lowercased()
    }

    // Remove invisible/control characters (BOM, zero-width spaces, etc.) and trim
    private func sanitizeToken(_ s: String) -> String {
        let forbidden: [Unicode.Scalar] = ["\u{FEFF}", "\u{200B}", "\u{200C}", "\u{200D}", "\u{2060}"]
        let filteredScalars = s.unicodeScalars.filter { sc in
            if CharacterSet.whitespacesAndNewlines.contains(sc) { return true }
            if CharacterSet.controlCharacters.contains(sc) { return false }
            if forbidden.contains(sc) { return false }
            return true
        }
        let filtered = String(String.UnicodeScalarView(filteredScalars))
        return filtered.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func parseCSVAndMatch(content: String) {

        var matches: [ComputerBasicRecord] = []
        var unmatched: [String] = []
        var selectedIDs: Set<Int> = []

        // create quick-access arrays to reduce repeated property lookups
        let basicList = networkController.allComputersBasic.computers
        let altBasic = networkController.computersBasic // legacy response struct

        // split on newlines and process each row
        let rows = content.components(separatedBy: CharacterSet.newlines)
        for raw in rows {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // split columns and trim quotes/spaces
            let columns = trimmed.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \t\"'")) }
            let candidates = columns.filter { !$0.isEmpty }
            if candidates.isEmpty { continue }

            var rowMatched = false

            // Try each candidate column (serial, name, etc.) to find matches
            for candidate in candidates {
                let tokenRaw = candidate
                let token = sanitizeToken(tokenRaw)
                let tokenLower = token.lowercased()
                let tokenNorm = normalizeToken(token)

                // 1) Try to match by serial number exactly (case-insensitive)
                if let found = basicList.first(where: { $0.serialNumber.lowercased() == tokenLower || normalizeToken($0.serialNumber) == tokenNorm }) {
                    if !matches.contains(where: { $0.id == found.id }) {
                        matches.append(found)
                        selectedIDs.insert(found.id)
                    }
                    rowMatched = true
                    break
                }

                // 2) Try exact name match
                if let found = basicList.first(where: { $0.name.lowercased() == tokenLower || normalizeToken($0.name) == tokenNorm }) {
                    if !matches.contains(where: { $0.id == found.id }) {
                        matches.append(found)
                        selectedIDs.insert(found.id)
                    }
                    rowMatched = true
                    break
                }

                // 3) Try matching against legacy `computersBasic` response (different struct)
                if let legacy = altBasic.first(where: { ($0.serial_number.lowercased() == tokenLower) || normalizeToken($0.serial_number) == tokenNorm || ($0.name?.lowercased() == tokenLower) }) {
                    // find corresponding ComputerBasicRecord by jamfId/name/serial
                    if let mapped = basicList.first(where: { $0.id == legacy.jamfId || $0.serialNumber.lowercased() == legacy.serial_number.lowercased() || $0.name.lowercased() == (legacy.name ?? "").lowercased() }) {
                        if !matches.contains(where: { $0.id == mapped.id }) {
                            matches.append(mapped)
                            selectedIDs.insert(mapped.id)
                        }
                        rowMatched = true
                        break
                    }
                }

                // 4) Broader partial matching: collect all candidates (not just first)
                let partialMatches = basicList.filter { comp in
                    let nameLower = comp.name.lowercased()
                    let serialLower = comp.serialNumber.lowercased()
                    let nameNorm = normalizeToken(comp.name)
                    let serialNorm = normalizeToken(comp.serialNumber)

                    // substring match in either direction
                    if nameLower.contains(tokenLower) || tokenLower.contains(nameLower) { return true }

                    // normalized substring match for serials/names (handles punctuation/prefixes)
                    if nameNorm.contains(tokenNorm) || tokenNorm.contains(nameNorm) { return true }

                    // prefix match on any word in the name (handles missing prefixes)
                    let nameWords = nameLower.split(separator: " ").map { String($0) }
                    if nameWords.contains(where: { $0.hasPrefix(tokenLower) }) { return true }

                    // token may be a prefix of the full name
                    if nameLower.hasPrefix(tokenLower) || tokenLower.hasPrefix(nameLower) { return true }

                    // allow serial substring matches too (user may paste partial serial)
                    if serialLower.contains(tokenLower) || tokenLower.contains(serialLower) { return true }
                    if serialNorm.contains(tokenNorm) || tokenNorm.contains(serialNorm) { return true }

                    return false
                }

                if !partialMatches.isEmpty {
                    for found in partialMatches {
                        if !matches.contains(where: { $0.id == found.id }) {
                            matches.append(found)
                            selectedIDs.insert(found.id)
                        }
                    }
                    rowMatched = true
                    break
                }
            }

            if !rowMatched {
                // add the first non-empty token for display in unmatched list
                if let firstToken = candidates.first {
                    unmatched.append(firstToken)
                }
            }
        }

        // Update published state on main actor (use DispatchQueue.main.async to be explicit)
        if importDebugLogging {
            print("[parseCSVAndMatch] Updating UI: matches=\(matches.count), unmatched=\(unmatched.count), selectedIDs=\(selectedIDs.count)")
        }
        DispatchQueue.main.async {
            self.importMatches = matches
            self.importUnmatched = unmatched

            // Build selection defensively using extractor so we tolerate different record shapes
            var sel = Set<Int>()
            for comp in matches {
                if let id = self.extractIntID(from: comp) {
                    sel.insert(id)
                } else {
                    if self.importDebugLogging { print("DEBUG: could not extract id for matched comp (parseCSVAndMatch): \(comp)") }
                }
            }
            self.importSelection = sel
            if self.importDebugLogging { print("Updating UI: selectedIDs=\(sel.count) -> \(sel)") }
            self.showingImportReview = true
        }
    }

    // Parse CSV text into raw rows (handling quoted values)
    private func parseContentToRawRows(content: String) -> [[String]] {
        // Normalize newlines
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var rawRows: [[String]] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }

            var columns: [String] = []
            var current = ""
            var insideQuotes = false
            for ch in trimmedLine {
                if ch == Character("\"") {
                    insideQuotes.toggle()
                    continue
                }
                if ch == Character(",") && !insideQuotes {
                    columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
            rawRows.append(columns)
        }

        return rawRows
    }

    // Levenshtein distance (iterative, O(n*m) )
    private func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        let n = a.count
        let m = b.count
        if n == 0 { return m }
        if m == 0 { return n }
        var prev = Array(0...m)
        var cur = Array(repeating: 0, count: m + 1)
        for i in 1...n {
            cur[0] = i
            for j in 1...m {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j-1] + 1, prev[j-1] + cost)
            }
            prev = cur
        }
        return prev[m]
    }

    // Similarity ratio [0..1] = 1 - (levenshtein / maxLen)
    private func similarityRatio(lhs: String, rhs: String) -> Double {
        let la = lhs.count
        let lb = rhs.count
        if la == 0 && lb == 0 { return 1.0 }
        if la == 0 || lb == 0 { return 0.0 }
        let dist = levenshtein(lhs, rhs)
        let maxLen = max(la, lb)
        return 1.0 - (Double(dist) / Double(maxLen))
    }

    // Tolerant extractor: try to pull an Int id from a record of unknown concrete type
    // (works for ComputerBasicRecord and fallback via Mirror for other shapes).
    private func extractIntID(from comp: Any) -> Int? {
        // Fast path for expected type
        if let cb = comp as? ComputerBasicRecord { return cb.id }

        // Mirror-based fallback: inspect child labels for common id field names
        let m = Mirror(reflecting: comp)
        for child in m.children {
            guard let label = child.label?.lowercased() else { continue }
            if ["id", "jamfid", "computerid", "computer_id", "jamf_id", "jamfid"].contains(label) {
                if let i = child.value as? Int { return i }
                if let s = child.value as? String, let i = Int(s) { return i }
            }
        }

        // If comp is itself a primitive wrapped (e.g. Int/String), try casting directly
        if let i = comp as? Int { return i }
        if let s = comp as? String, let i = Int(s) { return i }

        return nil
    }

    // Match an array of identifier tokens (serials/names) against inventory
    @MainActor
    private func parseTokensAndMatch(tokens: [String]) {
        var matches: [ComputerBasicRecord] = []
        var unmatched: [String] = []
        var selectedIDs: Set<Int> = []

        let basicList = networkController.allComputersBasic.computers
        let altBasic = networkController.computersBasic

        // If inventory is empty, try to fetch it first then re-run the match.
        if basicList.isEmpty {
            if importDebugLogging { print("Inventory appears empty; fetching computersBasic before matching...") }
            Task {
                do {
                    try await networkController.getComputersBasic(server: server, authToken: networkController.authToken)
                    // small delay to ensure published properties propagate
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    DispatchQueue.main.async {
                        // re-run matching on main actor context
                        parseTokensAndMatch(tokens: tokens)
                    }
                } catch {
                    print("Failed to fetch computers before matching: \(error)")
                }
            }
            return
        }

        if importDebugLogging {
            print("Import debug: tokens to match: \(tokens)")
            print("Import debug: inventory sample (first 10):")
            for comp in basicList.prefix(10) {
                print("  - id:\(comp.id) name:\(comp.name) serial:\(comp.serialNumber)")
            }
        }

        for rawToken in tokens {
            let tokenRaw = rawToken
            let token = sanitizeToken(tokenRaw)
            if token.isEmpty { continue }
            let tokenLower = token.lowercased()
            let tokenNorm = normalizeToken(token)

            var tokenMatched = false

            // exact serial (manual loop so we can log comparisons)
            if !tokenMatched {
                var foundSerial: ComputerBasicRecord? = nil
                for comp in basicList {
                    let compSerial = comp.serialNumber
                    let compSerialLower = compSerial.lowercased()
                    let compSerialNorm = normalizeToken(compSerial)
                    if importDebugLogging {
                        print("  [serial-check] token='\(token)' vs comp='\(comp.name)' serial='\(compSerial)' -> lowerMatch=\(compSerialLower == tokenLower) normMatch=\(compSerialNorm == tokenNorm)")
                    }
                    if compSerialLower == tokenLower || compSerialNorm == tokenNorm {
                        foundSerial = comp
                        break
                    }
                }
                if let found = foundSerial {
                    if !matches.contains(where: { $0.id == found.id }) {
                        matches.append(found)
                        selectedIDs.insert(found.id)
                    }
                    if importDebugLogging { print("  -> Exact serial match: \(found.name) [\(found.serialNumber)]") }
                    tokenMatched = true
                }
            }

            // exact name (manual loop for logging)
            if !tokenMatched {
                var foundName: ComputerBasicRecord? = nil
                for comp in basicList {
                    let compName = comp.name
                    let compNameLower = compName.lowercased()
                    let compNameNorm = normalizeToken(compName)
                    if importDebugLogging {
                        print("  [name-check] token='\(token)' vs comp='\(compName)' -> lowerMatch=\(compNameLower == tokenLower) normMatch=\(compNameNorm == tokenNorm)")
                    }
                    if compNameLower == tokenLower || compNameNorm == tokenNorm {
                        foundName = comp
                        break
                    }
                }
                if let found = foundName {
                    if !matches.contains(where: { $0.id == found.id }) {
                        matches.append(found)
                        selectedIDs.insert(found.id)
                    }
                    if importDebugLogging { print("  -> Exact name match: \(found.name) [\(found.serialNumber)]") }
                    tokenMatched = true
                }
            }

            // legacy list mapping
            if !tokenMatched, let legacy = altBasic.first(where: { ($0.serial_number.lowercased() == tokenLower) || normalizeToken($0.serial_number) == tokenNorm || ($0.name?.lowercased() == tokenLower) }) {
                if let mapped = basicList.first(where: { $0.id == legacy.jamfId || $0.serialNumber.lowercased() == legacy.serial_number.lowercased() || $0.name.lowercased() == (legacy.name ?? "").lowercased() }) {
                    if !matches.contains(where: { $0.id == mapped.id }) {
                        matches.append(mapped)
                        selectedIDs.insert(mapped.id)
                    }
                    tokenMatched = true
                }
            }

            // partial/normalized matching
            if !tokenMatched {
                let partialMatches = basicList.filter { comp in
                    let nameLower = comp.name.lowercased()
                    let serialLower = comp.serialNumber.lowercased()
                    let nameNorm = normalizeToken(comp.name)
                    let serialNorm = normalizeToken(comp.serialNumber)

                    if nameLower.contains(tokenLower) || tokenLower.contains(nameLower) { return true }
                    if nameNorm.contains(tokenNorm) || tokenNorm.contains(nameNorm) { return true }
                    let nameWords = nameLower.split(separator: " ").map { String($0) }
                    if nameWords.contains(where: { $0.hasPrefix(tokenLower) }) { return true }
                    if nameLower.hasPrefix(tokenLower) || tokenLower.hasPrefix(nameLower) { return true }
                    if serialLower.contains(tokenLower) || tokenLower.contains(serialLower) { return true }
                    if serialNorm.contains(tokenNorm) || tokenNorm.contains(serialNorm) { return true }
                    return false
                }

                if !partialMatches.isEmpty {
                    for found in partialMatches {
                        if !matches.contains(where: { $0.id == found.id }) {
                            matches.append(found)
                            selectedIDs.insert(found.id)
                        }
                    }
                    tokenMatched = true
                }
            }

            // Fuzzy matching fallback using Levenshtein similarity on normalized strings
            if !tokenMatched && enableFuzzyMatching {
                // compute best score per computer, pick those above threshold
                var scored: [(ComputerBasicRecord, Double)] = []
                for comp in basicList {
                    let nameNorm = normalizeToken(comp.name)
                    let serialNorm = normalizeToken(comp.serialNumber)
                    let nameScore = similarityRatio(lhs: nameNorm, rhs: tokenNorm)
                    let serialScore = similarityRatio(lhs: serialNorm, rhs: tokenNorm)
                    let best = max(nameScore, serialScore)
                    if best >= fuzzyThreshold {
                        scored.append((comp, best))
                    }
                }
                // sort by best score descending
                scored.sort { $0.1 > $1.1 }
                if !scored.isEmpty {
                    // When fuzzy is enabled, include top fuzzy candidates (limit to 10) and log if requested
                    if importDebugLogging {
                        print("Fuzzy matches (>=\(String(format: "%.2f", fuzzyThreshold))) for token '\(token)':")
                    }
                    for (comp, score) in scored.prefix(10) {
                        if importDebugLogging {
                            print("  -> \(comp.name) [serial:\(comp.serialNumber)] score=\(String(format: "%.3f", score))")
                        }
                        if !matches.contains(where: { $0.id == comp.id }) {
                            matches.append(comp)
                            selectedIDs.insert(comp.id)
                        }
                    }
                    tokenMatched = true
                }
            }

            if !tokenMatched {
                unmatched.append(token)
            }
        }

        if importDebugLogging {
            print("[parseTokensAndMatch] Updating UI: matches=\(matches.count), unmatched=\(unmatched.count), selectedIDs=\(selectedIDs.count)")
        }
        DispatchQueue.main.async {
            self.importMatches = matches
            self.importUnmatched = unmatched

            // Build selection defensively using extractor so we tolerate different record shapes
            var sel = Set<Int>()
            for comp in matches {
                if let id = self.extractIntID(from: comp) {
                    sel.insert(id)
                } else {
                    if self.importDebugLogging { print("DEBUG: could not extract id for matched comp (parseTokensAndMatch): \(comp)") }
                }
            }
            self.importSelection = sel
            if self.importDebugLogging { print("Updating UI: selectedIDs=\(sel.count) -> \(sel)") }
            self.showingImportReview = true
        }
    }

}

//
//#Preview {
//    GroupDetailView()
//}
