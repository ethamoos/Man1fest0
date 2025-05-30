
import SwiftUI

struct ScriptsDetailView: View {
    
    var script: ScriptClassic
    var scriptID: Int
    var server: String
    
    @State private var title: String = ""
    @State private var bodyText: String = ""

//    @Binding var isNewNotePresented: Bool
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
    var body: some View {
        
        let currentScript = networkController.scriptDetailed
        
        VStack(alignment: .leading, spacing: 10) {

            Section(header: Text("Script Detail").bold()) {
                VStack(alignment: .leading) {
                    Text("Script Name:\t\t\(currentScript.name )")
                    Text("Script ID:\t\t\(currentScript.id)")
                    Text("Category:\t\t\(currentScript.categoryName)")
                }
            }
//            .padding()
            
            if currentScript.notes != "" {
                Divider()
                Section(header: Text("Notes").bold()) {
                    Text(currentScript.notes)
                }
            }
            
            if currentScript.info != "" {
                Divider()
                Section(header: Text("Info").bold()) {
                    Text(currentScript.info)
                }
            }
            
            Divider()
            
            ScrollView {
                
                Section(header: Text("Script:").bold()) {
                    Text(currentScript.scriptContents)
                }
            }
            
            
            VStack(spacing: 12) {
                TextField("Title", text: $title)
                    .padding(4)
                    .border(Color.gray)
                TextEditor(text: $bodyText)
                    .border(Color.gray)
            }
            .padding(32)
            Button {
            //                    repository.newNote(title: title,
            //                                            date: Date(),
            //                                            body: bodyText)
            //                    isNewNotePresented.toggle()
//                xmlController.createScript(name: currentScript.name, category: <#String#>, filename: <#String#>, info: <#String#>, notes: <#String#>, priority: <#String#>, parameter4: <#String#>, parameter5: <#String#>, parameter6: <#String#>, parameter7: <#String#>, parameter8: <#String#>, parameter9: <#String#>, parameter10: <#String#>, parameter11: <#String#>, os_requirements: <#String#>, script_contents: <#String#>, script_contents_encoded: <#Script#>, scriptID: <#Script#>, server: <#String#>)
                
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                            }
                            .disabled(title.isEmpty)
//            .navigationBarTitle("New Note", displayMode: .inline)
//            .navigationBarItems(trailing:
//                Button {
////                    repository.newNote(title: title,
////                                            date: Date(),
////                                            body: bodyText)
////                    isNewNotePresented.toggle()
//                } label: {
//                    Image(systemName: "checkmark")
//                        .font(.headline)
//                }
//                .disabled(title.isEmpty)
//            )

        }
        .padding()

        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    Color.black.opacity(0.4),
                    style: StrokeStyle()
                )
        )        
        .multilineTextAlignment(.leading)
        .padding(30)
        .frame(minWidth: 140, alignment: .leading)
        .padding()
        .foregroundColor(.blue)
        .textSelection(.enabled)

        
        .onAppear() {
            
            Task {
                try await networkController.getDetailedScript(server: server, scriptID: scriptID, authToken: networkController.authToken)
            }
        }
    }
    
}

//struct PackagesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesDetailView()
//    }
//}
