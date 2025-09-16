//
//   IconsView.swift.
//  Man1fest0
//
//  Created by Amos Deane on 05/09/2024.
//

import SwiftUI

struct  IconsView: View {
    
    @StateObject private var viewModel = PhotoViewModel()
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var importExportController: ImportExportBrain
    @State var server: String

    //      ################################################################################
    //      Selections parameters
    //      ################################################################################
    
    @State private var selectedImageURL: URL?
    @State var selectedIcon: Icon = Icon(id: 0, url: "", name: "")
    @State private var selectedItem = ""

    @State var path = ""
    @State private var showList = false
    @State private var allItemsList = [""]
    @State private var searchText = ""

    var body: some View {
        
        VStack {
            VStack {
                
                if networkController.allIconsDetailed.count > 0 {
                    
                    NavigationView {
                        List(searchResults, id: \.self, selection: $selectedIcon) { icon in
                            NavigationLink(destination: IconDetailedView( server: server, selectedIcon: selectedIcon )) {
                                HStack {
                                    Image(systemName: "photo.circle")
                                    Text(icon.name ).font(.system(size: 12.0)).foregroundColor(.black)
                                }
                            }
                            .cornerRadius(8)
                        }
                        .searchable(text: $searchText)
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
            .frame(minWidth: 300, maxWidth: .infinity, alignment: .leading)
            
            Text("\(networkController.allIconsDetailed.count) total icons")
            
            VStack(spacing: 10) {
                
                HStack {
                    
                    Button(action: {
                        selectPhoto()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Select Icon")
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                Color.black.opacity(0.4),
                                style: StrokeStyle()
                            )
                    )
                    .buttonStyle(.borderedProminent)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .tint(.blue)
                    if let url = selectedImageURL {
                        Text("Selected: \(url.lastPathComponent)")
                    }
                    
                    Button(action: {
                        importExportController.uploadPhoto(server: server, authToken: networkController.authToken, selectedImageURL: selectedImageURL)
                        progress.showProgress()
                        progress.waitForABit()
                    }, label: {
                        HStack {
                            Text("Upload")
                        }
                    })
                    .buttonStyle(.borderedProminent)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .tint(.blue)
//                    .disabled(selectedImageURL == nil || importExportController.isUploading)
                    
                    Button("Download All Icons") {
                        progress.showProgress()
                        progress.waitForABit()
                        viewModel.downloadAllIcons(allIcons: networkController.allIconsDetailed)
                    }
                    .buttonStyle(.borderedProminent)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .tint(.yellow)
                }
                
                Text(importExportController.uploadStatus)
                    .foregroundColor(importExportController.uploadStatus.contains("Success") ? .green : .red)
              
            }
            .frame(width: 400, height: 50)
            .onAppear() {
                if networkController.allIconsDetailed.count <= 1 {
//                    if networkController.allIconsDetailed.count > 0 {

                    print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                    networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 20000)
                } else {
                    print("getAllIconsDetailed has already run")
                    print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                }
            }
        }
        .padding()
    }
    
    func selectPhoto() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic"]
        panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        
        if panel.runModal() == .OK {
            selectedImageURL = panel.url
            importExportController.uploadStatus = ""
        }
    }
    
    var searchResults: [Icon] {
        if searchText.isEmpty {
            return networkController.allIconsDetailed
        } else {
            return networkController.allIconsDetailed.filter { $0.name.lowercased().contains(searchText.lowercased())}
        }
    }
}
