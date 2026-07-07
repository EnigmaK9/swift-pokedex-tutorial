//
//  PokemonServiceProtocol.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Protocol defining the contract for Pokémon data fetching.
//               Enables dependency injection — swap real API for mock in tests
//               and SwiftUI previews without changing any view code.
//  Author: enigmak9
//

import Foundation

/// Protocol that defines the Pokémon data fetching interface.
///
/// By coding against this protocol rather than a concrete class:
/// 1. **Testability**: Unit tests inject `MockPokemonService` for deterministic results
/// 2. **Previews**: SwiftUI previews use mock data without network calls
/// 3. **Flexibility**: The real API implementation can change without affecting consumers
///
/// This is a core principle of **Protocol-Oriented Programming** in Swift:
/// depend on abstractions (protocols), not concretions (classes).
protocol PokemonServiceProtocol: AnyObject {

    /// Fetches a paginated list of Pokémon from the data source.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of Pokémon to return (default 20).
    ///   - offset: Number of Pokémon to skip (for pagination).
    /// - Returns: A `PokemonListResponse` containing the results and pagination info.
    /// - Throws: `PokemonServiceError` or network/decoding errors.
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse

    /// Fetches detailed information for a single Pokémon by its ID.
    ///
    /// - Parameter id: The Pokémon's national Pokédex number.
    /// - Returns: A `PokemonDetail` containing stats, abilities, sprites, and types.
    /// - Throws: `PokemonServiceError` or network/decoding errors.
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail

    /// Fetches type effectiveness data for a given type.
    ///
    /// - Parameter name: The type name (e.g., "fire", "water").
    /// - Returns: A `PokemonDetail.TypeRelations` with damage multipliers.
    /// - Throws: `PokemonServiceError` or network/decoding errors.
    func fetchTypeRelations(name: String) async throws -> PokemonDetail.TypeRelations
}

// MARK: - Service Errors

/// Custom errors that the Pokémon service can throw.
/// Provides specific, user-actionable error messages for each failure mode.
enum PokemonServiceError: LocalizedError {

    /// The URL could not be constructed (should never happen with hardcoded base URL).
    case invalidURL

    /// The server returned a non-2xx HTTP status code.
    /// - Parameter code: The HTTP status code received.
    case invalidResponse(code: Int)

    /// The JSON response could not be decoded into the expected model.
    /// - Parameter detail: Description of what failed during decoding.
    case decodingFailed(detail: String)

    /// No internet connection is available.
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "An internal error occurred. Please try again."
        case .invalidResponse(let code):
            return "Server error (code \(code)). Please try again later."
        case .decodingFailed(let detail):
            return "Failed to process data: \(detail)"
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        }
    }
}
