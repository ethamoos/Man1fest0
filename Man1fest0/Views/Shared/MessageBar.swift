import SwiftUI

struct MessageBar: View {
    @EnvironmentObject var messageStore: MessageStore

    private func backgroundColor(for level: MessageStore.Level) -> Color {
        switch level {
        case .info: return Color.blue.opacity(0.12)
        case .success: return Color.green.opacity(0.12)
        case .warning: return Color.yellow.opacity(0.14)
        case .error: return Color.red.opacity(0.12)
        case .debug: return Color.gray.opacity(0.12)
        }
    }

    private func foregroundColor(for level: MessageStore.Level) -> Color {
        switch level {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }

    var body: some View {
        if messageStore.isVisible {
            HStack(spacing: 12) {
                if messageStore.showSpinner {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(messageStore.message)
                        .font(.subheadline)
                        .foregroundColor(foregroundColor(for: messageStore.level))
                        .lineLimit(2)
                    if let details = messageStore.details {
                        Text(details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Button(action: { messageStore.hide() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(backgroundColor(for: messageStore.level)))
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1000)
        }
    }
}

struct MessageBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageBar()
                .environmentObject(MessageStore())
                .previewLayout(.sizeThatFits)
        }
    }
}
