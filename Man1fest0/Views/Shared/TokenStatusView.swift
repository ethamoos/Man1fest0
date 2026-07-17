import SwiftUI

struct TokenStatusView: View {
    @EnvironmentObject var networkController: NetBrain

    private func color(for state: NetBrain.TokenState) -> Color {
        switch state {
        case .unknown: return Color.gray
        case .valid: return Color.green
        case .expiringSoon: return Color.orange
        case .expired: return Color.red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: networkController.tokenState))
                .frame(width: 10, height: 10)
            Text(networkController.tokenTimeRemaining)
                .font(.caption)
                .foregroundColor(.primary)
            Button(action: {
                Task {
                    do {
                        try await networkController.ensureValidToken()
                        networkController.messageStore?.show("Token refreshed", level: .success)
                    } catch {
                        networkController.messageStore?.show("Token refresh failed", level: .error, details: error.localizedDescription)
                    }
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
        .onAppear {
            // Ensure UI state is correct when view appears
            Task { @MainActor in
                networkController.updateTokenState()
            }
        }
    }
}

struct TokenStatusView_Previews: PreviewProvider {
    static var previews: some View {
        TokenStatusView()
            .environmentObject(NetBrain())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
