//
//  Theme.swift
//  BirdWatch Watch App
//

import SwiftUI

extension Color {
    // Primary eBird Green - High Contrast for OLED (#388E3C)
    static let ebirdGreen = Color(red: 56/255, green: 142/255, blue: 60/255)
    
    // Light eBird Green for subtle glows/borders
    static let ebirdGreenLight = Color(red: 76/255, green: 175/255, blue: 80/255)
    
    // Crisp off-white text
    static let ebirdOffWhite = Color(red: 232/255, green: 245/255, blue: 233/255)
    
    // Glassmorphism card backgrounds (subtle dark charcoal on OLED)
    static let glassBackground = Color(white: 0.08)
    
    // Glassmorphism default card border
    static let glassBorder = Color(white: 0.16)
    
    // Active glowing border
    static let glassBorderActive = Color(red: 56/255, green: 142/255, blue: 60/255).opacity(0.6)
}

// Custom tactile button style with spring scale effect
struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Glassmorphic Card ViewModifier for easy reuse
struct GlassmorphicCardModifier: ViewModifier {
    var isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.glassBorderActive : Color.glassBorder, lineWidth: isActive ? 1.5 : 1.0)
            )
    }
}

extension View {
    func glassCard(isActive: Bool = false) -> some View {
        self.modifier(GlassmorphicCardModifier(isActive: isActive))
    }
}
