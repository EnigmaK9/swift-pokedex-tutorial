//
//  PokemonAPIService.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Real API client that fetches Pokémon data from the PokéAPI
//               (https://pokeapi.co). Implements PokemonServiceProtocol using
//               async/await and URLSession for modern Swift concurrency.
//  Author: enigmak9
//

import Foundation

/// The production Pokémon data service that communicates with the PokéAPI.
///
/// This service demonstrates modern Swift networking patterns:
/// - **async/await**: Structured concurrency instead of completion handler pyramids
/// - **URLSession**: Apple's built-in networking framework
/// - **Codable**: Automatic JSON decoding into Swift types
/// - **HTTP status checking**: Validates response codes before attempting decode
///
/// Rate limiting note: The PokéAPI is a free service. This implementation
/// includes no built-in rate limiting — be respectful when testing.
///
/// Architectural note: This class is `final` because there's no reason to subclass it.
/// Marking classes as `final` by default is a Swift best practice; it enables compiler
/// optimizations and clearly signals intent.
final class PokemonAPIService: ObservableObject, PokemonServiceProtocol {

    // MARK: - Constants

    /// Base URL for the PokéAPI v2 REST endpoints.
    /// All paths are appended to this base URL.
    private static let baseURL = "https://pokeapi.co/api/v2"

    // MARK: - URLSession

    /// The URLSession used for all network requests.
    ///
    /// Using `URLSession.shared` is appropriate here because:
    /// - No custom caching behavior is needed (the API responses change rarely)
    /// - No authentication headers are required
    /// - The default timeout (60s) is adequate
    ///
    /// For production apps with authentication, custom caching, or background
    /// uploads, you would create a custom `URLSessionConfiguration`.
    private let session: URLSession

    /// The JSON decoder shared across all fetch methods.
    ///
    /// Reusing a single decoder is more efficient than creating one per request.
    /// No custom `keyDecodingStrategy` is needed because the PokéAPI uses snake_case
    /// (e.g., "base_stat") and our models use custom CodingKeys where the mapping differs.
    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Creates a new API service with configurable session and decoder.
    /// - Parameters:
    ///   - session: URLSession to use (defaults to `.shared`; inject a mock for testing).
    ///   - decoder: JSONDecoder to use (defaults to a new instance).
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    // MARK: - PokemonServiceProtocol

    /// Fetches a paginated list of Pokémon from the PokéAPI.
    ///
    /// Endpoint: `GET /api/v2/pokemon?limit={limit}&offset={offset}`
    ///
    /// - Parameters:
    ///   - limit: Number of Pokémon to fetch per page (max ~1302 total exist).
    ///   - offset: Starting position for pagination.
    /// - Returns: A response containing Pokémon summaries and pagination URLs.
    /// - Throws: `PokemonServiceError` for network or decoding failures.
    func fetchPokemonList(limit: Int = 20, offset: Int = 0) async throws -> PokemonListResponse {
        guard var components = URLComponents(string: "\(Self.baseURL)/pokemon") else {
            throw PokemonServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else {
            throw PokemonServiceError.invalidURL
        }

        let data = try await performRequest(url: url)
        return try decode(data)
    }

    /// Fetches detailed information for a single Pokémon by its national Pokédex number.
    ///
    /// Endpoint: `GET /api/v2/pokemon/{id}`
    ///
    /// This endpoint returns the full Pokémon profile including:
    /// - Base stats (HP, Attack, Defense, Sp. Atk, Sp. Def, Speed)
    /// - Abilities (with hidden ability flag)
    /// - Sprites (official artwork, front default, shiny)
    /// - Types (with slot ordering)
    ///
    /// - Parameter id: The Pokémon's ID (1-1302+).
    /// - Returns: A fully populated `PokemonDetail`.
    /// - Throws: `PokemonServiceError` for network or decoding failures.
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        guard let url = URL(string: "\(Self.baseURL)/pokemon/\(id)") else {
            throw PokemonServiceError.invalidURL
        }

        let data = try await performRequest(url: url)
        return try decode(data)
    }

    /// Fetches type effectiveness data (damage relations) for a given type.
    ///
    /// Endpoint: `GET /api/v2/type/{name}`
    ///
    /// The response includes:
    /// - `double_damage_from`: Types that deal 2x damage
    /// - `half_damage_from`: Types that deal 0.5x damage
    /// - `no_damage_from`: Types that deal 0x damage (immunities)
    ///
    /// - Parameter name: The type name (e.g., "fire", "water").
    /// - Returns: `TypeRelations` with damage multipliers.
    /// - Throws: `PokemonServiceError` for network or decoding failures.
    func fetchTypeRelations(name: String) async throws -> PokemonDetail.TypeRelations {
        guard let url = URL(string: "\(Self.baseURL)/type/\(name)") else {
            throw PokemonServiceError.invalidURL
        }

        let data = try await performRequest(url: url)

        // The type endpoint wraps damage relations inside a "damage_relations" key.
        // We need to extract just that portion. We do this by decoding to a
        // temporary structure, then returning the nested relations.
        struct TypeResponse: Codable {
            struct DamageRelationsWrapper: Codable {
                let doubleDamageFrom: [PokemonDetail.TypeInfo]
                let halfDamageFrom: [PokemonDetail.TypeInfo]
                let noDamageFrom: [PokemonDetail.TypeInfo]

                enum CodingKeys: String, CodingKey {
                    case doubleDamageFrom = "double_damage_from"
                    case halfDamageFrom = "half_damage_from"
                    case noDamageFrom = "no_damage_from"
                }
            }
            let damageRelations: DamageRelationsWrapper

            enum CodingKeys: String, CodingKey {
                case damageRelations = "damage_relations"
            }
        }

        let typeResponse = try decode(data) as TypeResponse
        let relations = typeResponse.damageRelations

        return PokemonDetail.TypeRelations(
            doubleDamageFrom: relations.doubleDamageFrom,
            halfDamageFrom: relations.halfDamageFrom,
            noDamageFrom: relations.noDamageFrom
        )
    }

    // MARK: - Private Helpers

    /// Performs an HTTP GET request and returns the raw response data.
    ///
    /// This method encapsulates the common networking concerns:
    /// 1. Making the request with `URLSession`
    /// 2. Checking for transport-level errors
    /// 3. Validating the HTTP status code is in the 2xx range
    ///
    /// - Parameter url: The fully constructed URL to fetch.
    /// - Returns: The raw `Data` from the response body.
    /// - Throws: `PokemonServiceError` wrapping the specific failure.
    private func performRequest(url: URL) async throws -> Data {
        let (data, response): (Data, URLResponse)

        do {
            // `await` suspends execution here until the network call completes,
            // freeing the thread for other work. This is the core of structured concurrency.
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            // URLError provides specific network error codes.
            // `.notConnectedToInternet` and `.timedOut` are the most common.
            if error.code == .notConnectedToInternet || error.code == .timedOut {
                throw PokemonServiceError.networkUnavailable
            }
            throw PokemonServiceError.invalidResponse(code: error.errorCode)
        }

        // Cast to HTTPURLResponse to access the status code.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PokemonServiceError.invalidResponse(code: -1)
        }

        // Only accept 2xx status codes. The PokéAPI returns 200 for success
        // and 404 for invalid Pokémon IDs.
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PokemonServiceError.invalidResponse(code: httpResponse.statusCode)
        }

        return data
    }

    /// Decodes JSON data into a specified `Decodable` type.
    ///
    /// Extracted to a generic helper to avoid repeating try/catch blocks
    /// in every fetch method. Swift's type inference determines `T` from context.
    ///
    /// - Parameter data: The raw JSON bytes to decode.
    /// - Returns: An instance of type `T` populated from the JSON.
    /// - Throws: `PokemonServiceError.decodingFailed` with the specific error detail.
    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            // DecodingError provides rich diagnostics. We extract the context
            // to give the user actionable information about what went wrong.
            let detail: String
            switch decodingError {
            case .keyNotFound(let key, let context):
                detail = "Missing key '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                detail = "Expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                detail = "Expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                detail = context.debugDescription
            @unknown default:
                detail = decodingError.localizedDescription
            }
            throw PokemonServiceError.decodingFailed(detail: detail)
        } catch {
            throw PokemonServiceError.decodingFailed(detail: error.localizedDescription)
        }
    }
}
