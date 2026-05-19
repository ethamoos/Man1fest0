import SwiftUI

// Small helper used by views that want a color selected by name for the
// ProminentDisclosure indicator. Centralizing the logic avoids duplication.
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
