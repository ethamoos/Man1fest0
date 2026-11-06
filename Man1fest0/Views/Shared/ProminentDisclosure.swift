import SwiftUI

/// A lightweight replacement for `DisclosureGroup` that draws a more prominent
/// disclosure indicator (chevron) which can be colored, resized and made bold.
///
/// Usage:
/// ProminentDisclosure(indicatorColor: .blue) {
///     Text("Header")
/// } content: {
///     Text("Expanded content")
/// }
///
/// Open/closed state:
/// - Default: starts closed.
/// - `initiallyExpanded: true` to start open.
/// - `isExpanded: $someBool` to control/persist it from the parent (e.g. @AppStorage).
///
struct ProminentDisclosure<Label: View, Content: View>: View {
    /// Internal open/closed state (used when no external binding is supplied).
    /// Its starting value comes from `initiallyExpanded` (default: closed).
    @State private var internalExpanded: Bool
    /// Optional caller-owned binding, so the parent view can read/set/persist the state.
    private var externalExpanded: Binding<Bool>?

    /// The binding actually used: the external one if provided, otherwise the internal state.
    private var isExpanded: Binding<Bool> { externalExpanded ?? $internalExpanded }

    private let label: () -> Label
    private let content: () -> Content

    /// Color of the disclosure chevron
    private var indicatorColor: Color
    /// Font weight of the chevron (use .bold to emphasize)
    private var indicatorWeight: Font.Weight
    /// Size (point) for the chevron symbol
    private var indicatorSize: CGFloat
    /// Spacing indentation applied to the expanded content
    private var contentIndent: CGFloat

    init(indicatorColor: Color = .accentColor,
         indicatorWeight: Font.Weight = .bold,
         indicatorSize: CGFloat = 14,
         contentIndent: CGFloat = 18,
         initiallyExpanded: Bool = false,      // start open/closed (ignored if isExpanded binding is given)
         isExpanded: Binding<Bool>? = nil,     // optional external control of open/closed state
         @ViewBuilder label: @escaping () -> Label,
         @ViewBuilder content: @escaping () -> Content) {
        self._internalExpanded = State(initialValue: initiallyExpanded)
        self.externalExpanded = isExpanded
        self.indicatorColor = indicatorColor
        self.indicatorWeight = indicatorWeight
        self.indicatorSize = indicatorSize
        self.contentIndent = contentIndent
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: { withAnimation { isExpanded.wrappedValue.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .font(.system(size: indicatorSize, weight: indicatorWeight))
                        .foregroundColor(indicatorColor)
                        .imageScale(.medium)
                        .frame(minWidth: indicatorSize, minHeight: indicatorSize)

                    label()

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded.wrappedValue {
                content()
                    .padding(.leading, contentIndent)
            }
        }
    }
}

// MARK: - Previews

struct ProminentDisclosure_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProminentDisclosure(indicatorColor: .blue, indicatorWeight: .bold, indicatorSize: 16) {
                Text("Find/Replace/Inject")
                    .font(.headline)
            } content: {
                VStack(alignment: .leading) {
                    Text("Option A")
                    Text("Option B")
                }
            }

            ProminentDisclosure(indicatorColor: .red, indicatorWeight: .semibold, indicatorSize: 14) {
                Text("Smaller red")
            } content: {
                Text("Expanded content goes here")
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// Convenience color utilities used by views that consume ProminentDisclosure.
fileprivate let ProminentDisclosureColorOptions: [String] = ["blue", "green", "red", "orange", "purple", "gray"]

func prominentDisclosureColorOptions() -> [String] { ProminentDisclosureColorOptions }

func prominentDisclosureColorForName(_ name: String) -> Color {
    switch name.lowercased() {
    case "blue": return .blue
    case "green": return .green
    case "red": return .red
    case "orange": return .orange
    case "purple": return .purple
    case "gray": return .gray
    default: return .accentColor
    }
}
