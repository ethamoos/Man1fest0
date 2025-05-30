

//
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
    
    
    var selectedResourceType: ResourceType
    @State var server: String
    @State var user: String
    @State var password: String
    @State var authToken: String
    
    
    var body: some View {
        
        
        @State var selection: ComputerExtensionAttribute = ComputerExtensionAttribute(id: "", name: "", description: "", dataType: "")
        
        @State var ComputerExtAttributeView: PolicyCodable? = nil
        
        
        VStack(alignment: .leading) {
            
            
            NavigationView {
                VStack {
                    
             
                    
                    List(networkController.allComputerExtensionAttributesArray, id: \.self) { computerEA in
                        Text(computerEA.name)
                        Text(String(describing: computerEA))
                        
                        HStack {
                            Image(systemName: "rectangle.3.group")
                            Text(String(describing: computerEA)).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .red : .blue)
                        }
                    }
                    
                    List(networkController.allComputerExtensionAttributes.computerExtensionAttribute, id: \.self) { computerEA in
                        Text(computerEA.name)
                        
                        HStack {
                            Image(systemName: "rectangle.3.group")
                            Text(String(describing: computerEA)).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .red : .blue)
                        }
                    }
                    
                    List(networkController.allComputerExtensionAttributesDict, id: \.self) { computerEA in
                        
                        Text(computerEA.name)
                        
                        HStack {
                            Image(systemName: "rectangle.3.group")
                            Text(String(describing: computerEA)).font(.system(size: 12.0)).foregroundColor(colorScheme == .dark ? .red : .blue)
                        }
                    }
                    .background(Color.gray.opacity(0.05))
                    .foregroundColor(.blue)
                    
                    .navigationTitle("Departments")
         
                }
                
                
                Text("\(networkController.allComputerExtensionAttributesDict.count) total computerExtensionAttributes")
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

        
        .onAppear {

            print("ComputerExtAttributeView appeared. Running onAppear")
           
            Task {
                
                //  #######################################################################
                //            getComputerExtAttributes
                //  #######################################################################
                
                try await networkController.getComputerExtAttributes(server: server, authToken: authToken)
            }
        }
    }
}
    
//#Preview {
//    ComputerExtAttributeView()
//}
