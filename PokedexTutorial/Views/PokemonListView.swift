//
//  PokemonListView.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: The main Pokémon list screen. Displays Pokémon in a list or grid
//               with search, type filtering, favorites toggle, and pull-to-refresh.
//               Serves as the navigation root for the entire app.
//  Author: enigmak9
//

import SwiftUI

/// The primary screen of the Pokédex app.
///
/// This view orchestrates several features working together:
/// - **List/Grid toggle**: Switch between compact and expanded layouts
/// - **Search**: Real-time name search with Combine debouncing
/// - **Type filter**: Horizontally scrollable type chips
/// - **Favorites**: Star toggle persisted to UserDefaults
/// - **Navigation**: Tap a Pokémon to push the detail view
/// - **Pull-to-refresh**: Swipe down to reload from the API
/// - **Infinite scroll**: Loads more Pokémon as you scroll down
///
/// Architecture note: The view owns a `@StateObject` ViewModel. This ensures
/// the ViewModel's lifecycle is tied to this view — it's created when the view
/// appears and destroyed when the view is removed from the hierarchy.
struct PokemonListView: View {

    // MARK: - State & Observed Objects

    /// The ViewModel that drives this screen's data and logic.
    /// `@StateObject` tells SwiftUI this view OWNS the ViewModel.
    /// It survives view re-renders and is only recreated if the view is
    /// removed and re-added to the hierarchy.
    @StateObject var viewModel: PokemonListViewModel

    /// The shared favorites store, injected by the app entry point.
    @EnvironmentObject var favoritesStore: FavoritesStore

    /// Tracks whether to show only favorited Pokémon.
    @State private var showFavoritesOnly: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Pokedex")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search Pokemon by name"
                )
                .toolbar {
                    toolbarContent
                }
                .task {
                    // `.task` is the SwiftUI way to start async work when a view appears.
                    // It's automatically cancelled if the view disappears before completion.
                    await viewModel.fetchInitialData()
                }
                .navigationDestination(for: Pokemon.self) { pokemon in
                    // Value-based navigation: the NavigationLink passes a Pokemon value,
                    // and this destination builder creates the detail view for it.
                    // This pattern (iOS 16+) decouples the navigation source from the destination.
                    PokemonDetailView(
                        viewModel: PokemonDetailViewModel(
                            pokemonID: pokemon.id,
                            pokemonName: pokemon.name,
                            service: viewModel.service
                        )
                    )
                }
        }
    }

    // MARK: - Content View

    /// The main content: loading spinner, error message, or the Pokémon list.
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            // Initial state before any fetch. Shows nothing.
            EmptyView()

        case .loading:
            // First-page loading: centered spinner.
            ProgressView("Loading Pokemon...")
                .scaleEffect(1.2)

        case .loaded(let pokemon):
            // Success: render the list with type filter chips.
            VStack(spacing: 0) {
                typeFilterBar
                pokemonList(pokemon)
            }

        case .error(let message):
            // Error state with retry option.
            ErrorView(message: message) {
                Task { await viewModel.refresh() }
            }
        }
    }

    // MARK: - Type Filter Bar

    /// A horizontally scrollable row of type filter chips.
    ///
    /// The "All" chip clears the filter. Tapping a type chip sets it as the
    /// active filter; tapping it again clears it. Only one type can be
    /// selected at a time.
    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip — clears any active filter.
                FilterChipView(
                    type: nil,
                    isSelected: viewModel.selectedType == nil,
                    action: { viewModel.selectedType = nil }
                )

                // One chip per Pokémon type (18 total).
                ForEach(PokemonType.allCases, id: \.self) { type in
                    FilterChipView(
                        type: type,
                        isSelected: viewModel.selectedType == type,
                        action: {
                            // Toggle: tapping the selected chip deselects it.
                            if viewModel.selectedType == type {
                                viewModel.selectedType = nil
                            } else {
                                viewModel.selectedType = type
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Pokémon List

    /// The scrollable list (or grid) of Pokémon.
    ///
    /// Features:
    /// - **Infinite scroll**: when the user scrolls to the last few items, the next page loads
    /// - **Pull-to-refresh**: `.refreshable` adds the standard iOS pull-down gesture
    /// - **Empty state**: a helpful message appears when filters produce no results
    private func pokemonList(_ pokemon: [Pokemon]) -> some View {
        let displayedPokemon = showFavoritesOnly
            ? pokemon.filter { favoritesStore.isFavorite($0.id) }
            : pokemon

        return Group {
            if isGridLayout {
                // Grid layout: 2-column responsive grid of Pokémon cards.
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 160), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(displayedPokemon) { pokemon in
                            NavigationLink(value: pokemon) {
                                gridCell(pokemon)
                            }
                            .buttonStyle(.plain)
                            .task {
                                // Infinite scroll: when the last few items appear, load more.
                                await loadMoreIfNeeded(currentItem: pokemon, allItems: displayedPokemon)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Bottom loading indicator for pagination.
                    if viewModel.currentOffset > 0 && pokemon.count < 1302 {
                        ProgressView()
                            .padding()
                    }
                }
            } else {
                // List layout: standard iOS table-style list.
                List {
                    ForEach(displayedPokemon) { pokemon in
                        NavigationLink(value: pokemon) {
                            PokemonRowView(pokemon: pokemon)
                        }
                        .task {
                            await loadMoreIfNeeded(currentItem: pokemon, allItems: displayedPokemon)
                        }
                    }
                }
                .listStyle(.plain)
            }

            // Empty state when filters yield no matches.
            if displayedPokemon.isEmpty {
                ContentUnavailableView(
                    "No Pokemon Found",
                    systemImage: "magnifyingglass",
                    description: Text(
                        showFavoritesOnly
                            ? "You haven't favorited any Pokemon yet."
                            : "Try adjusting your search or filter."
                    )
                )
            }
        }
        .refreshable {
            // Pull-to-refresh: reload from page 1.
            await viewModel.refresh()
        }
    }

    // MARK: - Grid Cell

    /// A single cell in the grid layout, showing the sprite, name, and types.
    private func gridCell(_ pokemon: Pokemon) -> some View {
        VStack(spacing: 8) {
            // Pokémon sprite.
            AsyncImage(url: pokemon.spriteURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().interpolation(.none).scaledToFit()
                case .failure:
                    Image(systemName: "questionmark.circle.fill")
                        .font(.largeTitle).foregroundColor(.gray)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 80)

            // Name and number.
            VStack(spacing: 2) {
                Text(pokemon.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.primary).lineLimit(1)
                Text(String(format: "#%04d", pokemon.id))
                    .font(.caption2).foregroundColor(.secondary)
                    .monospacedDigit()
            }

            // Type badges.
            HStack(spacing: 4) {
                ForEach(pokemon.types, id: \.self) { type in
                    TypeBadgeView(type: type, showIcon: false)
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Favorites filter toggle.
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation {
                    showFavoritesOnly.toggle()
                }
            } label: {
                Label(
                    "Favorites",
                    systemImage: showFavoritesOnly ? "star.fill" : "star"
                )
            }
            .tint(showFavoritesOnly ? .yellow : .primary)
        }

        // List/Grid layout toggle.
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.isGridView.toggle()
                }
            } label: {
                Label(
                    viewModel.isGridView ? "List View" : "Grid View",
                    systemImage: viewModel.isGridView ? "list.bullet" : "square.grid.2x2"
                )
            }
        }
    }

    // MARK: - Helpers

    /// Whether the current layout mode is grid.
    private var isGridLayout: Bool {
        viewModel.isGridView
    }

    /// Triggers pagination when the user scrolls near the bottom of the list.
    ///
    /// "Near the bottom" is defined as within 5 items of the last displayed item.
    /// This pre-fetching ensures smooth scrolling — the next page is already
    /// loading by the time the user reaches the actual end.
    private func loadMoreIfNeeded(currentItem: Pokemon, allItems: [Pokemon]) async {
        let threshold = 5
        guard let index = allItems.firstIndex(where: { $0.id == currentItem.id }),
              allItems.count - index <= threshold else {
            return
        }
        await viewModel.loadNextPage()
    }
}

// MARK: - Error View

/// A reusable error display with a retry button.
///
/// Extracted as a shared view to keep the main view bodies clean
/// and focused on the happy path.
struct ErrorView: View {

    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Navigation Destination

extension PokemonListView {
    /// The view displayed when a Pokémon is selected for navigation.
    /// This is the detail screen, pushed onto the NavigationStack.
    static func detailView(
        for pokemon: Pokemon,
        service: any PokemonServiceProtocol
    ) -> some View {
        PokemonDetailView(
            viewModel: PokemonDetailViewModel(
                pokemonID: pokemon.id,
                pokemonName: pokemon.name,
                service: service
            )
        )
    }
}

// MARK: - Preview

#Preview {
    PokemonListView(
        viewModel: PokemonListViewModel(service: MockPokemonService())
    )
    .environmentObject(FavoritesStore())
}
