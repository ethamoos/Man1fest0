//
//  DownloadsView.swift
//  Man1fest0
//
//  Created by Amos Deane on 11/10/2023.
//

import SwiftUI

struct DownloadsView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    
    var authToken: String
    var server: String
    
    @State var downloadFileURL = ""
    @State var objectID = 1
    
    var body: some View {
        
//        let url = URL(string: downloadFileURL )
        
        VStack(alignment: .leading, spacing: 10) {
            
            LazyVGrid(columns: layout.threeColumnsAdaptive) {
                HStack {
                    Spacer()
                    Label("File URL", systemImage: "globe")
                    TextField("downloadFileURL", text: $downloadFileURL)
                }
            }
            
//            Button(action: {ASyncFileDownloader.downloadFileAsync(url: (url ?? URL(string:""))!) { (path, error) in}}) {
//                Text("Download")
//            }        
            
            Button(action: {ASyncFileDownloader.downloadFileAsyncAuth(objectID: objectID, resourceType: ResourceType.policies, server: server, authToken: networkController.authToken) { (path, error) in}}) {
                Text("Download Auth")
            }
        }
        .padding()
    }
}

