// PackagesDetailView.swift
// Restored PackageDetailView with editors for Info and Notes

import SwiftUI

struct PackageDetailView: View {
    
    var package: Package
    var server: String
    
    @State private var packageID = ""
    @State private var packageName = ""
    @State private var packageFileName = ""
    @State private var packageInfo = ""
    @State private var packageNotes = ""
    
    //  ########################################################################################
    //  EnvironmentObjects
    //  ########################################################################################

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    //  ########################################################################################
    //  Selections
    //  ########################################################################################

    // Use jamfId-based selection for Category to avoid Picker tag/selection mismatches
    @State var selectedCategoryId: Int? = nil
    private var selectedCategory: Category? {
        networkController.categories.first(where: { $0.jamfId == selectedCategoryId })
    }
    
    @State private var showingWarning = false
    
    var body: some View {
        
        let currentPackage = networkController.packageDetailed

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentPackage?.name ?? package.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            // Use jamfId (Int) from the lightweight `Package` model to match `currentPackage?.id` (Int?)
                            Text("ID: \(currentPackage?.id ?? package.jamfId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // `Package` (lightweight) doesn't have `filename`; use detailed package filename when available
                            // otherwise fall back to the lightweight package name
                            Text("Filename: \(currentPackage?.filename ?? package.name)")
                                 .font(.caption)
                                 .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            showingWarning = true
                            progress.showProgressView = true
                            progress.waitForABit()
                        }) {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        .keyboardShortcut(.delete, modifiers: [])
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button(action: {
                            Task {
                                try await networkController.getDetailedPackage(server: server, authToken: networkController.authToken, packageID: String(describing: package.jamfId))
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding([.bottom], 6)

                GroupBox(label: Label("Details", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Category").fontWeight(.bold)
                            Spacer()
                            Picker(selection: $selectedCategoryId, label: Text("") ) {
                                Text("No category selected").tag(nil as Int?)
                                ForEach(networkController.categories, id: \.self) { category in
                                    Text(String(describing: category.name)).tag(category.jamfId as Int?)
                                }
                            }
                            .frame(maxWidth: 240)
                            .onAppear {
                                if selectedCategoryId == nil {
                                    selectedCategoryId = networkController.categories.first?.jamfId
                                }
                            }
                        }

                        HStack {
                            Text("Priority").fontWeight(.bold)
                            Spacer()
                            Text("\(currentPackage?.priority ?? 10)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("User Template").fontWeight(.bold)
                            Spacer()
                            Text(currentPackage?.fillUserTemplate == true ? "Yes" : "No")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                }

                GroupBox(label: Label("Rename", systemImage: "pencil")) {
                    VStack(spacing: 10) {
                        HStack {
                            TextField(currentPackage?.filename ?? "", text: $packageFileName)
                                .textSelection(.enabled)
                                .frame(minWidth: 200)
                            Button("Rename File") {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updatePackageFileName(server: server, authToken: networkController.authToken, resourceType:  ResourceType.package, packageFileName: packageFileName, packageID: String(describing: currentPackage?.id ?? 0))
                                networkController.separationLine()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        HStack {
                            TextField(currentPackage?.name ?? "", text: $packageName)
                                .textSelection(.enabled)
                            Button("Rename Package") {
                                progress.showProgress()
                                progress.waitForABit()
                                networkController.updatePackageName(server: server, authToken: networkController.authToken, resourceType:  ResourceType.package, packageName: packageName, packageID: String(describing: currentPackage?.id ?? 0))
                                networkController.separationLine()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(8)
                }

                GroupBox(label: Label("Package Info", systemImage: "doc.text")) {
                    VStack(alignment: .leading) {
                        TextEditor(text: $packageInfo)
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

                        HStack {
                            Spacer()
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                // Call NetBrain to update the package info
                                networkController.updatePackageInfo(server: server, authToken: networkController.authToken, resourceType: ResourceType.package, packageInfo: packageInfo, packageID: String(describing: currentPackage?.id ?? 0))
                                networkController.separationLine()
                            }) {
                                Text("Update Info")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                    .padding(8)
                }

                GroupBox(label: Label("Package Notes", systemImage: "text.bubble")) {
                    VStack(alignment: .leading) {
                        TextEditor(text: $packageNotes)
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

                        HStack {
                            Spacer()
                            Button(action: {
                                progress.showProgress()
                                progress.waitForABit()
                                // Call NetBrain to update the package notes
                                networkController.updatePackageNotes(server: server, authToken: networkController.authToken, resourceType: ResourceType.package, packageNotes: packageNotes, packageID: String(describing: currentPackage?.id ?? 0))
                                networkController.separationLine()
                            }) {
                                Text("Update Notes")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                    .padding(8)
                }

                Spacer()
            }
            .padding(20)
            .frame(minWidth: 420)
        }
        .onAppear() {
            Task {
                try await networkController.getDetailedPackage(server: server, authToken: networkController.authToken, packageID: String(describing: package.jamfId))
            }
            if networkController.categories.count <= 1 {
                networkController.connect(server: server,resourceType: ResourceType.category, authToken: networkController.authToken)
            }
        }
        // When the detailed package is updated, populate the edit state if it's currently empty
        .onChange(of: networkController.packageDetailed) { newPackage in
            if let p = newPackage {
                if packageName.isEmpty {
                    packageName = p.name
                }
                if packageFileName.isEmpty {
                    packageFileName = p.filename
                }
                packageInfo = p.info
                packageNotes = p.notes
            }
        }
    }
}
