////
////  OptionsView.swift
////  JamfListApp
////
////  Created by Amos Deane on 16/04/2024.
////
//
import SwiftUI
import UniformTypeIdentifiers
import AppKit

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

                Spacer(minLength: 20)
            }
            .padding(.bottom)
        }
        .fileExporter(
            isPresented: $exporting,
            document: document,
            contentType: .plainText
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
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.12))
        )
        .padding(.horizontal)
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
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .padding(.horizontal)
    }

}
