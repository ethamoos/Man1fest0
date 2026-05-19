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
    // Rename tools for Extension Attributes
    @State private var toolsNameAction: String = "removelast"
    @State private var toolsCountString: String = "1"
    @State private var toolsMatchString: String = ""
    @State private var toolsReplacementString: String = ""
    // Color for prominent disclosure chevron in rename tools
    @State private var renameDisclosureColorName: String = "blue"

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

                        ProminentDisclosure(indicatorColor: prominentDisclosureColorForName(renameDisclosureColorName)) {
                            HStack(spacing: 8) {
                                Text("Rename Tools")
                                    .font(.headline)
                                Spacer()
                                Menu {
                                    ForEach(["blue","green","red","orange","purple","gray"], id: \.self) { name in
                                        Button(action: { renameDisclosureColorName = name }) {
                                            HStack {
                                                Circle()
                                                    .fill(prominentDisclosureColorForName(name))
                                                    .frame(width: 10, height: 10)
                                                Text(name.capitalized)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(prominentDisclosureColorForName(renameDisclosureColorName))
                                            .frame(width: 12, height: 12)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                }
                                .menuStyle(BorderlessButtonMenuStyle())
                            }
                        } content: {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Action", selection: $toolsNameAction) {
                                    Text("Remove last chars").tag("removelast")
                                    Text("Remove first chars").tag("removefirst")
                                    Text("Replace last chars").tag("replacelast")
                                    Text("Replace first chars").tag("replacefirst")
                                    Text("Replace all occurrences").tag("replaceall")
                                    Text("Add last characters").tag("addlast")
                                    Text("Add first characters").tag("addfirst")
                                }
                                .pickerStyle(.segmented)

                                HStack(spacing: 8) {
                                    if toolsNameAction == "removelast" || toolsNameAction == "replacelast" || toolsNameAction == "removefirst" || toolsNameAction == "replacefirst" {
                                        TextField("Count", text: $toolsCountString)
                                            .frame(width: 80)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    if toolsNameAction == "replacelast" || toolsNameAction == "replaceall" || toolsNameAction == "replacefirst" || toolsNameAction == "addlast" || toolsNameAction == "addfirst" {
                                        TextField("Replacement", text: $toolsReplacementString)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    if toolsNameAction == "replaceall" {
                                        TextField("Match", text: $toolsMatchString)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    Spacer()
                                    Button(action: {
                                        let countInt = Int(toolsCountString) ?? 0
                                        progress.showProgress()
                                        progress.waitForABit()
                                        Task {
                                            for ea in Array(selection) {
                                                do {
                                                    try await extensionAttributeController.updateComputerExtensionAttributeNameLogical(server: server, authToken: networkController.authToken, extAtId: String(ea.id), action: toolsNameAction, count: countInt, match: toolsMatchString, replacement: toolsReplacementString)
                                                } catch {
                                                    print("Failed to rename EA \(ea.id): \(error)")
                                                }
                                                try? await Task.sleep(nanoseconds: 200_000_000)
                                            }
                                            progress.endProgress()
                                        }
                                    }) {
                                        Text("Run on Selected")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(selection.isEmpty)
                                }
                            }
                            .padding()
                        }
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


