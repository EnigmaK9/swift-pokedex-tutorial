//
//  PokemonType.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Enumeration of all 18 Pokémon elemental types with color mapping
//               and SF Symbol icon associations for visual display in the UI.
//  Author: enigmak9
//

import SwiftUI

/// Represents one of the 18 elemental types in the Pokémon universe.
///
/// Each type carries associated display properties:
/// - A brand color matching the official Pokémon type color scheme
/// - An SF Symbol name for the type icon
///
/// The enum uses `String` raw values matching the lowercase API representation
/// (e.g., "fire", "water", "grass"), which allows direct decoding from JSON.
///
/// Usage:
/// ```swift
/// let type = PokemonType.fire
/// type.color   // Color.red
/// type.icon    // "flame.fill"
/// ```
enum PokemonType: String, Codable, CaseIterable, Hashable {

    // MARK: - Cases

    case normal
    case fire
    case water
    case electric
    case grass
    case ice
    case fighting
    case poison
    case ground
    case flying
    case psychic
    case bug
    case rock
    case ghost
    case dragon
    case dark
    case steel
    case fairy

    // MARK: - Display Properties

    /// The official brand color associated with this Pokémon type.
    ///
    /// Colors are sourced from the official Pokémon design guidelines
    /// and are used for type badges, backgrounds, and stat bars.
    var color: Color {
        switch self {
        case .normal:   return Color(red: 0.66, green: 0.66, blue: 0.47)
        case .fire:     return Color(red: 0.93, green: 0.51, blue: 0.19)
        case .water:    return Color(red: 0.39, green: 0.56, blue: 0.89)
        case .electric: return Color(red: 0.97, green: 0.82, blue: 0.19)
        case .grass:    return Color(red: 0.48, green: 0.78, blue: 0.30)
        case .ice:      return Color(red: 0.59, green: 0.85, blue: 0.84)
        case .fighting: return Color(red: 0.76, green: 0.18, blue: 0.16)
        case .poison:   return Color(red: 0.64, green: 0.24, blue: 0.64)
        case .ground:   return Color(red: 0.89, green: 0.75, blue: 0.40)
        case .flying:   return Color(red: 0.66, green: 0.56, blue: 0.87)
        case .psychic:  return Color(red: 0.98, green: 0.35, blue: 0.53)
        case .bug:      return Color(red: 0.65, green: 0.73, blue: 0.14)
        case .rock:     return Color(red: 0.72, green: 0.63, blue: 0.31)
        case .ghost:    return Color(red: 0.45, green: 0.34, blue: 0.59)
        case .dragon:   return Color(red: 0.44, green: 0.20, blue: 0.99)
        case .dark:     return Color(red: 0.44, green: 0.34, blue: 0.27)
        case .steel:    return Color(red: 0.72, green: 0.72, blue: 0.78)
        case .fairy:    return Color(red: 0.84, green: 0.52, blue: 0.64)
        }
    }

    /// An SF Symbol name that visually represents this Pokémon type.
    ///
    /// Uses Apple's SF Symbols library for consistent, accessible iconography.
    /// Each icon is chosen to intuitively suggest the type (e.g., a water drop for Water).
    var icon: String {
        switch self {
        case .normal:   return "circle.fill"
        case .fire:     return "flame.fill"
        case .water:    return "drop.fill"
        case .electric: return "bolt.fill"
        case .grass:    return "leaf.fill"
        case .ice:      return "snowflake"
        case .fighting: return "figure.boxing"
        case .poison:   return "skull.fill"
        case .ground:   return "mountain.2.fill"
        case .flying:   return "wind"
        case .psychic:  return "brain.head.profile"
        case .bug:      return "ant.fill"
        case .rock:     return "diamond.fill"
        case .ghost:    return "ghost.fill"
        case .dragon:   return "lizard.fill"
        case .dark:     return "moon.fill"
        case .steel:    return "gearshape.fill"
        case .fairy:    return "sparkles"
        }
    }

    /// A human-readable display name with the first letter capitalized.
    var displayName: String {
        rawValue.capitalized
    }
}
