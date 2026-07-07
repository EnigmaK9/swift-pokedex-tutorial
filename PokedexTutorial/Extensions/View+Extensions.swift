//
//  View+Extensions.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Shared SwiftUI View modifiers and extensions used throughout the app.
//               Includes card styling, conditional modifiers, and reusable layouts.
//  Author: enigmak9
//

import SwiftUI

// MARK: - Card Style Modifier

/// A custom `ViewModifier` that applies a card-like appearance to any view.
///
/// Used for Pokémon cells, detail sections, and filter chips.
/// Provides consistent rounded corners, background color, and shadow across the app.
struct CardStyle: ViewModifier {

    /// The corner radius applied to the card.
    let cornerRadius: CGFloat

    /// The background color of the card.
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Extension

extension View {

    /// Applies the standard card style used throughout the app.
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .cardStyle()
    /// ```
    func cardStyle(
        cornerRadius: CGFloat = 12,
        backgroundColor: Color = Color(.systemBackground)
    ) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, backgroundColor: backgroundColor))
    }

    /// Conditionally applies a transformation to the view.
    ///
    /// Useful for applying modifiers only when a condition is true,
    /// avoiding awkward branching in view builders.
    ///
    /// Usage:
    /// ```swift
    /// Text("Hello")
    ///     .if(isHighlighted) { $0.foregroundColor(.yellow) }
    /// ```
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
