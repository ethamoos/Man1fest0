//
//  IconDetailedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/09/2024.
//


import SwiftUI
import ImageIO

struct IconDetailedView: View {
    
    @State var server: String
    @State var selectedIcon: Icon?
    @State private var exporting = false

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    // `Layout` conflicts with SwiftUI's `Layout` protocol in newer SDKs.
    // Qualify the app's Layout class with the module name to avoid ambiguity.
    // Use the local `Layout` class type directly to avoid module qualification issues
    // (qualifying as `Man1fest0.Layout` can confuse the compiler in some build contexts).
    @EnvironmentObject var layout: AppLayout
    @StateObject private var viewModel = PhotoViewModel()

    var body: some View {
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.columnsWide, spacing: 10) {
                VStack(alignment: .leading) {
                    // Wrap the conditional image in a Group so modifiers (.frame, .clipShape, etc.)
                    // apply cleanly to the concrete view produced by the branch.
                    if let currentIconUrl = selectedIcon?.url {
                        Group {
                            // Use AsyncImage as a safe fallback when CachedAsyncImage isn't available in the build
                            if let url = URL(string: currentIconUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img
                                            .resizable()
                                            .scaledToFit()
                                    case .failure(_):
                                        Color.gray
                                    case .empty:
                                        Color.red
                                    @unknown default:
                                        Color.clear
                                    }
                                }
                            } else {
                                Color.red
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.gray, radius: 2, x: 0, y: 2)

                        Text("Filename:\t\t\(String(describing: selectedIcon?.name ?? ""))")
                        Text("ID:\t\t\t\t\(String(describing: selectedIcon?.id ?? 0))")
                        Text("Url:\t\t\t\t\(String(describing: selectedIcon?.url ?? ""))")

                        Button(action: {
                            print("Pressing button")
                            handleConnect(server: server)
                        }) {
                            HStack(spacing:20) {
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

#if os(macOS)
                        Button("Export") {
                            progress.showProgress()
                            progress.waitForABit()
                            exporting = true
                            networkController.separationLine()
                            viewModel.downloadIcon(url: selectedIcon?.url ?? "", filename: selectedIcon?.name ?? "" )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: Color.gray, radius: 2, x: 0, y: 2)
#endif
                    }
                }
            }
        }
    
        .padding()

        .onAppear {
            print("Icon detailed view appeared. Running onAppear")
            print("selectedIcon is set as:\(String(describing: selectedIcon?.name ?? ""))")
            handleConnect(server: server)
        }
    }
    
    func handleConnect(server: String) {
        print("Handling connection")
        Task {
            try await networkController.getDetailedIcon(server: server, authToken: networkController.authToken, iconID: String(describing: selectedIcon?.id ?? 0))
        }
    }
}
