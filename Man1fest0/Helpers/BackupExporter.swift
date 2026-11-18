//
//  BackupExporter.swift
//  Man1fest0
//
//  Bulk backup of Jamf resources (policies, scripts, macOS configuration profiles)
//  to a user-chosen folder. Used by the "Backup" section at the bottom of ReportsView.
//
//  Layout of a backup:
//      <chosen folder>/Man1fest0_Backup_<yyyy-MM-dd_HHmmss>/
//          Policies/<id>.xml          + index.csv   (id,name,file,status)
//          Scripts/<id>.xml           + index.csv
//          ConfigProfiles/<id>.xml    + index.csv
//
//  Files are named purely by Jamf ID so a policy backup can be restored directly with the
//  existing "Replace Policies" tool in PolicySearchView (which takes the policy ID from the
//  filename stem). The human-readable names are kept in each folder's index.csv.
//
//  Notes:
//  - Uses the Classic API (`/JSSResource/<type>/id/<id>`) with an explicit Accept header so the
//    saved file is genuinely XML (or JSON if chosen).
//  - The Authorization header is set on the URLRequest itself; URLSessionConfiguration's
//    httpAdditionalHeaders silently drops "Authorization".
//  - Downloads run a few at a time with retry + exponential backoff on 429/5xx, because Jamf
//    Cloud throttles aggressively when hundreds of requests arrive at once.
//  - Scripts fall back to the Jamf Pro API (`/api/v1/scripts/<id>`, saved as .json) if the
//    Classic endpoint is unavailable on the server.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Supporting types (top level so they are not main-actor isolated)

/// The kinds of resource that can be backed up.
enum BackupKind: String, CaseIterable, Identifiable {
    case policies
    case scripts
    case configProfiles

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .policies: return "Policies"
        case .scripts: return "Scripts"
        case .configProfiles: return "Config Profiles (macOS)"
        }
    }

    /// Sub-folder created inside the backup folder.
    var folderName: String {
        switch self {
        case .policies: return "Policies"
        case .scripts: return "Scripts"
        case .configProfiles: return "ConfigProfiles"
        }
    }

    /// Classic API resource path segment.
    var classicPath: String {
        switch self {
        case .policies: return "policies"
        case .scripts: return "scripts"
        case .configProfiles: return "osxconfigurationprofiles"
        }
    }

    var systemImage: String {
        switch self {
        case .policies: return "doc.text"
        case .scripts: return "applescript"
        case .configProfiles: return "gearshape.2"
        }
    }
}

/// A single resource to back up.
struct BackupItem {
    let id: Int
    let name: String
}

/// A downloaded resource ready to be written to disk.
struct BackupDownloadedFile {
    let data: Data
    let fileExtension: String
}

/// A resource that could not be backed up.
struct BackupFailure: Identifiable {
    let id = UUID()
    let kind: BackupKind
    let itemID: Int
    let name: String
    let reason: String
}

enum BackupError: LocalizedError {
    case badURL
    case http(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid URL"
        case .http(let statusCode): return "HTTP \(statusCode)"
        case .unknown: return "Unknown error"
        }
    }
}

// MARK: - BackupExporter

@MainActor
final class BackupExporter: ObservableObject {

    @Published private(set) var isRunning = false
    @Published private(set) var currentKind: BackupKind?
    @Published private(set) var completedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var savedCount = 0
    @Published private(set) var failures: [BackupFailure] = []
    @Published private(set) var statusMessage = ""
    @Published private(set) var lastBackupFolder: URL?

    /// UserDefaults key used to remember the last folder the user backed up to.
    static let lastDirectoryKey = "BackupExporter.lastDirectoryPath"

    /// Number of simultaneous downloads. Kept low to avoid Jamf Cloud throttling (503s).
    private let maxConcurrentDownloads = 3
    /// Attempts per item (initial try + retries) for transient errors.
    private let maxAttempts = 3

    private var runningTask: Task<Void, Never>?

    var fractionComplete: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    // MARK: Folder selection

    /// Ask the user where to save the backup. Defaults to the last folder used.
    func chooseDestinationFolder() -> URL? {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Back Up Here"
        panel.title = "Choose a folder for the backup"
        panel.message = "A timestamped Man1fest0_Backup folder will be created inside the folder you choose."
        if let lastPath = UserDefaults.standard.string(forKey: Self.lastDirectoryKey) {
            panel.directoryURL = URL(fileURLWithPath: lastPath, isDirectory: true)
        } else {
            panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        }
        guard panel.runModal() == .OK, let folderURL = panel.url else { return nil }
        UserDefaults.standard.set(folderURL.path, forKey: Self.lastDirectoryKey)
        return folderURL
        #else
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #endif
    }

    // MARK: Start / cancel

    func start(kinds: [BackupKind],
               format: PolicyExportFormat,
               server: String,
               networkController: NetBrain,
               destination: URL) {
        guard !isRunning, !kinds.isEmpty else { return }
        runningTask = Task { [weak self] in
            await self?.run(kinds: kinds, format: format, server: server,
                            networkController: networkController, destination: destination)
        }
    }

    func cancel() {
        guard isRunning else { return }
        statusMessage = "Cancelling…"
        runningTask?.cancel()
    }

    #if os(macOS)
    func revealLastBackup() {
        guard let folder = lastBackupFolder else { return }
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }
    #endif

    // MARK: Main run loop

    private func run(kinds: [BackupKind],
                     format: PolicyExportFormat,
                     server: String,
                     networkController: NetBrain,
                     destination: URL) async {
        isRunning = true
        failures = []
        completedCount = 0
        totalCount = 0
        savedCount = 0
        defer {
            isRunning = false
            currentKind = nil
            runningTask = nil
        }

        // Folders chosen via NSOpenPanel are accessible for the session, but start access
        // explicitly in case the URL is security-scoped.
        let isAccessingScope = destination.startAccessingSecurityScopedResource()
        defer { if isAccessingScope { destination.stopAccessingSecurityScopedResource() } }

        // 1) Valid auth token (refreshes if expired).
        statusMessage = "Checking authentication…"
        let token: String
        do {
            token = try await networkController.getValidToken(server: server)
        } catch {
            statusMessage = "Backup failed: could not obtain an auth token (\(error.localizedDescription))"
            return
        }

        // 2) Build the list of items for each kind (fetching lists that haven't been loaded yet).
        var plan: [(kind: BackupKind, items: [BackupItem])] = []
        for kind in kinds {
            if Task.isCancelled { break }
            statusMessage = "Loading \(kind.displayName.lowercased()) list…"
            let items = await loadItems(for: kind, server: server, token: token, networkController: networkController)
            plan.append((kind, items))
        }
        totalCount = plan.reduce(0) { $0 + $1.items.count }
        guard !Task.isCancelled else { statusMessage = "Backup cancelled"; return }
        guard totalCount > 0 else {
            statusMessage = "Nothing to back up – no items were found for the selected types."
            return
        }

        // 3) Create the timestamped backup folder.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let backupRoot = destination.appendingPathComponent("Man1fest0_Backup_\(dateFormatter.string(from: Date()))", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        } catch {
            statusMessage = "Backup failed: could not create folder (\(error.localizedDescription))"
            return
        }
        lastBackupFolder = backupRoot

        // 4) Download each kind into its own sub-folder.
        for (kind, items) in plan {
            if Task.isCancelled { break }
            currentKind = kind
            let kindFolder = backupRoot.appendingPathComponent(kind.folderName, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: kindFolder, withIntermediateDirectories: true)
            } catch {
                for item in items {
                    failures.append(BackupFailure(kind: kind, itemID: item.id, name: item.name, reason: "Could not create folder"))
                }
                completedCount += items.count
                continue
            }

            var indexRows: [String] = ["id,name,file,status"]
            var startIndex = 0
            while startIndex < items.count && !Task.isCancelled {
                let chunk = Array(items[startIndex..<min(startIndex + maxConcurrentDownloads, items.count)])
                startIndex += chunk.count
                statusMessage = "Backing up \(kind.displayName) (\(min(completedCount + chunk.count, totalCount)) of \(totalCount))…"

                let attempts = maxAttempts
                let chunkResults = await withTaskGroup(of: (BackupItem, Result<BackupDownloadedFile, Error>).self) { group in
                    for item in chunk {
                        group.addTask {
                            let result = await BackupExporter.download(kind: kind, item: item, server: server,
                                                                       token: token, format: format, maxAttempts: attempts)
                            return (item, result)
                        }
                    }
                    var collected: [(BackupItem, Result<BackupDownloadedFile, Error>)] = []
                    for await entry in group { collected.append(entry) }
                    return collected.sorted { $0.0.id < $1.0.id }
                }

                for (item, result) in chunkResults {
                    switch result {
                    case .success(let downloaded):
                        let fileName = "\(item.id).\(downloaded.fileExtension)"
                        do {
                            try downloaded.data.write(to: kindFolder.appendingPathComponent(fileName), options: .atomic)
                            savedCount += 1
                            indexRows.append(Self.csvRow([String(item.id), item.name, fileName, "saved"]))
                        } catch {
                            failures.append(BackupFailure(kind: kind, itemID: item.id, name: item.name, reason: error.localizedDescription))
                            indexRows.append(Self.csvRow([String(item.id), item.name, "", "write failed"]))
                        }
                    case .failure(let error):
                        failures.append(BackupFailure(kind: kind, itemID: item.id, name: item.name, reason: error.localizedDescription))
                        indexRows.append(Self.csvRow([String(item.id), item.name, "", "failed: \(error.localizedDescription)"]))
                    }
                    completedCount += 1
                }
            }

            // Index file maps IDs to names so the backup is easy to browse.
            let indexText = indexRows.joined(separator: "\n") + "\n"
            try? indexText.data(using: .utf8)?.write(to: kindFolder.appendingPathComponent("index.csv"), options: .atomic)
        }

        let failureSummary = failures.isEmpty ? "" : " – \(failures.count) failed"
        if Task.isCancelled {
            statusMessage = "Backup cancelled – \(savedCount) of \(totalCount) saved\(failureSummary)"
        } else {
            statusMessage = "Backup complete – \(savedCount) of \(totalCount) saved\(failureSummary)"
        }
    }

    // MARK: Item lists

    /// Returns the items to back up for a kind, loading the list from the server if the
    /// app hasn't fetched it yet. Duplicate IDs are removed.
    private func loadItems(for kind: BackupKind, server: String, token: String, networkController: NetBrain) async -> [BackupItem] {
        var items: [BackupItem] = []
        switch kind {
        case .policies:
            if networkController.allPoliciesConverted.isEmpty {
                try? await networkController.getAllPolicies(server: server, authToken: token)
            }
            items = networkController.allPoliciesConverted.compactMap { policy in
                policy.jamfId.map { BackupItem(id: $0, name: policy.name) }
            }
        case .scripts:
            if networkController.scripts.isEmpty {
                try? await networkController.getAllScripts()
            }
            items = networkController.scripts.map { BackupItem(id: $0.jamfId, name: $0.name) }
        case .configProfiles:
            if (networkController.allConfigProfiles.computerConfigurations ?? []).isEmpty {
                try? await networkController.getOSXConfigProfiles(server: server, authToken: token)
            }
            items = (networkController.allConfigProfiles.computerConfigurations ?? []).compactMap { profile in
                profile.jamfId.map { BackupItem(id: $0, name: profile.name) }
            }
        }
        var seenIDs = Set<Int>()
        return items.filter { $0.id > 0 && seenIDs.insert($0.id).inserted }
    }

    // MARK: Networking (nonisolated so downloads run off the main actor)

    nonisolated static func download(kind: BackupKind,
                                     item: BackupItem,
                                     server: String,
                                     token: String,
                                     format: PolicyExportFormat,
                                     maxAttempts: Int) async -> Result<BackupDownloadedFile, Error> {
        let baseURL = server.hasSuffix("/") ? String(server.dropLast()) : server
        guard let classicURL = URL(string: "\(baseURL)/JSSResource/\(kind.classicPath)/id/\(item.id)") else {
            return .failure(BackupError.badURL)
        }
        let classicResult = await fetch(url: classicURL, token: token, accept: format.acceptHeader, maxAttempts: maxAttempts)
        switch classicResult {
        case .success(let data):
            return .success(BackupDownloadedFile(data: data, fileExtension: format.fileExtension))
        case .failure(let error):
            // Scripts: fall back to the Jamf Pro API if the Classic endpoint isn't available.
            if kind == .scripts, !(error is CancellationError),
               let modernURL = URL(string: "\(baseURL)/api/v1/scripts/\(item.id)"),
               case .success(let data) = await fetch(url: modernURL, token: token, accept: "application/json", maxAttempts: maxAttempts) {
                return .success(BackupDownloadedFile(data: data, fileExtension: "json"))
            }
            return .failure(error)
        }
    }

    /// GET with retry + exponential backoff (1s, 2s, …) for throttling / server errors.
    nonisolated static func fetch(url: URL, token: String, accept: String, maxAttempts: Int) async -> Result<Data, Error> {
        var lastError: Error = BackupError.unknown
        for attempt in 1...max(1, maxAttempts) {
            if Task.isCancelled { return .failure(CancellationError()) }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            request.httpMethod = "GET"
            // Authorization must be on the request itself (httpAdditionalHeaders drops it).
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(accept, forHTTPHeaderField: "Accept")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                if statusCode == 200 { return .success(data) }
                lastError = BackupError.http(statusCode)
                // Only retry transient failures; 401/403/404 etc. won't improve on retry.
                guard statusCode == 429 || statusCode >= 500 else { return .failure(lastError) }
            } catch {
                if error is CancellationError || (error as? URLError)?.code == .cancelled {
                    return .failure(CancellationError())
                }
                lastError = error
            }
            if attempt < maxAttempts {
                let delaySeconds = pow(2.0, Double(attempt - 1))
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        return .failure(lastError)
    }

    // MARK: CSV helper

    private static func csvRow(_ fields: [String]) -> String {
        fields.map { field in
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") ? "\"\(escaped)\"" : escaped
        }.joined(separator: ",")
    }
}
