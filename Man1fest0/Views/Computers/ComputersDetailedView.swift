import SwiftUI

struct ComputersDetailedView: View {
    @State var server: String
    @State var computerID: String
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress

    // Use the published full decoded ComputerFull from NetBrain directly
    @State private var isLoading: Bool = true
    @State private var lastUpdated: Date? = nil

    var body: some View {
        Group {
            if isLoading && networkController.computerDetailedFull == nil && networkController.computerDetailed == nil {
                ProgressView("Loading computer...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let d = networkController.computerDetailedFull {
                // Preferred detailed model
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Raw debug dump so it's obvious when data arrives and what's inside
                        Text("Raw detail: \(String(describing: d))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let updated = lastUpdated {
                            Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        let g = d.general
                        let h = d.hardware
                        let s = d.security

                        Text("Name: \(g?.name ?? "")")
                        Text("ID: \(g?.id ?? "")")
                        Text("UDID: \(g?.udid ?? "")")
                        Text("Serial: \(g?.serial_number ?? "")")
                        Text("Model: \(g?.model ?? "")")
                        Text("Username: \(g?.username ?? "")")
                        Text("Department: \(g?.department ?? "")")
                        Text("Building: \(g?.building ?? "")")
                        Text("Last checkin: \(g?.report_date_utc ?? "")")

                        // New hardware / security fields
                        Text("Hardware model: \(h?.model ?? "")")
                        Text("Filevault Status: \(h?.diskEncryptionConfiguration ?? "")")
                        Text("Activation Lock Status: \(s?.activationLock ?? "")")
                    }
                    .padding()
                }

            } else if let legacy = networkController.computerDetailed {
                // Legacy fallback (lightweight record)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name: \(legacy.name)")
                    Text("ID: \(legacy.id)")
                    Text("Model: \(legacy.model)")
                    Text("Username: \(legacy.username)")
                    Text("Department: \(legacy.department)")
                    // show lastUpdated if available
                    if let updated = lastUpdated {
                        Text("Last updated: \(updated.formatted(.dateTime.hour().minute().second()))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

            } else if let msg = networkController.lastErrorMessage {
                // Show error returned by NetBrain if decoding/request failed
                VStack(alignment: .leading, spacing: 12) {
                    Text("Failed to load details")
                        .font(.headline)
                    Text(msg)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("URL: \(networkController.currentURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Response code: \(networkController.currentResponseCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No details")
                    Text("Current URL: \(networkController.currentURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Response code: \(networkController.currentResponseCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .task(id: computerID) {
            // Run fetch; set loading to false when done so the UI updates based on published value
            isLoading = true
            do {
                try await networkController.getDetailedComputer(userID: computerID)
                // update lastUpdated when successful
                lastUpdated = Date()
            } catch {
                // error already published by NetBrain.publishError; fallback to printing here
                print("ComputersDetailedView: getDetailedComputer failed: \(error)")
            }
            // small delay to allow published value propagation before turning off loader
            try? await Task.sleep(nanoseconds: 100_000_000)
            isLoading = false
        }
    }
}
