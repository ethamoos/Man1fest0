//
//  ViewModifiers.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/08/2024.
//

import Foundation
import SwiftUI

/// Styles supported by the SectionHeading modifier.
enum SectionHeadingStyle {
    case standard      // simple bold text with padding
    case divider       // thin divider above the heading
    case accentBar     // narrow accent bar at the leading edge
    case boxed         // rounded rectangle background (subtle card)
    case pill          // capsule/pill label
    case band          // full-width colored band
}

/// Preset shorthand names for common section heading combinations.
/// Use these with `Text("Title").sectionHeading(preset: .standard)`
enum SectionHeadingPreset {
    case standard    // default lightweight heading
    case bold        // high-contrast band-style heading (strong)
    case minimal     // compact heading with divider
    case accent      // accent bar to the left
    case boxedCard   // boxed rounded card style
    case pillBlue    // pill with blue tint
    case bandStrong  // full-width accent band
}

/// A consistent heading style used across the app for section headings.
/// Use `Text("Title").sectionHeading()` or pass `style:` to choose a variant.
struct SectionHeading: ViewModifier {
    var style: SectionHeadingStyle = .standard
    var size: CGFloat = 14
    var weight: Font.Weight = .bold
    var color: Color = .primary
    var paddingEdges: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    var background: Color? = nil
    var accentColor: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .standard:
            content
                .font(.system(size: size, weight: weight))
                .foregroundColor(color)
                .padding(paddingEdges)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(background)
                .accessibilityAddTraits(.isHeader)

        case .divider:
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
            }
            .padding(paddingEdges)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .accessibilityAddTraits(.isHeader)

        case .accentBar:
            HStack(spacing: 8) {
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(accentColor ?? Color.accentColor)
                    .cornerRadius(2)
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(paddingEdges)
            .background(background)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)

        case .boxed:
            content
                .font(.system(size: size, weight: weight))
                .foregroundColor(color)
                .padding(paddingEdges)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(background ?? Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06))
                )
                .accessibilityAddTraits(.isHeader)

        case .pill:
            HStack(spacing: 8) {
                content
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill((background ?? Color.accentColor.opacity(0.12))))
            .accessibilityAddTraits(.isHeader)

        case .band:
            content
                .font(.system(size: size, weight: weight))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(paddingEdges)
                .background(background ?? Color.accentColor)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

extension View {
    /// Apply the standard app section heading styling with an optional style variant.
    /// - Parameters: style: one of SectionHeadingStyle. Defaults to `.standard`.
    func sectionHeading(
        style: SectionHeadingStyle = .standard,
        size: CGFloat = 14,
        weight: Font.Weight = .bold,
        color: Color = .primary,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        background: Color? = nil,
        accentColor: Color? = nil
    ) -> some View {
        self.modifier(SectionHeading(style: style, size: size, weight: weight, color: color, paddingEdges: padding, background: background, accentColor: accentColor))
    }

    /// Convenience shorthand that maps `SectionHeadingPreset` names to specific combinations
    /// of `SectionHeadingStyle` and parameters. Returns an `AnyView` wrapper so the API is
    /// simple to call from any place in the views.
    func sectionHeading(preset: SectionHeadingPreset) -> some View {
        switch preset {
        case .standard:
            return AnyView(self.sectionHeading(style: .standard))
        case .bold:
            // Strong band with accent color for high-visibility headers
            return AnyView(self.sectionHeading(style: .band, size: 16, weight: .semibold, color: .white, background: Color.accentColor))
        case .minimal:
            // Compact divider-based heading
            return AnyView(self.sectionHeading(style: .divider, size: 13, weight: .semibold, color: .primary))
        case .accent:
            // Small leading accent bar
            return AnyView(self.sectionHeading(style: .accentBar, size: 14, weight: .semibold, color: .primary, background: nil, accentColor: Color.accentColor))
        case .boxedCard:
            // Subtle rounded rectangle card
            #if os(iOS)
            let bg = Color(.secondarySystemBackground)
            #elseif os(macOS)
            let bg = Color(NSColor.windowBackgroundColor)
            #else
            let bg = Color.gray.opacity(0.08)
            #endif
            return AnyView(self.sectionHeading(style: .boxed, size: 14, weight: .semibold, color: .primary, background: bg))
        case .pillBlue:
            return AnyView(self.sectionHeading(style: .pill, size: 13, weight: .semibold, color: .primary, background: Color.blue.opacity(0.12)))
        case .bandStrong:
            return AnyView(self.sectionHeading(style: .band, size: 15, weight: .semibold, color: .white, background: Color.blue))
        }
    }
}
