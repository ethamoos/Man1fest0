import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor

    // Downloads preference — stored in UserDefaults, default OFF
    @AppStorage(ASyncFileDownloader.openInFinderDefaultsKey)
    private var showOpenInFinder: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security")) {
                    PreferencesSecuritySection()
                }

                Section(header: Text("Policy Fetch")) {
                    NavigationLink("Policy Delay…", destination: PolicyDelayPreferencesView())
                    NavigationLink("Policy Fetch Concurrency…", destination: PolicyConcurrencyPreferencesView())
                }

                Section(header: Text("Downloads")) {
                    Toggle(isOn: $showOpenInFinder) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show \"Open in Finder\" after download")
                            Text("When enabled, a dialog offering to reveal the file in Finder appears after each XML download completes.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
            }
            .navigationTitle("Preferences")
            .frame(minWidth: 420, minHeight: 300)
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(SecuritySettingsManager())
            .environmentObject(InactivityMonitor(securitySettings: SecuritySettingsManager()))
    }
}
