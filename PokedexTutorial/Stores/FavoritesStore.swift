//
//  FavoritesStore.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: ObservableObject that persists favorite Pokémon IDs using UserDefaults.
//               Shared across the app via @EnvironmentObject for consistent state.
//  Author: enigmak9
//

import Foundation
import SwiftUI

/// Manages the set of favorited Pokémon IDs with UserDefaults persistence.
///
/// This class demonstrates:
/// - **ObservableObject**: SwiftUI watches published changes and re-renders views
/// - **UserDefaults**: Simple key-value persistence for small data sets
/// - **@Published**: Property wrapper that emits change notifications
///
/// For larger data sets or relational data, consider upgrading to SwiftData
/// or Core Data. UserDefaults is ideal for small, flat collections like this.
///
/// Usage in views:
/// ```swift
/// @EnvironmentObject var favoritesStore: FavoritesStore
/// Button { favoritesStore.toggle(pokemon.id) } label: {
///     Image(systemName: favoritesStore.isFavorite(pokemon.id) ? "star.fill" : "star")
/// }
/// ```
final class FavoritesStore: ObservableObject {

    // MARK: - UserDefaults Key

    /// The key used to store favorites in UserDefaults.
    /// Using a namespaced key prevents collisions with other stored values.
    private static let storageKey = "com.pokedextutorial.favorites"

    // MARK: - Published Properties

    /// The set of favorited Pokémon IDs.
    ///
    /// `@Published` triggers SwiftUI view updates whenever this set changes.
    /// Using a `Set<Int>` gives O(1) lookup performance for `isFavorite(_:)`.
    @Published private var favoriteIDs: Set<Int> = []

    // MARK: - Initialization

    /// Creates a favorites store, loading any previously saved favorites from UserDefaults.
    ///
    /// The load happens synchronously in `init` because:
    /// - UserDefaults reads are near-instant (memory-backed on device)
    /// - Favorites should be available before the first view renders
    init() {
        loadFavorites()
    }

    // MARK: - Public API

    /// Checks whether a Pokémon is in the user's favorites.
    /// - Parameter id: The Pokémon's ID to check.
    /// - Returns: `true` if the Pokémon is favorited.
    func isFavorite(_ id: Int) -> Bool {
        favoriteIDs.contains(id)
    }

    /// Toggles the favorite status for a Pokémon.
    ///
    /// If currently favorited, removes it. If not favorited, adds it.
    /// Changes are immediately persisted to UserDefaults.
    ///
    /// - Parameter id: The Pokémon's ID to toggle.
    func toggle(_ id: Int) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        saveFavorites()
    }

    /// Returns the total count of favorited Pokémon.
    var count: Int {
        favoriteIDs.count
    }

    /// Returns all favorited Pokémon IDs as a sorted array.
    var allFavorites: [Int] {
        favoriteIDs.sorted()
    }

    // MARK: - Persistence

    /// Loads the favorites set from UserDefaults.
    ///
    /// UserDefaults stores arrays natively. We convert to `Set<Int>` for
    /// O(1) lookup performance during list rendering.
    private func loadFavorites() {
        guard let savedArray = UserDefaults.standard.array(forKey: Self.storageKey) as? [Int] else {
            favoriteIDs = []
            return
        }
        favoriteIDs = Set(savedArray)
    }

    /// Persists the current favorites set to UserDefaults.
    ///
    /// Called after every toggle. UserDefaults writes are synchronous and fast
    /// for small data sets, so no async handling is needed.
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: Self.storageKey)
    }
}
