import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct GroupsSmartDetailView: View {
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var layout: Layout
    @State var server: String
    var group: ComputerGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.name)
                .font(.title)
                .padding(.bottom, 4)

            HStack {
                Text("ID:")
                    .bold()
                Text(String(group.id))
            }

            HStack {
                Text("Smart Group:")
                    .bold()
                Text(group.isSmart ? "Yes" : "No")
            }

            Divider()

            HStack(spacing: 12) {
#if os(macOS)
                Button(action: {
                    openInBrowser()
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Open in Browser")
                    }
                }
                .buttonStyle(.borderedProminent)
#else
                Button(action: {
                    openInBrowser()
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Open in Browser")
                    }
                }
                .buttonStyle(.borderedProminent)
#endif
                Spacer()
            }

            if xmlController.compGroupComputers.count >= 1 {

                Section(header: Text("Group Members for group: \(group.name)").bold()) {

                    List(xmlController.compGroupComputers, id: \.self) { computer in
                        VStack(alignment: .leading) {
                            Text(computer.name)
                                .font(.body)
                            if !computer.serialNumber.isEmpty {
                                Text("SN: \(computer.serialNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Open in Browser button (matches style used in ScriptsDetailView & ComputerExtAttDetailView)
                HStack {
                    Spacer()
                    Button(action: {
                        let trimmedServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
                        var base = trimmedServer
                        if base.hasSuffix("/") { base.removeLast() }
                        // Construct Jamf UI URL for this group
                        let uiURL = "\(base)/staticComputerGroups.html?id=\(group.id)&o=r"
                        print("Opening group UI URL: \(uiURL)")
                        layout.openURL(urlString: uiURL)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                            Text("Open in Browser")
                        }
                    }
                    .help("Open this group in the Jamf web interface in your default browser.")
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 6)
                    Spacer()
                }
                .padding()
                .textSelection(.enabled)

            } else {
                Text("No members found")
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 200)
        .onAppear {
            Task {
                // Fetch members into xmlController.compGroupComputers (and networkController)
                await runGetGroupMembers(selection: group, authToken: networkController.authToken)
            }
        }
        .textSelection(.enabled)
    }

    func openInBrowser() {
        // Compose a Jamf web console URL for the group (assumes classic JSS path)
        let base = server.hasSuffix("/") ? String(server.dropLast()) : server
        let urlString = "\(base)/computergroups.html?id=\(group.id)"


        guard let url = URL(string: urlString) else { return }

#if os(macOS)
        NSWorkspace.shared.open(url)
#else
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
    }

    func runGetGroupMembers(selection: ComputerGroup, authToken: String) async {
        // Prefer calling XmlBrain's async JSON loader which populates xmlController.compGroupComputers
        let groupName = selection.name

        do {
            try await xmlController.getGroupMembers(server: server, name: groupName, authToken: authToken)
        } catch {
            print("XmlBrain.getGroupMembers failed: \(error). Falling back to NetBrain JSON and XML fetch")
            // Fallback to networkController and raw XML fetch
            do {
                try await networkController.getGroupMembers(server: server, name: groupName)
            } catch {
                print("networkController.getGroupMembers also failed: \(error)")
            }
            // Also fetch XML string (used by other flows)
            xmlController.getGroupMembersXML(server: server, groupId: selection.id, authToken: authToken)
        }
        // If the async XmlBrain call succeeded, compGroupComputers will already be populated.
        // Only use the XML endpoint as a fallback (handled in the catch block above).
    }
}

struct GroupsSmartDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsSmartDetailView(server: "https://example.com", group: ComputerGroup(id: 123, name: "Test Group", isSmart: true))
            .environmentObject(NetBrain())
            .environmentObject(XmlBrain())
            .environmentObject(Layout())
    }
}
