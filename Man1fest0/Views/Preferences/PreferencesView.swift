import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security")) {
                    PreferencesSecuritySection()
                }

                Section(header: Text("Policy Fetch")) {
                    NavigationLink("Policy Delay…", destination: PolicyDelayPreferencesView())
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
