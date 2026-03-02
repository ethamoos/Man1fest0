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
