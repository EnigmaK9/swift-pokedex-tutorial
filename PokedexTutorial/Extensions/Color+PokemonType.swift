//
//  Color+PokemonType.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Convenience extension on Color to initialize colors from PokemonType.
//               Provides the mapping between Pokémon types and their brand colors.
//  Author: enigmak9
//

import SwiftUI

extension Color {

    /// Returns the brand color associated with the given Pokémon type.
    ///
    /// This is a convenience initializer-style static accessor that delegates
    /// to `PokemonType.color`, keeping color logic centralized in the enum.
    ///
    /// Usage:
    /// ```swift
    /// Text("Fire")
    ///     .foregroundColor(.forPokemonType(.fire))
    /// ```
    static func forPokemonType(_ type: PokemonType) -> Color {
        type.color
    }
}
