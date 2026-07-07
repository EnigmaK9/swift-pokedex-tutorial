//
//  PokemonDetailViewModel.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: ViewModel for the Pokémon detail screen. Fetches full Pokémon
//               detail data including stats, abilities, sprites, and type relations.
//  Author: enigmak9
//

import Foundation

/// ViewModel for the Pokémon detail screen.
///
/// Manages fetching the full detail data for a single Pokémon, including
/// stats, abilities, and type effectiveness information.
///
/// Uses `@MainActor` because all `@Published` property updates must happen
/// on the main thread (they trigger UI updates).
@MainActor
final class PokemonDetailViewModel: ObservableObject {

    // MARK: - Published State

    /// The current state of the detail data fetch.
    @Published var state: LoadingState<PokemonDetail> = .idle

    /// The current state of the type relations fetch (lazy-loaded).
    @Published var typeRelationsState: LoadingState<PokemonDetail.TypeRelations> = .idle

    // MARK: - Properties

    /// The Pokémon ID being viewed.
    let pokemonID: Int

    /// The Pokémon's name (available from the list response, shown while detail loads).
    let pokemonName: String

    // MARK: - Private Properties

    /// The service used to fetch detail data.
    private let service: any PokemonServiceProtocol

    // MARK: - Initialization

    /// Creates a detail ViewModel for a specific Pokémon.
    /// - Parameters:
    ///   - pokemonID: The Pokémon's national Pokédex number.
    ///   - pokemonName: The Pokémon's name (shown in the navigation title).
    ///   - service: The data service for fetching detail information.
    init(
        pokemonID: Int,
        pokemonName: String,
        service: any PokemonServiceProtocol
    ) {
        self.pokemonID = pokemonID
        self.pokemonName = pokemonName
        self.service = service
    }

    // MARK: - Public Methods

    /// Fetches the full detail data for this Pokémon.
    ///
    /// Called when the detail view appears. Only fetches if not already loaded.
    func fetchDetail() async {
        guard case .idle = state else { return }

        state = .loading

        do {
            let detail = try await service.fetchPokemonDetail(id: pokemonID)
            state = .loaded(detail)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Fetches type effectiveness data for the Pokémon's primary type.
    ///
    /// This is called lazily — only when the user taps to view type effectiveness.
    /// This pattern avoids unnecessary network calls for data the user may never see.
    func fetchTypeRelations() async {
        guard case .loaded(let detail) = state,
              let primaryType = detail.primaryType else { return }

        typeRelationsState = .loading

        do {
            let relations = try await service.fetchTypeRelations(name: primaryType.rawValue)
            typeRelationsState = .loaded(relations)
        } catch {
            typeRelationsState = .error(error.localizedDescription)
        }
    }

    // MARK: - Computed Properties

    /// Returns the loaded detail, or `nil` if not yet loaded.
    var detail: PokemonDetail? {
        state.value
    }

    /// The maximum base stat value among all stats (used to normalize the stat bars).
    /// The highest possible base stat in Pokémon is 255 (Blissey's HP),
    /// so we cap the bar at 255 for consistent visual scaling.
    static var maxStatValue: Double { 255.0 }
}
