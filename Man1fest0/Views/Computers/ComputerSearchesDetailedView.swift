#if os(macOS)
import AppKit
#endif

import SwiftUI

struct ComputerSearchesDetailedView: View {
    @EnvironmentObject var networkController: NetBrain
    let searchId: Int

    var body: some View {
        Group {
            if let d = networkController.advancedComputerSearchDetailed {
                VStack(alignment: .leading, spacing: 12) {
                    Text(d.name).font(.title)
                    Text("ID: \(d.id)").foregroundColor(.secondary)
                    if let crit = d.criteria {
                        Text("Criteria:")
                            .font(.headline)
                        ScrollView { Text(crit).font(.body) }
                    }
                    HStack(spacing: 12) {
                        Button("Open in Browser") {
                            // Build the JSSResource URL for the advancedcomputersearch
                            if let url = URL(string: networkController.server + "/JSSResource/advancedcomputersearches/id/" + String(searchId)) {
                                #if os(macOS)
                                NSWorkspace.shared.open(url)
                                #endif
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Delete Selection") {
                            Task {
                                let setSel: Set<AdvancedComputerSearch> = Set([AdvancedComputerSearch(id: d.id, name: d.name)])
                                try? await networkController.batchDeleteAdvancedComputerSearch(selection: setSel, server: networkController.server, authToken: networkController.authToken, resourceType: .advancedComputerSearch)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            } else {
                Text("Loading...")
                    .task(id: searchId) {
                        do {
                            try await networkController.getDetailAdvancedComputerSearch(userID: String(searchId))
                        } catch {
                            print("Failed to load detail for id \(searchId): \(error)")
                        }
                    }
            }
        }
    }
}

struct ComputerSearchesDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        ComputerSearchesDetailedView(searchId: 0)
            .environmentObject(NetBrain())
    }
}
