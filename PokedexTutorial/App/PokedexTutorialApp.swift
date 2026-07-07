//
//  PokedexTutorialApp.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: The @main entry point for the Pokédex Tutorial app.
//               Configures the dependency injection, creates the root view,
//               and sets up the application-wide environment.
//  Author: enigmak9
//

import SwiftUI

/// The entry point of the Pokédex Tutorial application.
///
/// Conforms to the `App` protocol (iOS 14+) which replaces the older
/// `UIApplicationDelegate` pattern for SwiftUI-based apps.
///
/// This is where:
/// - Dependency injection is configured (swapping services for testing/mocking)
/// - Global environment objects are attached to the view hierarchy
/// - The root scene and initial view are declared
@main
struct PokedexTutorialApp: App {

    // MARK: - State Objects

    /// The service responsible for fetching Pokémon data.
    ///
    /// We default to the real API service. For development or testing,
    /// swap this with `MockPokemonService()` to use local fixture data
    /// and avoid network calls.
    ///
    /// ```swift
    /// // For development without network:
    /// @StateObject private var pokemonService: PokemonServiceProtocol = MockPokemonService()
    /// ```
    @StateObject private var pokemonService: PokemonAPIService = PokemonAPIService()

    /// The shared favorites store persisted to UserDefaults.
    /// Attached as an environment object so all child views can access it
    /// without explicit passing through the view hierarchy.
    @StateObject private var favoritesStore = FavoritesStore()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            PokemonListView(
                viewModel: PokemonListViewModel(service: pokemonService)
            )
            .environmentObject(favoritesStore)
        }
    }
}
