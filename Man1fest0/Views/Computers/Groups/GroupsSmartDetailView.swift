import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct GroupsSmartDetailView: View {
    @EnvironmentObject var networkController: NetBrain
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

            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 200)
    }

    func openInBrowser() {
        // Compose a Jamf web console URL for the group (assumes classic JSS path)
        let base = server.hasSuffix("/") ? String(server.dropLast()) : server
        let urlString = "\(base)/smartComputerGroups.html?id=\(group.id)"
        
        guard let url = URL(string: urlString) else { return }

#if os(macOS)
        NSWorkspace.shared.open(url)
#else
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
    }
}

struct GroupsSmartDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsSmartDetailView(server: "https://example.com", group: ComputerGroup(id: 123, name: "Test Group", isSmart: true))
            .environmentObject(NetBrain())
    }
}
