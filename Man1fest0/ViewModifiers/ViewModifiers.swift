//
//  ViewModifiers.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/08/2024.
//

import Foundation
import SwiftUI

//struct GlowBorder: ViewModifier {
//    
//    var color: Color
//    var lineWidth: Int
//    
//    func body (content: Content) -> some View {
//        applyShadow(content: AnyView(content), linewidth: lineWidth)
//    }
//    
//    func applyShadow(content: AnyView, linewidth: Int) -> AnyView {
//        if lineWidth == 0 {
//            return content
//        } else {
//            return applyShadow(content: AnyView(content.shadow(color: color, radius: 1)), linewidth: lineWidth
//                               - 1)
//        }
//    }
//}
//
//        
//extension View {
//    func glowBorder (color: Color, linewidth: Int) -> some View {
//        self.modifier(GlowBorder(color: color, lineWidth: linewidth))
//    }
//}

struct SectionHeading: ViewModifier {
    var size: CGFloat = 14
    var weight: Font.Weight = .bold
    var color: Color = .primary
    var paddingEdges: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    var background: Color? = nil

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
            .padding(paddingEdges)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
    }
}

extension View {
    /// Apply the standard app section heading styling.
    /// Usage: `Text("Heading").sectionHeading()`
    func sectionHeading(
        size: CGFloat = 14,
        weight: Font.Weight = .bold,
        color: Color = .primary,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        background: Color? = nil
    ) -> some View {
        self.modifier(SectionHeading(size: size, weight: weight, color: color, paddingEdges: padding, background: background))
    }
}
