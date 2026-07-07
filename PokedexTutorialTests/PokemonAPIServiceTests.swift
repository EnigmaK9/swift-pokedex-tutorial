//
//  PokemonAPIServiceTests.swift
//  PokedexTutorialTests
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Integration tests for the real PokéAPI service. Validates that
//               the live API responses match our expected model structure.
//               Tests are marked with a timeout for network reliability.
//  Author: enigmak9
//

import XCTest
@testable import PokedexTutorial

/// Integration tests for `PokemonAPIService`.
///
/// These tests hit the real PokéAPI (pokeapi.co). They verify:
/// - Network connectivity to the API
/// - Correct JSON structure (our models match the API response)
/// - Pagination mechanics
/// - Known Pokémon data points
///
/// NOTE: These tests require an internet connection. They are designed
/// to be run on demand, not as part of every CI build. The PokéAPI is
/// a free service — please use these tests responsibly.
final class PokemonAPIServiceTests: XCTestCase {

    // MARK: - Properties

    private var service: PokemonAPIService!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        service = PokemonAPIService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - List Fetch Tests

    /// Verifies that fetching the first page of Pokémon returns expected data.
    func test_fetchPokemonList_firstPage_shouldReturn20Pokemon() async throws {
        // Given: a real API service.
        // When: fetching the first page with default parameters.
        let response = try await service.fetchPokemonList(limit: 20, offset: 0)

        // Then: the response should contain 20 Pokémon and a total count.
        XCTAssertEqual(response.results.count, 20)
        XCTAssertGreaterThan(response.count, 1000, "There should be over 1000 Pokémon total")
        XCTAssertNotNil(response.next, "There should be a next page URL")
        XCTAssertNil(response.previous, "First page should have no previous URL")
    }

    /// Verifies that the first Pokémon in the API is Bulbasaur (ID #1).
    func test_fetchPokemonList_firstPokemon_shouldBeBulbasaur() async throws {
        // Given: the API service.
        // When: fetching the first page.
        let response = try await service.fetchPokemonList(limit: 20, offset: 0)

        // Then: the first Pokémon should be Bulbasaur with the correct name.
        let first = response.results.first
        XCTAssertEqual(first?.name, "bulbasaur")
    }

    /// Verifies that pagination works by comparing two consecutive pages.
    func test_fetchPokemonList_pagination_shouldReturnDifferentResults() async throws {
        // Given: the API service.
        // When: fetching two consecutive pages.
        let page1 = try await service.fetchPokemonList(limit: 5, offset: 0)
        let page2 = try await service.fetchPokemonList(limit: 5, offset: 5)

        // Then: the pages should contain different Pokémon.
        let page1IDs = Set(page1.results.map(\.id))
        let page2IDs = Set(page2.results.map(\.id))
        XCTAssertTrue(page1IDs.isDisjoint(with: page2IDs), "Pages should not overlap")
    }

    // MARK: - Detail Fetch Tests

    /// Verifies that fetching a known Pokémon (Pikachu #25) returns correct data.
    func test_fetchPokemonDetail_pikachu_shouldReturnCorrectData() async throws {
        // Given: Pikachu's Pokédex number.
        let pikachuID = 25

        // When: fetching the detail for Pikachu.
        let detail = try await service.fetchPokemonDetail(id: pikachuID)

        // Then: the detail should match known Pikachu data.
        XCTAssertEqual(detail.id, 25)
        XCTAssertEqual(detail.name, "pikachu")
        XCTAssertEqual(detail.pokemonTypes.count, 1, "Pikachu should have one type")
        XCTAssertEqual(detail.pokemonTypes.first, .electric, "Pikachu should be Electric type")
        XCTAssertEqual(detail.stats.count, 6, "Should have all 6 base stats")
        XCTAssertFalse(detail.abilities.isEmpty, "Should have at least one ability")
    }

    /// Verifies that a dual-type Pokémon (Bulbasaur) has both types.
    func test_fetchPokemonDetail_bulbasaur_shouldHaveTwoTypes() async throws {
        // Given: Bulbasaur's Pokédex number.
        let bulbasaurID = 1

        // When: fetching Bulbasaur's detail.
        let detail = try await service.fetchPokemonDetail(id: bulbasaurID)

        // Then: Bulbasaur should be Grass/Poison type.
        XCTAssertEqual(detail.pokemonTypes.count, 2)
        XCTAssertTrue(detail.pokemonTypes.contains(.grass))
        XCTAssertTrue(detail.pokemonTypes.contains(.poison))
    }

    /// Verifies that fetching a non-existent Pokémon throws an error.
    func test_fetchPokemonDetail_invalidID_shouldThrowError() async {
        // Given: an ID that doesn't exist (0 is not a valid Pokémon).
        // When/Then: fetching should throw an error.
        do {
            _ = try await service.fetchPokemonDetail(id: 0)
            XCTFail("Expected an error for ID 0")
        } catch {
            // Expected: the API should return a 404 or other error.
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Type Relations Tests

    /// Verifies that type effectiveness data is returned for the Fire type.
    func test_fetchTypeRelations_fire_shouldReturnRelations() async throws {
        // Given: the Fire type name.
        // When: fetching type relations.
        let relations = try await service.fetchTypeRelations(name: "fire")

        // Then: Fire should be weak to Water, Ground, and Rock.
        let weakTo = relations.doubleDamageFrom.map(\.name)
        XCTAssertTrue(weakTo.contains("water"), "Fire should be weak to Water")
        XCTAssertTrue(weakTo.contains("ground"), "Fire should be weak to Ground")
        XCTAssertTrue(weakTo.contains("rock"), "Fire should be weak to Rock")
    }
}
