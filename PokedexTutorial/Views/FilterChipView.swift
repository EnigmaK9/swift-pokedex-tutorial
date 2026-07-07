//
//  FilterChipView.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: A selectable chip/toggle used for filtering Pokémon by type.
//               Displays the type color, icon, and name with a selected state.
//  Author: enigmak9
//

import SwiftUI

/// A selectable chip that represents a Pokémon type filter option.
///
/// Used in a horizontal scrolling row above the Pokémon list. Tapping a chip
/// filters the list to show only Pokémon matching that type. Tapping the
/// selected chip again clears the filter.
///
/// Design considerations:
/// - Selected chips are filled with solid color; deselected are outlined
/// - An "All" chip at the start clears any active filter
/// - Chips are horizontally scrollable to accommodate all 18 types
struct FilterChipView: View {

    // MARK: - Properties

    /// The type this chip represents, or `nil` for the "All" chip.
    let type: PokemonType?

    /// Whether this chip is currently selected (active filter).
    let isSelected: Bool

    /// Closure called when the user taps this chip.
    let action: () -> Void

    // MARK: - Computed Properties

    /// The display text for the chip.
    private var label: String {
        type?.displayName ?? "All"
    }

    /// The color used for the chip's background or border.
    /// The "All" chip uses a neutral gray.
    private var chipColor: Color {
        type?.color ?? .gray
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                // Only show the type icon for specific types, not "All".
                if let type = type {
                    Image(systemName: type.icon)
                        .font(.caption2)
                }

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : chipColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? chipColor : chipColor.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(chipColor.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) type filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Selected state example.
        FilterChipView(type: .fire, isSelected: true, action: {})

        // Deselected state example.
        FilterChipView(type: .water, isSelected: false, action: {})

        // "All" chip — shows all Pokémon, no filter applied.
        FilterChipView(type: nil, isSelected: true, action: {})
    }
    .padding()
}
