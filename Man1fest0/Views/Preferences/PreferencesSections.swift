 - import SwiftUI

// A compact, aligned security preferences section reused across preferences screens
struct PreferencesSecuritySection: View {
    @EnvironmentObject var securitySettings: SecuritySettingsManager
    @EnvironmentObject var inactivityMonitor: InactivityMonitor

    // Label column width for alignment
    private let labelWidth: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Auto-lock row
            HStack(alignment: .center, spacing: 12) {
                Text("Auto-lock after:")
                    .frame(width: labelWidth, alignment: .leading)
                    .foregroundColor(.primary)
                Picker("Auto-lock after:", selection: $securitySettings.inactivityTimeout) {
                    ForEach(SecuritySettingsManager.InactivityTimeout.allCases) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                Spacer()
            }

            // Require password row
            HStack(alignment: .center, spacing: 12) {
                Text("Require password on wake")
                    .frame(width: labelWidth, alignment: .leading)
                Toggle("", isOn: $securitySettings.requirePasswordOnWake)
                    .labelsHidden()
                Spacer()
            }

            // Keychain row
            HStack(alignment: .center, spacing: 12) {
                Text("Use keychain for password")
                    .frame(width: labelWidth, alignment: .leading)
                Toggle("", isOn: $securitySettings.useKeychainForPassword)
                    .labelsHidden()
                Spacer()
            }

            // Actions
            HStack(alignment: .center, spacing: 12) {
                // keep left column empty to align with labels
                Spacer().frame(width: labelWidth)
                Button(action: { inactivityMonitor.lockApp() }) {
                    Text("Force lock now")
                }
                Spacer()
            }
        }
        .padding(.vertical, 6)
    }
}

struct PreferencesSecuritySection_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesSecuritySection()
            .environmentObject(SecuritySettingsManager())
            .environmentObject(InactivityMonitor(securitySettings: SecuritySettingsManager()))
            .frame(width: 560)
            .padding()
    }
}
