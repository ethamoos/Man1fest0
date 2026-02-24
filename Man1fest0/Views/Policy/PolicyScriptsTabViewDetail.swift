import SwiftUI

struct PolicyScriptsTabViewDetail: View {
    var script: PolicyScripts
    var policyID: Int
    var server: String

    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout

    @State private var parameter4: String = ""
    @State private var parameter5: String = ""
    @State private var parameter6: String = ""
    @State private var parameter7: String = ""
    @State private var parameter8: String = ""
    @State private var parameter9: String = ""
    @State private var parameter10: String = ""
    @State private var priority: String = ""
    @State private var selectedScriptNumber: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(script.name ?? "").font(.title2).bold()

                Group {
                    HStack {
                        Text("Parameter 4:")
                        TextField("parameter4", text: $parameter4)
                    }
                    HStack {
                        Text("Parameter 5:")
                        TextField("parameter5", text: $parameter5)
                    }
                    HStack {
                        Text("Parameter 6:")
                        TextField("parameter6", text: $parameter6)
                    }
                    HStack {
                        Text("Parameter 7:")
                        TextField("parameter7", text: $parameter7)
                    }
                    HStack {
                        Text("Parameter 8:")
                        TextField("parameter8", text: $parameter8)
                    }
                    HStack {
                        Text("Parameter 9:")
                        TextField("parameter9", text: $parameter9)
                    }
                    HStack {
                        Text("Parameter 10:")
                        TextField("parameter10", text: $parameter10)
                    }

                    HStack {
                        Text("Priority:")
                        TextField("Before/After", text: $priority)
                            .frame(minWidth: 120)
                    }
                }

                HStack {
                    Picker("Script Index", selection: $selectedScriptNumber) {
                        ForEach(0..<10) { i in
                            Text("\(i)")
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Button("Update Parameter") {
                        progress.showProgress()
                        progress.waitForABit()

                        xmlController.replaceScriptParameter(authToken: networkController.authToken, resourceType: ResourceType.policyDetail, server: server, policyID: String(describing: policyID), currentPolicyAsXML: xmlController.currentPolicyAsXML, selectedScriptNumber: selectedScriptNumber, parameter4: parameter4, parameter5: parameter5, parameter6: parameter6, parameter7: parameter7, parameter8: parameter8, parameter9: parameter9, parameter10: parameter10, priority: priority)

                        Task {
                            do {
                                try await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
                            } catch {
                                print("Failed to refresh detailed policy after replacing script parameter: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                parameter4 = script.parameter4 ?? ""
                parameter5 = script.parameter5 ?? ""
                parameter6 = script.parameter6 ?? ""
                parameter7 = script.parameter7 ?? ""
                parameter8 = script.parameter8 ?? ""
                parameter9 = script.parameter9 ?? ""
                parameter10 = script.parameter10 ?? ""
                priority = script.priority ?? ""
            }
        }
    }
}

#if DEBUG
struct PolicyScriptsTabViewDetail_Previews: PreviewProvider {
    static var previews: some View {
        PolicyScriptsTabViewDetail(script: PolicyScripts(id: UUID(), jamfId: 123, name: "Test Script"), policyID: 1, server: "https://example")
            .environmentObject(XmlBrain())
            .environmentObject(NetBrain())
            .environmentObject(Progress())
            .environmentObject(Layout())
    }
}
#endif
