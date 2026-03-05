import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security")) {
                    Picker("Auto-lock after:", selection: $securitySettings.inactivityTimeout) {
                        ForEach(SecuritySettingsManager.InactivityTimeout.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    Toggle("Require password on wake", isOn: $securitySettings.requirePasswordOnWake)
                    Toggle("Use keychain for password", isOn: $securitySettings.useKeychainForPassword)
                    Button("Force lock now") {
                        inactivityMonitor.lockApp()
                    }
                }

                Section(header: Text("Policy Fetch")) {
                    NavigationLink("Policy Delay…", destination: AppPolicyDelayPreferencesView())
                }
            }
            .navigationTitle("Preferences")
            .frame(minWidth: 420, minHeight: 260)
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
