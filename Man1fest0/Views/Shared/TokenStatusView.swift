import SwiftUI

struct TokenStatusView: View {
    @EnvironmentObject var networkController: NetBrain

    @State private var isRefreshing = false
    @State private var isHovering = false

    private func color(for state: NetBrain.TokenState) -> Color {
        switch state {
        case .unknown: return Color.gray
        case .valid: return Color.green
        case .expiringSoon: return Color.orange
        case .expired: return Color.red
        }
    }

    private func refreshToken() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            do {
                try await networkController.ensureValidToken()
                networkController.messageStore?.show("Token refreshed", level: .success)
            } catch {
                networkController.messageStore?.show("Token refresh failed", level: .error, details: error.localizedDescription)
            }
            await MainActor.run { isRefreshing = false }
        }
    }

    var body: some View {
        // The entire pill is a single button so the whole area is responsive,
        // not just the refresh icon.
        Button(action: refreshToken) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color(for: networkController.tokenState))
                    .frame(width: 10, height: 10)
                Text(networkController.tokenTimeRemaining)
                    .font(.caption)
                    .foregroundColor(.primary)
                // More prominent activity symbol: larger, bold, tinted,
                // and it spins while a refresh is in progress.
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(
                        isRefreshing
                            ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: isRefreshing
                    )
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(isHovering ? 0.10 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(isHovering ? 0.15 : 0.0), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .help("Refresh authentication token")
        .onHover { hovering in
            isHovering = hovering
        }
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
