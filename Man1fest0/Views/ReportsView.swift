////
////  OptionsView.swift
////  JamfListApp
////
////  Created by Amos Deane on 16/04/2024.
////
//
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct ReportsView: View {
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password = ""
    
    //    ########################################################################################
    //    EnvironmentObject
    //    ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var backgroundTasks: BackgroundTasks
    
    // @EnvironmentObject var controller: JamfController
    
    @EnvironmentObject var exportController: ImportExportBrain
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    //    ########################################################################################
    
    @State private var sortOrder = [KeyPathComparator(\Policy.jamfId)]
    @State private var selection = Set<Policy.ID>()
    
    //    ########################################################################################
    //    Text exporting
    //    ########################################################################################

    @State private var exporting = false

    // lightweight local refresh trigger (uses networkController publisher)
    @State private var refreshToggle = false

    //    ########################################################################################
    //    Backup (see Helpers/BackupExporter.swift)
    //    ########################################################################################

    @StateObject private var backupExporter = BackupExporter()
    // Which resource types are included when pressing "Back Up Selected" (all on by default)
    @State private var backupIncludePolicies = true
    @State private var backupIncludeScripts = true
    @State private var backupIncludeConfigProfiles = true
    @State private var backupFormat: PolicyExportFormat = .xml
    @State private var showBackupFailures = false
    
    var body: some View {
        // Break complex expressions into small locals so the compiler can type-check faster
        let hasPolicies = !networkController.allPoliciesDetailed.isEmpty
        let totalPoliciesConverted = networkController.allPoliciesConverted.count
        let totalPoliciesDetailed = networkController.allPoliciesDetailed.count
        let totalPackages = networkController.allPackages.count
        let assignedPackagesCount = backgroundTasks.assignedPackagesByNameDict.count
        let unassignedPackagesCount = backgroundTasks.unassignedPackagesArray.count
        let totalScripts = networkController.scripts.count
        let assignedScriptsCount = policyController.assignedScriptsByNameDict.count
        let unassignedScriptsCount = policyController.unassignedScriptsArray.count
        let currentDateString = layout.date
        // Prepare a safe filename for export (replace characters that are not allowed in filenames)
        let safeDateComponent = currentDateString.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: " ", with: "_")
        let exportFilename = "Man1fest0_report_\(safeDateComponent).txt"

        let text = String(describing: networkController.allPackages)
        let document = TextDocument(text: text)

        ScrollView {
            VStack(spacing: 16) {
                headerView

                // Card with stats
                Group {
                    if hasPolicies {
                        statsCardView(totalPoliciesConverted: totalPoliciesConverted,
                                      totalPoliciesDetailed: totalPoliciesDetailed,
                                      totalPackages: totalPackages,
                                      assignedPackagesCount: assignedPackagesCount,
                                      unassignedPackagesCount: unassignedPackagesCount,
                                      totalScripts: totalScripts,
                                      assignedScriptsCount: assignedScriptsCount,
                                      unassignedScriptsCount: unassignedScriptsCount,
                                      currentDateString: currentDateString,
                                      document: document)
                    } else {
                        emptyCardView
                    }
                }

                // Backup options – always shown (lists are fetched on demand if not loaded)
                backupSectionView

                Spacer(minLength: 20)
            }
            .padding(.bottom)
        }
        .fileExporter(
            isPresented: $exporting,
            document: document,
            contentType: .plainText,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success(let file):
                print("File:\(file) has exported")
            case .failure(let error):
                print(error)
            }
        }
    }

    // MARK: - Subviews broken out to help type-checker

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reports")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text("Overview of server counts and usage")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    // trigger a lightweight refresh visually
                    refreshToggle.toggle()
                    // Signal that something changed in the NetBrain (harmless if it's an ObservableObject)
                    networkController.objectWillChange.send()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button(action: { exporting = true }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
        .padding([.horizontal, .top])
    }

    @ViewBuilder
    private func statsCardView(totalPoliciesConverted: Int,
                               totalPoliciesDetailed: Int,
                               totalPackages: Int,
                               assignedPackagesCount: Int,
                               unassignedPackagesCount: Int,
                               totalScripts: Int,
                               assignedScriptsCount: Int,
                               unassignedScriptsCount: Int,
                               currentDateString: String,
                               document: TextDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Jamf server:")
                    .fontWeight(.semibold)
                Spacer()
                Text(server)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Text("Total policies in Jamf:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalPoliciesConverted)")
            }

            HStack {
                Text("Policy records downloaded:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalPoliciesDetailed)")
            }

            Divider()

            HStack {
                Text("Total Packages in Jamf:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalPackages)")
            }

            HStack {
                Text("Packages in a policy:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(assignedPackagesCount)")
            }

            HStack {
                Text("Packages not in a policy:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(unassignedPackagesCount)")
            }

            Divider()

            HStack {
                Text("Total Scripts in Jamf:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(totalScripts)")
            }

            HStack {
                Text("Scripts in a policy:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(assignedScriptsCount)")
            }

            HStack {
                Text("Scripts not in a policy:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(unassignedScriptsCount)")
            }

            Divider()

            HStack {
                Text("Current date:")
                    .fontWeight(.semibold)
                Spacer()
                Text(currentDateString)
            }

            // Export button remains available inside the card for convenience
            HStack {
                Spacer()
                Button("Export Text") {
                    exporting = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .shadow(color: .gray, radius: 2, x: 0, y: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill({
                    #if os(macOS)
                    return Color(NSColor.controlBackgroundColor)
                    #else
                    return Color(.secondarySystemBackground)
                    #endif
                }())
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.12))
        )
        .padding(.horizontal)
    }

    // MARK: - Backup section

    /// Card at the bottom of the report offering bulk backups of policies, scripts and
    /// macOS configuration profiles. Each item is saved as <id>.xml (or .json) in a
    /// timestamped folder so policies can be restored with "Replace Policies".
    private var backupSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Backup", systemImage: "externaldrive.badge.timemachine")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Picker("Format", selection: $backupFormat) {
                    ForEach(PolicyExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
                .disabled(backupExporter.isRunning)
            }
            Text("Export every item of a type to a folder of your choice. A timestamped Man1fest0_Backup folder is created with one file per item (named by Jamf ID) and an index.csv listing names.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // One-click buttons per resource type
            HStack(spacing: 10) {
                backupButton(for: .policies, count: networkController.allPoliciesConverted.count)
                backupButton(for: .scripts, count: networkController.scripts.count)
                backupButton(for: .configProfiles, count: networkController.allConfigProfiles.computerConfigurations?.count ?? 0)
            }

            // Combined backup of several types into a single folder
            HStack(spacing: 12) {
                Toggle("Policies", isOn: $backupIncludePolicies)
                Toggle("Scripts", isOn: $backupIncludeScripts)
                Toggle("Config Profiles", isOn: $backupIncludeConfigProfiles)
                Spacer()
                Button {
                    startBackup(kinds: selectedBackupKinds)
                } label: {
                    Label("Back Up Selected", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.borderedProminent)
                .disabled(backupExporter.isRunning || selectedBackupKinds.isEmpty)
            }
            // (Default Toggle style on macOS is a checkbox, so no .toggleStyle needed – keeps iOS building)
            .disabled(backupExporter.isRunning)

            backupProgressView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill({
                    #if os(macOS)
                    return Color(NSColor.controlBackgroundColor)
                    #else
                    return Color(.secondarySystemBackground)
                    #endif
                }())
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.12))
        )
        .padding(.horizontal)
    }

    /// Progress, status, cancel / reveal buttons and an expandable failure list.
    @ViewBuilder
    private var backupProgressView: some View {
        if backupExporter.isRunning || !backupExporter.statusMessage.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if backupExporter.isRunning {
                    ProgressView(value: backupExporter.fractionComplete) {
                        Text(backupExporter.statusMessage)
                            .font(.callout)
                    } currentValueLabel: {
                        Text("\(backupExporter.completedCount) / \(backupExporter.totalCount)")
                            .font(.caption)
                            .monospacedDigit()
                    }
                } else {
                    Label(backupExporter.statusMessage,
                          systemImage: backupExporter.failures.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(backupExporter.failures.isEmpty ? .green : .orange)
                }

                HStack(spacing: 10) {
                    if backupExporter.isRunning {
                        Button(role: .cancel) {
                            backupExporter.cancel()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    #if os(macOS)
                    if backupExporter.lastBackupFolder != nil {
                        Button {
                            backupExporter.revealLastBackup()
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                    }
                    #endif
                    if !backupExporter.failures.isEmpty {
                        Button {
                            showBackupFailures.toggle()
                        } label: {
                            Label(showBackupFailures ? "Hide Failures" : "Show Failures (\(backupExporter.failures.count))",
                                  systemImage: "list.bullet.rectangle")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if showBackupFailures && !backupExporter.failures.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(backupExporter.failures) { failure in
                                Text("\(failure.kind.displayName) #\(failure.itemID) – \(failure.name): \(failure.reason)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .textSelection(.enabled)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }
            }
        }
    }

    private func backupButton(for kind: BackupKind, count: Int) -> some View {
        Button {
            startBackup(kinds: [kind])
        } label: {
            // Show the loaded count when known; the list is fetched on demand otherwise.
            Label(count > 0 ? "All \(kind.displayName) (\(count))" : "All \(kind.displayName)",
                  systemImage: kind.systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(backupExporter.isRunning)
    }

    private var selectedBackupKinds: [BackupKind] {
        var kinds: [BackupKind] = []
        if backupIncludePolicies { kinds.append(.policies) }
        if backupIncludeScripts { kinds.append(.scripts) }
        if backupIncludeConfigProfiles { kinds.append(.configProfiles) }
        return kinds
    }

    /// Ask for a destination folder, then start the backup in the background.
    private func startBackup(kinds: [BackupKind]) {
        guard !kinds.isEmpty, let destination = backupExporter.chooseDestinationFolder() else { return }
        showBackupFailures = false
        backupExporter.start(kinds: kinds,
                             format: backupFormat,
                             server: server,
                             networkController: networkController,
                             destination: destination)
    }

    private var emptyCardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No usage tasks performed yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Try: Packages → Package Usage or Scripts → Script Usage")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill({
                    #if os(macOS)
                    return Color(NSColor.controlBackgroundColor)
                    #else
                    return Color(.secondarySystemBackground)
                    #endif
                }())
        )
        .padding(.horizontal)
    }

}
