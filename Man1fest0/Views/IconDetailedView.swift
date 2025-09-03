//
//  IconDetailedView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/09/2024.
//


import SwiftUI

struct IconDetailedView: View {
    
    @State var server: String
    @State var selectedIcon: Icon?
    @State private var exporting = false

    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    @StateObject private var viewModel = PhotoViewModel()

    var body: some View {
        
        VStack(alignment: .leading) {
            
            LazyVGrid(columns: layout.columnsWide, spacing: 10) {
                
                VStack(alignment: .leading) {
                    
                    if let currentIconUrl = selectedIcon?.url {
                        AsyncImage(url: URL(string: currentIconUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.red
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(.rect(cornerRadius: 25))
                        
                        Text("Filename:\t\t\(String(describing: selectedIcon?.name ?? ""))")
                        Text("ID:\t\t\t\t\(String(describing: selectedIcon?.id ?? 0))")
                        Text("Url:\t\t\t\t\(String(describing: selectedIcon?.url ?? ""))")
                        
                        Button(action: { print("Pressing button")
                            handleConnect(server: server)
                        }) {
                            HStack(spacing:20) {
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        //  ################################################################################
                        //              DOWNLOAD OPTION
                        //  ################################################################################
                        
#if os(macOS)
                        
                        Button("Export") {
                            progress.showProgress()
                            progress.waitForABit()
                            exporting = true
                            networkController.separationLine()
                            viewModel.downloadIcon(url: selectedIcon?.url ?? "", filename: selectedIcon?.name ?? "" )
                            //                        print("Printing text to export:\(text)")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
#endif
                    }
                }
            }
        }
//        .frame(minWidth: 400, maxWidth: .infinity, alignment: .leading)
    
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

//struct  IconsView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconDetailedView()
//    }
//}
