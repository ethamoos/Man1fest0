import SwiftUI

struct ScriptsDetailView: View {
    
    var script: ScriptClassic
    var scriptID: Int
    var server: String
    
//    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var scriptName: String = ""

    //    ########################################################################################
    //    EnvironmentObject
    //    ########################################################################################
    
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var layout: Layout
    
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
                TextField(scriptName, text: $scriptName)
                    .padding(4)
                    .border(Color.gray)
                TextEditor(text: $bodyText)
                    .border(Color.gray)
            }
            .padding(32)
            
            Button {
                
                progress.showProgress()
                progress.waitForABit()
                
                Task {
                    try await networkController.updateScript(server: server, scriptName: scriptName, scriptContent: bodyText, scriptId: String(describing:scriptID), authToken: networkController.authToken)
                }
            } label: {
//                Image(systemName: "paperplane")
                Text("Update")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
//            .disabled(title.isEmpty)
            
            // Open in Browser button (mirrors PolicyDetailView behavior)
            HStack {
                Spacer()
                Button(action: {
                    // Construct Jamf Pro script UI URL directly (avoids translation mismatches)
                    let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                    var base = trimmedServer
                    if base.hasSuffix("/") { base.removeLast() }
                    let uiURL = "\(base)/view/settings/computer-management/scripts/\(scriptID)?tab=general"
                    print("Opening script UI URL: \(uiURL)")
                    layout.openURL(urlString: uiURL)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text("Open in Browser")
                    }
                }
                .help("Open this script in the Jamf web interface in your default browser.")
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 6)
                Spacer()
            }
            .padding()
            .textSelection(.enabled)
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
                bodyText = networkController.scriptDetailed.scriptContents
                scriptName = networkController.scriptDetailed.name
            }
        }
    }
    
}

//struct PackagesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PackagesDetailView()
//    }
//}
