//
//  Pokemon.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-07
//  Description: Core Pokémon model that represents a Pokémon species.
//               Conforms to Codable for JSON decoding, Identifiable for SwiftUI lists,
//               and Hashable for set operations and navigation.
//  Author: enigmak9
//

import Foundation

/// Represents a Pokémon species with its identifying information and display properties.
///
/// This is the primary model used throughout the app. It conforms to:
/// - `Codable`: enables decoding from the PokéAPI JSON responses
/// - `Identifiable`: required by SwiftUI `List` and `ForEach` for efficient view updates
/// - `Hashable`: enables use in `Set` collections (e.g., favorites) and as navigation values
/// - `Equatable`: enables SwiftUI to detect changes and animate appropriately
///
/// Important: The PokéAPI list endpoint returns results WITHOUT an `id` field:
/// ```json
/// { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" }
/// ```
/// The `id` is extracted from the URL via a custom decoder, making this model
/// work with both list and detail endpoints seamlessly.
struct Pokemon: Identifiable, Hashable, Equatable {

    // MARK: - Properties

    /// Unique identifier for the Pokémon. Extracted from the URL or decoded directly.
    /// Using `Int` instead of `UUID` because the PokéAPI provides integer IDs.
    let id: Int

    /// The display name of the Pokémon (e.g., "bulbasaur", "pikachu").
    let name: String

    /// URL string pointing to the Pokémon's detail endpoint on the PokéAPI.
    /// Example: "https://pokeapi.co/api/v2/pokemon/1/"
    let url: String?

    /// The primary types of this Pokémon. Decoded from the detail endpoint
    /// rather than the list endpoint. Defaults to empty if not yet loaded.
    var types: [PokemonType] = []

    /// URL string for the official artwork image (front-facing, high resolution).
    var imageURL: String?

    // MARK: - Computed Properties

    /// Returns the Pokémon name with the first letter capitalized.
    var displayName: String {
        name.capitalized
    }

    /// Constructs the sprite URL for the official artwork from the Pokémon ID.
    var spriteURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable Conformance

    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension Pokemon: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
    }

    /// Custom decoder that handles the two different JSON shapes from the PokéAPI.
    ///
    /// **List endpoint** returns results without an `id`:
    /// ```json
    /// { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" }
    /// ```
    /// The `id` is extracted by parsing the last path component of the URL.
    ///
    /// **Detail endpoint** returns results with an `id`:
    /// ```json
    /// { "id": 1, "name": "bulbasaur", ... }
    /// ```
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        url = try container.decodeIfPresent(String.self, forKey: .url)

        // Try to decode `id` directly (present in detail endpoint and mock data).
        if let decodedID = try container.decodeIfPresent(Int.self, forKey: .id) {
            id = decodedID
        } else if let urlString = url,
                  let urlObj = URL(string: urlString) {
            // Extract ID from the last path component of the URL.
            // Example: "https://pokeapi.co/api/v2/pokemon/1/" → "1" → 1
            let lastComponent = urlObj.lastPathComponent
            id = Int(lastComponent) ?? 0
        } else {
            // Fallback: should not happen with valid API data.
            id = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(url, forKey: .url)
    }
}

// MARK: - API Response Wrappers

/// Top-level response from `GET /api/v2/pokemon?limit=N&offset=M`.
///
/// The PokéAPI wraps list results in this structure:
/// ```json
/// {
///   "count": 1302,
///   "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
///   "previous": null,
///   "results": [ ... ]
/// }
/// ```
struct PokemonListResponse: Codable {
    /// Total number of Pokémon available in the API.
    let count: Int

    /// URL for the next page of results, or `nil` if this is the last page.
    let next: String?

    /// URL for the previous page of results, or `nil` if this is the first page.
    let previous: String?

    /// The array of Pokémon summaries for the current page.
    /// Each result contains only `name` and `url`; detail data requires a separate request.
    let results: [Pokemon]
}
