//
//  MockPokemonService.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Mock implementation of PokemonServiceProtocol for development,
//               testing, and SwiftUI previews. Returns fixture data from a local
//               JSON file instead of making network requests.
//  Author: enigmak9
//

import Foundation

/// A mock Pokémon service that reads from a bundled JSON fixture.
///
/// This service simulates network latency with a short delay and returns
/// deterministic data. It is used for:
/// - **SwiftUI Previews**: see data immediately without API calls
/// - **Unit Tests**: predictable results for ViewModel testing
/// - **Development**: iterate on the UI without hitting the network
///
/// To use, inject this into your ViewModel instead of `PokemonAPIService`:
/// ```swift
/// let viewModel = PokemonListViewModel(service: MockPokemonService())
/// ```
final class MockPokemonService: PokemonServiceProtocol {

    // MARK: - Properties

    /// Simulated network delay in seconds. Set to 0 for instant responses in tests.
    private let simulatedDelay: UInt64

    // MARK: - Initialization

    /// Creates a mock service with configurable simulated latency.
    /// - Parameter simulatedDelay: Delay in seconds before returning data (default 0.5s).
    init(simulatedDelay: UInt64 = 500_000_000) {
        self.simulatedDelay = simulatedDelay
    }

    // MARK: - PokemonServiceProtocol

    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse {
        // Simulate network latency so students can see loading states in the UI.
        try await Task.sleep(nanoseconds: simulatedDelay)

        guard let url = Bundle.main.url(
            forResource: "mock_pokemon_list",
            withExtension: "json"
        ) else {
            throw PokemonServiceError.decodingFailed(
                detail: "Mock JSON file not found in bundle."
            )
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(PokemonListResponse.self, from: data)
        } catch {
            throw PokemonServiceError.decodingFailed(detail: error.localizedDescription)
        }
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        try await Task.sleep(nanoseconds: simulatedDelay / 2)

        // Return a sample detail for the mock Pokémon based on ID.
        // This is a simplified mock; the real data comes from the API.
        let sampleJSON = """
        {
            "id": \(id),
            "name": "bulbasaur",
            "stats": [
                {"base_stat": 45, "effort": 0, "stat": {"name": "hp", "url": ""}},
                {"base_stat": 49, "effort": 0, "stat": {"name": "attack", "url": ""}},
                {"base_stat": 49, "effort": 0, "stat": {"name": "defense", "url": ""}},
                {"base_stat": 65, "effort": 1, "stat": {"name": "special-attack", "url": ""}},
                {"base_stat": 65, "effort": 0, "stat": {"name": "special-defense", "url": ""}},
                {"base_stat": 45, "effort": 0, "stat": {"name": "speed", "url": ""}}
            ],
            "abilities": [
                {"ability": {"name": "overgrow", "url": ""}, "is_hidden": false, "slot": 1}
            ],
            "sprites": {
                "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png",
                "front_shiny": null,
                "other": {
                    "official-artwork": {
                        "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png"
                    }
                }
            },
            "types": [
                {"slot": 1, "type": {"name": "grass", "url": ""}},
                {"slot": 2, "type": {"name": "poison", "url": ""}}
            ]
        }
        """

        let data = Data(sampleJSON.utf8)
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(PokemonDetail.self, from: data)
        } catch {
            throw PokemonServiceError.decodingFailed(detail: error.localizedDescription)
        }
    }

    func fetchTypeRelations(name: String) async throws -> PokemonDetail.TypeRelations {
        try await Task.sleep(nanoseconds: simulatedDelay / 4)

        // Simplified mock type relations.
        return PokemonDetail.TypeRelations(
            doubleDamageFrom: [],
            halfDamageFrom: [],
            noDamageFrom: []
        )
    }
}
