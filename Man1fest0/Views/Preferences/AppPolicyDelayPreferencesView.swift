import SwiftUI

// Deprecated duplicate file retained for compatibility — use `PolicyDelayPreferencesView` in `Views/PolicyDelayPreferencesView.swift`.
// Provide a thin alias wrapper to avoid duplicate symbol definitions.
struct PolicyDelayPreferencesView_PrefAlias: View {
    var body: some View {
        PolicyDelayPreferencesView()
    }
}

struct PolicyDelayPreferencesView_PrefAlias_Previews: PreviewProvider {
    static var previews: some View {
        PolicyDelayPreferencesView_PrefAlias().environmentObject(NetBrain())
    }
}
