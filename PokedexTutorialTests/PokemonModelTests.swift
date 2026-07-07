//
//  PokemonModelTests.swift
//  PokedexTutorialTests
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Unit tests validating the Pokémon model decoding from JSON fixtures.
//               Tests cover successful decoding, malformed JSON, and edge cases.
//  Author: enigmak9
//

import XCTest
@testable import PokedexTutorial

/// Tests for the `Pokemon` and `PokemonListResponse` model decoding.
///
/// These tests verify that our Codable models correctly map the PokéAPI JSON
/// structure to Swift types. They use inline JSON strings as test fixtures,
/// which makes each test self-contained and easy to understand.
final class PokemonModelTests: XCTestCase {

    // MARK: - Properties

    /// A shared JSONDecoder. Tests don't need custom configuration here
    /// because our models handle key mapping with CodingKeys enums.
    private var decoder: JSONDecoder!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    // MARK: - Pokemon Decoding Tests

    /// Verifies that a valid Pokémon JSON snippet decodes correctly.
    func test_decodePokemon_validJSON_shouldReturnPokemonWithCorrectID() throws {
        // Given: valid JSON for a single Pokémon.
        let json = """
        {
            "id": 25,
            "name": "pikachu",
            "url": "https://pokeapi.co/api/v2/pokemon/25/"
        }
        """.data(using: .utf8)!

        // When: decoding the JSON into a Pokemon struct.
        let pokemon = try decoder.decode(Pokemon.self, from: json)

        // Then: all fields should match the JSON values.
        XCTAssertEqual(pokemon.id, 25)
        XCTAssertEqual(pokemon.name, "pikachu")
        XCTAssertEqual(pokemon.url, "https://pokeapi.co/api/v2/pokemon/25/")
    }

    /// Verifies that the `displayName` computed property capitalizes the first letter.
    func test_displayName_shouldCapitalizeFirstLetter() {
        // Given: a Pokémon with a lowercase name (as the API returns).
        let pokemon = Pokemon(id: 1, name: "bulbasaur", url: nil, types: [], imageURL: nil)

        // When: accessing the displayName property.
        // Then: the first letter should be capitalized.
        XCTAssertEqual(pokemon.displayName, "Bulbasaur")
    }

    /// Verifies that the `spriteURL` computed property constructs the correct URL.
    func test_spriteURL_shouldConstructCorrectArtworkURL() {
        // Given: a Pokémon with a known ID.
        let pokemon = Pokemon(id: 150, name: "mewtwo", url: nil, types: [], imageURL: nil)

        // When: accessing the spriteURL property.
        let url = pokemon.spriteURL

        // Then: the URL should point to the official artwork on GitHub.
        XCTAssertEqual(
            url?.absoluteString,
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/150.png"
        )
    }

    /// Verifies that two Pokémon with the same ID are considered equal.
    func test_equatable_shouldTreatSameIDAsEqual() {
        let pokemon1 = Pokemon(id: 25, name: "pikachu", url: nil, types: [], imageURL: nil)
        let pokemon2 = Pokemon(id: 25, name: "PIKACHU", url: nil, types: [.electric], imageURL: nil)

        XCTAssertEqual(pokemon1, pokemon2)
    }

    // MARK: - PokemonListResponse Decoding Tests

    /// Verifies that a full list response decodes correctly including pagination fields.
    func test_decodePokemonListResponse_validJSON_shouldDecodeCountAndResults() throws {
        // Given: a valid list response JSON with two Pokémon.
        let json = """
        {
            "count": 1302,
            "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
            "previous": null,
            "results": [
                { "id": 1, "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" },
                { "id": 2, "name": "ivysaur", "url": "https://pokeapi.co/api/v2/pokemon/2/" }
            ]
        }
        """.data(using: .utf8)!

        // When: decoding the JSON.
        let response = try decoder.decode(PokemonListResponse.self, from: json)

        // Then: pagination fields and results should decode correctly.
        XCTAssertEqual(response.count, 1302)
        XCTAssertEqual(response.results.count, 2)
        XCTAssertEqual(response.results[0].name, "bulbasaur")
        XCTAssertNotNil(response.next)
        XCTAssertNil(response.previous)
    }

    // MARK: - Edge Case Tests

    /// Verifies that decoding fails with invalid JSON.
    func test_decodePokemon_invalidJSON_shouldThrowError() {
        // Given: malformed JSON.
        let json = "{ not json at all }".data(using: .utf8)!

        // When/Then: decoding should throw.
        XCTAssertThrowsError(try decoder.decode(Pokemon.self, from: json))
    }

    /// Verifies that the `hash` method produces consistent results.
    func test_hashable_shouldProduceConsistentHashForSameID() {
        let pokemon1 = Pokemon(id: 1, name: "bulbasaur", url: nil, types: [], imageURL: nil)
        let pokemon2 = Pokemon(id: 1, name: "bulbasaur", url: nil, types: [], imageURL: nil)

        XCTAssertEqual(pokemon1.hashValue, pokemon2.hashValue)
    }
}
