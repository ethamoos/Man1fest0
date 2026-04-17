//  ComputerExtAttributeView.swift
//  Manifesto
//
//  Created by Amos Deane on 09/02/2024.
//

import SwiftUI

struct ComputerExtAttributeView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var extensionAttributeController: EaBrain
    
    @State var server: String
    @State var searchText: String = ""
    
    var body: some View {
        
        @State var selection: ComputerExtensionAttribute = ComputerExtensionAttribute(id: 0, name: "", enabled: true)
        
        VStack(alignment: .leading) {
            
            //            if networkController.computerExtensionAttributes.count > 0 {
            //            if networkController.allComputerExtensionAttributesArray.count > 0 {
            
            NavigationView {
                    
                VStack {
                    
//                    if #available(macOS 13.0, *) {
#if os(macOS)
                        List(searchResults, id: \.self, selection: $selection) { computerEA in
                            NavigationLink(destination: ComputerExtAttDetailView(computerEA: computerEA, server: server)) {
                                HStack {
                                    Image(systemName: "rectangle.3.group")
                                    Text(String(describing: computerEA.name)).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .red : .blue)
                                }
                            }
                        }
#else
                    
                    List(searchResults, id: \.self) { computerEA in
                        NavigationLink(destination: ComputerExtAttDetailView(computerEA: computerEA, server: server)) {
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(String(describing: computerEA.name)).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .red : .blue)
                            }
                        }
                    }
#endif
                }
                .navigationViewStyle(DefaultNavigationViewStyle())
                
                    .alert(isPresented: $extensionAttributeController.hasError) {
                        Alert(
                            title: Text("Error"),
                            message: Text("Error code is:\(extensionAttributeController.currentResponseCode)"),
                            dismissButton: .default(Text("Ok"))
                        )
                    }
                
                if progress.showProgressView == true {
                    
                    ProgressView {
                        
                        Text("Processing")
                            .padding()
                    }
                } else {
                    Text("")
                }
            }
        }
        
        .onAppear {
            print("ComputerExtAttributeView appeared. Running onAppear")
            
            Task {
            //  #######################################################################
            //  getComputerExtAttributes
            //  #######################################################################
            
                try await extensionAttributeController.getComputerExtAttributes(server: server, authToken: networkController.authToken)
//                try await extensionAttributeController.getComputerExtAttributes(server: server, authToken: "blahblah")
            }
        }
    }
    
    
    var searchResults: [ComputerExtensionAttribute] {
        if searchText.isEmpty {
            return extensionAttributeController.allComputerExtensionAttributesDict
        } else {
            return extensionAttributeController.allComputerExtensionAttributesDict
        }
    }
}



//#Preview {
//    ComputerExtAttributeView()
//}
