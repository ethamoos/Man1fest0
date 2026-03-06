import SwiftUI

// Thin wrapper to expose the centralized PolicyDelayPreferencesView inline where needed
struct PolicyDelayPreferencesInlineView: View {
    var body: some View {
        PolicyDelayPreferencesView()
            .frame(minWidth: 400, minHeight: 160)
    }
}

struct PolicyDelayPreferencesInlineView_Previews: PreviewProvider {
    static var previews: some View {
        PolicyDelayPreferencesInlineView().environmentObject(NetBrain())
    }
}
