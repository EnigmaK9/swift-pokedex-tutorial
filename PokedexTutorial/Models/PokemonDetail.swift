//
//  PokemonDetail.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Detailed Pokémon information model including stats, abilities,
//               sprites, and type data decoded from the PokéAPI detail endpoint.
//  Author: enigmak9
//

import Foundation

/// Comprehensive Pokémon data returned from the detail endpoint
/// (`GET /api/v2/pokemon/{id}`).
///
/// This struct contains all the rich information displayed in the detail view:
/// - Official artwork URL
/// - Base stats (HP, Attack, Defense, etc.)
/// - Abilities
/// - Types with slot ordering
///
/// The response from the PokéAPI is deeply nested; this model flattens
/// the relevant fields into a clean structure for the UI layer.
struct PokemonDetail: Codable, Equatable {
    static func == (lhs: PokemonDetail, rhs: PokemonDetail) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Properties

    /// Unique identifier matching the Pokémon's national Pokédex number.
    let id: Int

    /// Display name of the Pokémon.
    let name: String

    /// Base stats array containing all six stat categories.
    /// Each entry has a base value, effort yield, and nested stat name/URL.
    let stats: [Stat]

    /// Abilities the Pokémon can have, including hidden abilities.
    /// Each entry includes a slot number and a nested ability name/URL.
    let abilities: [Ability]

    /// Sprite URLs in various formats and resolutions.
    let sprites: Sprites

    /// Type entries for this Pokémon. Most Pokémon have 1-2 types.
    /// Each entry includes a slot number (ordering) and nested type name/URL.
    let types: [TypeEntry]

    // MARK: - Computed Properties

    /// The Pokémon's display name with the first letter capitalized.
    var displayName: String {
        name.capitalized
    }

    /// URL for the official high-resolution artwork.
    /// Falls back to the front-default sprite if the official artwork is unavailable.
    var bestImageURL: URL? {
        if let officialArtwork = sprites.other?.officialArtwork?.frontDefault,
           let url = URL(string: officialArtwork) {
            return url
        }
        return URL(string: sprites.frontDefault ?? "")
    }

    /// Extracts the primary and secondary types as an array of `PokemonType` values.
    /// Types are sorted by their slot number to maintain correct order (primary first).
    var pokemonTypes: [PokemonType] {
        types
            .sorted { $0.slot < $1.slot }
            .compactMap { PokemonType(rawValue: $0.type.name) }
    }

    /// The primary type (slot 1). Used for theming the detail view header.
    var primaryType: PokemonType? {
        pokemonTypes.first
    }
}

// MARK: - Nested Types

extension PokemonDetail {

    /// Represents a single base stat (e.g., HP, Attack, Speed).
    ///
    /// Example JSON:
    /// ```json
    /// {
    ///   "base_stat": 45,
    ///   "effort": 1,
    ///   "stat": { "name": "speed", "url": "..." }
    /// }
    /// ```
    struct Stat: Codable, Identifiable {
        /// Unique identifier derived from the nested stat name (e.g., "hp", "attack").
        var id: String { stat.name }

        /// The base value of this stat (typically ranges from 1 to 255).
        let baseStat: Int

        /// The effort value (EV) yielded when defeating this Pokémon.
        let effort: Int

        /// Information about the stat itself (name and detail URL).
        let stat: StatInfo

        /// A human-readable display name for the stat (e.g., "Sp. Atk" for "special-attack").
        var displayName: String {
            StatDisplayName.mapping[stat.name] ?? stat.name.capitalized
        }

        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"
            case effort
            case stat
        }
    }

    /// Container for the stat's name and detail URL.
    struct StatInfo: Codable {
        /// The stat name as returned by the API (e.g., "hp", "attack", "special-attack").
        let name: String

        /// URL to the stat's detail endpoint.
        let url: String
    }

    /// Represents a Pokémon ability.
    struct Ability: Codable, Identifiable {
        /// Unique identifier derived from the nested ability name.
        var id: String { ability.name }

        /// Whether this ability is hidden.
        /// Hidden abilities must be unlocked through special means (e.g., Dream World, Ability Patch).
        /// Decoded from the "is_hidden" field in the API response.
        let isHidden: Bool

        /// The ability's slot number (1 = primary, 2 = secondary, 3 = hidden).
        let slot: Int

        /// Information about the ability itself (name and detail URL).
        let ability: AbilityInfo

        /// A human-readable display name with the first letter capitalized
        /// and hyphens replaced with spaces.
        var displayName: String {
            ability.name
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }

        enum CodingKeys: String, CodingKey {
            case isHidden = "is_hidden"
            case slot
            case ability
        }
    }

    /// Container for the ability's name and detail URL.
    struct AbilityInfo: Codable {
        /// The ability name (e.g., "overgrow", "chlorophyll").
        let name: String

        /// URL to the ability's detail endpoint.
        let url: String
    }

    /// Container for all sprite variations returned by the API.
    struct Sprites: Codable {
        /// Default front-facing sprite (low resolution PNG).
        let frontDefault: String?

        /// Shiny front-facing sprite.
        let frontShiny: String?

        /// Container for sprite categories from different generations.
        let other: OtherSprites?

        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
            case frontShiny = "front_shiny"
            case other
        }
    }

    /// Container for alternative sprite categories.
    struct OtherSprites: Codable {
        /// Official high-resolution artwork from Pokémon Home.
        let officialArtwork: OfficialArtwork?

        enum CodingKeys: String, CodingKey {
            case officialArtwork = "official-artwork"
        }
    }

    /// High-resolution official artwork sprite URLs.
    struct OfficialArtwork: Codable {
        /// Front-facing official artwork (high resolution PNG, typically 475x475).
        let frontDefault: String?

        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
        }
    }

    /// Represents a type entry from the Pokémon's types array.
    ///
    /// Example JSON:
    /// ```json
    /// {
    ///   "slot": 1,
    ///   "type": { "name": "grass", "url": "..." }
    /// }
    /// ```
    struct TypeEntry: Codable {
        /// The type slot (1 = primary type, 2 = secondary type).
        let slot: Int

        /// Information about the type itself (name and detail URL).
        let type: TypeInfo
    }

    /// Container for the type's name and detail URL.
    struct TypeInfo: Codable, Equatable {
        /// The type name (e.g., "grass", "poison").
        let name: String

        /// URL to the type's detail endpoint.
        let url: String
    }

    /// Type effectiveness multipliers between types.
    /// Used to compute damage relations displayed in the detail view.
    struct TypeRelations: Codable, Equatable {
        /// Types that deal double damage to this type combination.
        let doubleDamageFrom: [TypeInfo]

        /// Types that deal half damage to this type combination.
        let halfDamageFrom: [TypeInfo]

        /// Types that deal no damage to this type combination.
        let noDamageFrom: [TypeInfo]

        enum CodingKeys: String, CodingKey {
            case doubleDamageFrom = "double_damage_from"
            case halfDamageFrom = "half_damage_from"
            case noDamageFrom = "no_damage_from"
        }
    }
}

// MARK: - Stat Display Name Mapping

/// Provides human-readable display names for Pokémon stat abbreviations.
///
/// The API returns abbreviated stat names (e.g., "special-attack", "special-defense").
/// This mapping converts them to the conventional display format ("Sp. Atk", "Sp. Def").
private enum StatDisplayName {
    static let mapping: [String: String] = [
        "hp": "HP",
        "attack": "Attack",
        "defense": "Defense",
        "special-attack": "Sp. Atk",
        "special-defense": "Sp. Def",
        "speed": "Speed"
    ]
}
