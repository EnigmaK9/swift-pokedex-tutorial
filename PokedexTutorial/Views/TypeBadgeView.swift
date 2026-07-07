//
//  TypeBadgeView.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: A small colored capsule badge that displays a single Pokémon type
//               with its icon and name. Reused across list rows, detail views,
//               and filter chips for visual consistency.
//  Author: enigmak9
//

import SwiftUI

/// A colored capsule-shaped badge representing a single Pokémon type.
///
/// This view is used in multiple places throughout the app:
/// - In `PokemonRowView` to show types for each list item
/// - In `PokemonDetailView` to show the Pokémon's type(s)
/// - In filter chip groups to select type filters
///
/// Design notes:
/// - The icon comes from SF Symbols, ensuring accessibility and consistency
/// - The background color matches the official Pokémon type color scheme
/// - Text is white for contrast against the colored background
struct TypeBadgeView: View {

    // MARK: - Properties

    /// The Pokémon type to display.
    let type: PokemonType

    /// Whether to show the SF Symbol icon alongside the text.
    /// Set to `false` for compact layouts where only the colored capsule is needed.
    var showIcon: Bool = true

    // MARK: - Body

    var body: some View {
        Label(
            title: { Text(type.displayName) },
            icon: {
                if showIcon {
                    Image(systemName: type.icon)
                }
            }
        )
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(type.color)
        )
        // Accessibility: The type color alone isn't sufficient for colorblind users.
        // The text name provides the actual information; color is decorative.
        .accessibilityLabel("\(type.displayName) type")
    }
}

// MARK: - Preview

#Preview {
    HStack {
        ForEach(
            [PokemonType.fire, PokemonType.water, PokemonType.grass, PokemonType.electric],
            id: \.self
        ) { type in
            TypeBadgeView(type: type)
        }
    }
    .padding()
}
