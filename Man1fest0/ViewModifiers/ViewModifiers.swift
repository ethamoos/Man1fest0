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
}
