//
//  PokemonListViewModel.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: ViewModel for the Pokémon list screen. Manages fetching, filtering,
//               searching, and pagination logic. Owns the list's UI state.
//  Author: enigmak9
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for the main Pokémon list screen.
///
/// This ViewModel follows the MVVM pattern:
/// - **Model**: `Pokemon` structs (the data)
/// - **ViewModel**: This class (transforms data for the view)
/// - **View**: `PokemonListView` (renders the transformed data)
///
/// Key architectural decisions:
/// - Uses `@Published` for all UI-bound state so SwiftUI reacts automatically
/// - Relies on protocol-based dependency injection for testability
/// - Implements client-side filtering and search for responsive UX
/// - Uses Combine for debounced search input
@MainActor
final class PokemonListViewModel: ObservableObject {

    // MARK: - Published State

    /// The current loading state of the Pokémon list.
    /// The view observes this to show loading spinners, error messages, or content.
    @Published var state: LoadingState<[Pokemon]> = .idle

    /// The user's search query, bound to the `.searchable` modifier.
    /// Debounced to avoid filtering on every keystroke.
    @Published var searchText: String = ""

    /// The currently selected type filter, or `nil` to show all types.
    @Published var selectedType: PokemonType? = nil

    /// Whether the view is in grid mode (`true`) or list mode (`false`).
    @Published var isGridView: Bool = false

    /// The current page offset for pagination.
    @Published private(set) var currentOffset: Int = 0

    // MARK: - Private Properties

    /// The service used to fetch Pokémon data.
    /// Injected via the initializer — swap for `MockPokemonService` in tests.
    /// Internal access so the navigation destination can pass it to detail ViewModels.
    let service: any PokemonServiceProtocol

    /// The full unfiltered Pokémon array fetched from the service.
    /// Filtering/searching operates on this array and publishes results to `state`.
    private var allPokemon: [Pokemon] = []

    /// Maximum number of Pokémon to fetch per page.
    private let pageSize: Int

    /// Whether more Pokémon are available to load.
    private var hasMorePages: Bool = true

    /// Whether a fetch is currently in progress (prevents concurrent requests).
    private var isFetching: Bool = false

    /// Combine cancellables storage for the search debounce pipeline.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Creates a ViewModel with the given service dependency.
    /// - Parameters:
    ///   - service: The Pokémon data service (real API or mock).
    ///   - pageSize: Number of Pokémon per page (default 20).
    init(service: any PokemonServiceProtocol, pageSize: Int = 20) {
        self.service = service
        self.pageSize = pageSize
        setupSearchDebounce()
    }

    // MARK: - Public Methods

    /// Initiates the first data fetch. Call this when the view appears.
    ///
    /// Only fetches if the state is `.idle` (prevents redundant fetches).
    /// Subsequent pages are loaded via `loadNextPage()` for pagination.
    func fetchInitialData() async {
        guard case .idle = state else { return }
        await loadPage(offset: 0)
    }

    /// Loads the next page of Pokémon when the user scrolls to the bottom.
    /// Called by the view's `.task` modifier on the last visible row.
    func loadNextPage() async {
        guard hasMorePages, !isFetching else { return }
        await loadPage(offset: currentOffset + pageSize)
    }

    /// Refreshes the list from scratch (pull-to-refresh).
    /// Resets all pagination state and re-fetches page 1.
    func refresh() async {
        currentOffset = 0
        hasMorePages = true
        allPokemon = []
        await loadPage(offset: 0)
    }

    /// Returns the filtered Pokémon based on search text and type selection.
    ///
    /// Filtering is done client-side for responsiveness:
    /// 1. Filter by type (if a type filter is active)
    /// 2. Filter by name (if search text is non-empty)
    var filteredPokemon: [Pokemon] {
        var result = allPokemon

        // Apply type filter: only show Pokémon matching the selected type.
        if let selectedType = selectedType {
            result = result.filter { pokemon in
                pokemon.types.contains(selectedType)
            }
        }

        // Apply text search: match against the Pokémon name (case-insensitive).
        if !searchText.isEmpty {
            result = result.filter { pokemon in
                pokemon.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    // MARK: - Private Methods

    /// Fetches a single page from the service and updates the published state.
    /// - Parameter offset: The starting position for this page.
    private func loadPage(offset: Int) async {
        guard !isFetching else { return }
        isFetching = true

        if offset == 0 {
            state = .loading
        }

        do {
            let response = try await service.fetchPokemonList(limit: pageSize, offset: offset)

            if offset == 0 {
                allPokemon = response.results
            } else {
                allPokemon.append(contentsOf: response.results)
            }

            currentOffset = offset
            hasMorePages = response.next != nil
            state = .loaded(filteredPokemon)

        } catch {
            // If we already have data (e.g., pagination failed), keep showing it.
            if case .loaded = state {
                // Append error info but don't replace loaded data.
                // The view can show a toast or snackbar for pagination errors.
            } else {
                state = .error(error.localizedDescription)
            }
        }

        isFetching = false
    }

    /// Sets up a Combine pipeline that debounces search text input.
    ///
    /// Without debouncing, filtering would run on every keystroke, causing
    /// janky UI when searching through hundreds of Pokémon. Debouncing waits
    /// for the user to pause typing before applying the filter.
    ///
    /// Pipeline:
    /// ```
    /// $searchText (Publisher)
    ///   → .debounce (wait 300ms)
    ///   → .removeDuplicates (skip if same as previous)
    ///   → .sink (apply filter, update state)
    /// ```
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Re-publish filtered results when search text changes.
                if case .loaded = self.state {
                    self.state = .loaded(self.filteredPokemon)
                }
            }
            .store(in: &cancellables)
    }
}
