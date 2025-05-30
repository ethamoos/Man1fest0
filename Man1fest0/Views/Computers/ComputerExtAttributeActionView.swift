//
//  ComputerExtAttributeActions.swift
//  Man1fest0
//
//  Created by Amos Deane on 27/05/2025.
//



import SwiftUI

struct ComputerExtAttributeActionView: View {
    
//    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var extensionAttributeController: EaBrain
    
    @State var server: String
    @State var searchText: String = ""
    @State var selection = Set<ComputerExtensionAttribute>()
    @State private var showingWarning = false

    var body: some View {
        
        VStack(alignment: .leading) {
            
            NavigationView {
                
                VStack {
                    
#if os(macOS)
                    List(searchResults, id: \.self, selection: $selection) { computerEA in
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(String(describing: computerEA.name))
                            }
                    }
                    
                    Button(action: {

                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "delete.left.fill")
                            
                            Text("Delete")
                        }
                        .foregroundColor(.blue)
                        .alert(isPresented: $showingWarning) {
                            Alert(
                                title: Text("Caution!"),
                                message: Text("This action will delete data.\n Always ensure that you have a backup!"),
                                primaryButton: .destructive(Text("I understand!")) {
                                    // Code to execute when "Yes" is tapped
                                    Task {
                                        try await extensionAttributeController.batchDeleteComputerEA(selection: selection, server: server, authToken: networkController.authToken, resourceType: ResourceType.computerExtensionAttribute)
                                    }
                                    print("Yes tapped")
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Selections").fontWeight(.bold)
                        
                        List(Array(selection), id: \.self) { computerEA in
                            Text(computerEA.name )
                        }
                        .frame(height: 50)
                    }
#else
                    List(searchResults, id: \.self) { computerEA in
                            HStack {
                                Image(systemName: "rectangle.3.group")
                                Text(String(describing: computerEA.name))
                            }
                    }
#endif
                }
                .navigationViewStyle(DefaultNavigationViewStyle())
                
             
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


