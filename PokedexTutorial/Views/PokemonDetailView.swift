//
//  PokemonDetailView.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Detail screen showing full Pokémon information: artwork, stats,
//               abilities, types, and type effectiveness. Demonstrates complex
//               layout composition, async data loading, and accessibility.
//  Author: enigmak9
//

import SwiftUI

/// The detail screen for a single Pokémon.
///
/// This view displays everything known about a Pokémon:
/// - Official artwork (large hero image)
/// - Base stats with colored progress bars
/// - Abilities with hidden ability indicator
/// - Types with effectiveness information
/// - National Pokédex number
///
/// Layout structure:
/// ```
/// ┌──────────────────────┐
/// │    [Artwork Image]   │  ← Hero image, tinted by primary type color
/// │    #0001 Bulbasaur   │  ← Name and Pokédex number
/// │  [Grass] [Poison]    │  ← Type badges
/// │                      │
/// │  Base Stats          │  ← Section header
/// │  HP  ████████░░ 45   │
/// │  Atk ██████████ 49   │       Repeated for all 6 stats
/// │  ...                 │
/// │                      │
/// │  Abilities           │  ← Section header
/// │  • Overgrow          │
/// │  • Chlorophyll (H)   │  ← "(H)" marks hidden abilities
/// └──────────────────────┘
/// ```
struct PokemonDetailView: View {

    // MARK: - State & Observed Objects

    /// The ViewModel managing the detail data fetch.
    @StateObject var viewModel: PokemonDetailViewModel

    /// Shared favorites store for the star toggle.
    @EnvironmentObject var favoritesStore: FavoritesStore

    /// Whether the type effectiveness section is expanded.
    @State private var showTypeEffectiveness: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch viewModel.state {
                case .idle, .loading:
                    loadingSection

                case .loaded(let detail):
                    heroSection(detail)
                    typeSection(detail)
                    statsSection(detail)
                    abilitiesSection(detail)
                    typeEffectivenessSection(detail)

                case .error(let message):
                    ErrorView(message: message) {
                        Task { await viewModel.fetchDetail() }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(viewModel.pokemonName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                favoriteButton
            }
        }
        .task {
            await viewModel.fetchDetail()
        }
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Pokemon data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Hero Section

    /// The top section showing the official artwork, name, and Pokédex number.
    ///
    /// The background is tinted with the Pokémon's primary type color at low opacity,
    /// creating a subtle themed appearance that changes with each Pokémon.
    private func heroSection(_ detail: PokemonDetail) -> some View {
        VStack(spacing: 12) {
            // Official artwork — large, high-resolution image.
            AsyncImage(url: detail.bestImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 250)
                        // Subtle shadow to lift the artwork off the background.
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                case .failure:
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                        .frame(height: 250)

                case .empty:
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 250)

                @unknown default:
                    EmptyView()
                }
            }

            // Name and Pokédex number.
            VStack(spacing: 4) {
                Text(detail.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(String(format: "#%04d", detail.id))
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            // Subtle gradient tinted with the primary type color.
            (detail.primaryType?.color ?? .gray)
                .opacity(0.15)
                .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Type Section

    /// Displays the Pokémon's types as colored badges.
    private func typeSection(_ detail: PokemonDetail) -> some View {
        HStack(spacing: 10) {
            ForEach(detail.pokemonTypes, id: \.self) { type in
                TypeBadgeView(type: type)
                    .scaleEffect(1.2) // Slightly larger than list badges
            }
        }
    }

    // MARK: - Stats Section

    /// Displays all six base stats with colored progress bars.
    ///
    /// Stats are sorted in the standard order:
    /// HP → Attack → Defense → Sp. Atk → Sp. Def → Speed
    private func statsSection(_ detail: PokemonDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Base Stats")

            VStack(spacing: 10) {
                ForEach(detail.stats) { stat in
                    StatBarView(
                        label: stat.displayName,
                        value: stat.baseStat,
                        maxValue: PokemonDetailViewModel.maxStatValue
                    )
                }
            }
            .padding(16)
            .cardStyle()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Abilities Section

    /// Lists all abilities with hidden abilities marked.
    ///
    /// Hidden abilities (slot 3) are shown with "(Hidden)" appended
    /// and a slightly muted text color to differentiate them.
    private func abilitiesSection(_ detail: PokemonDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Abilities")

            VStack(spacing: 0) {
                ForEach(Array(detail.abilities.enumerated()), id: \.element.id) { index, ability in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ability.displayName)
                                .font(.body)
                                .fontWeight(.medium)

                            if ability.isHidden {
                                Text("Hidden Ability")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }

                        Spacer()

                        if ability.isHidden {
                            Image(systemName: "eye.slash.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Divider between abilities (but not after the last one).
                    if index < detail.abilities.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .cardStyle()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Type Effectiveness Section

    /// Expandable section showing type matchups.
    ///
    /// Data is lazy-loaded: the network call only fires when the user
    /// expands this section, avoiding unnecessary API requests.
    private func typeEffectivenessSection(_ detail: PokemonDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Collapsible header.
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTypeEffectiveness.toggle()
                    // Lazy-load type relations when the user expands this section.
                    if showTypeEffectiveness {
                        Task { await viewModel.fetchTypeRelations() }
                    }
                }
            } label: {
                HStack {
                    sectionHeader("Type Effectiveness")
                    Spacer()
                    Image(systemName: showTypeEffectiveness ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Expanded content.
            if showTypeEffectiveness {
                typeEffectivenessContent
            }
        }
        .padding(.horizontal, 16)
    }

    /// The content shown when the type effectiveness section is expanded.
    @ViewBuilder
    private var typeEffectivenessContent: some View {
        switch viewModel.typeRelationsState {
        case .idle, .loading:
            HStack {
                ProgressView()
                Text("Loading type matchups...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cardStyle()

        case .loaded(let relations):
            VStack(spacing: 12) {
                typeRelationRow(
                    title: "Weak to (2x damage)",
                    types: relations.doubleDamageFrom,
                    color: .red
                )
                typeRelationRow(
                    title: "Resistant to (0.5x damage)",
                    types: relations.halfDamageFrom,
                    color: .green
                )
                typeRelationRow(
                    title: "Immune to (0x damage)",
                    types: relations.noDamageFrom,
                    color: .blue
                )
            }
            .padding(16)
            .cardStyle()

        case .error(let message):
            Text("Could not load type matchups: \(message)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .cardStyle()
        }
    }

    /// A single row in the type effectiveness list showing matching types.
    private func typeRelationRow(
        title: String,
        types: [PokemonDetail.TypeInfo],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)

            if types.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Wrap type chips that overflow to the next line.
                FlowLayout(spacing: 6) {
                    ForEach(types, id: \.name) { typeInfo in
                        if let pokemonType = PokemonType(rawValue: typeInfo.name) {
                            TypeBadgeView(type: pokemonType, showIcon: false)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Favorite Button

    /// Toolbar button to toggle this Pokémon as a favorite.
    private var favoriteButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoritesStore.toggle(viewModel.pokemonID)
            }
        } label: {
            Image(
                systemName: favoritesStore.isFavorite(viewModel.pokemonID)
                    ? "star.fill" : "star"
            )
            .foregroundColor(
                favoritesStore.isFavorite(viewModel.pokemonID)
                    ? .yellow : .gray
            )
        }
        .accessibilityLabel(
            favoritesStore.isFavorite(viewModel.pokemonID)
                ? "Remove from favorites"
                : "Add to favorites"
        )
    }

    // MARK: - Helpers

    /// Reusable section header text.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
    }
}

// MARK: - Flow Layout

/// A custom layout that arranges views horizontally, wrapping to the next line
/// when they exceed the available width.
///
/// This is similar to CSS flexbox with `flex-wrap: wrap`. SwiftUI doesn't have
/// a built-in flow layout (as of iOS 17), so we implement one using `Layout`.
///
/// This demonstrates the `Layout` protocol, new in iOS 16, which allows
/// building custom container views without `GeometryReader` hacks.
struct FlowLayout: Layout {

    /// The spacing between adjacent views, both horizontal and vertical.
    var spacing: CGFloat = 6

    // MARK: - Layout Protocol

    /// Returns the total size of the flow layout given the proposed width.
    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        guard !rows.isEmpty else { return .zero }

        let width = rows.map { row in
            row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + CGFloat(row.count - 1) * spacing
        }.max() ?? 0

        let height = rows.reduce(0) { $0 + rowHeight($1) } + CGFloat(rows.count - 1) * spacing

        return CGSize(width: width, height: height)
    }

    /// Positions each subview in the flow layout.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            let rowH = rowHeight(row)

            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(
                    at: CGPoint(x: x, y: y + (rowH - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }

            y += rowH + spacing
        }
    }

    // MARK: - Private Helpers

    /// Groups subviews into rows based on available width.
    private func computeRows(proposal: ProposedViewSize, subviews: LayoutSubviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let requiredWidth = currentRow.isEmpty ? size.width : currentWidth + spacing + size.width

            if requiredWidth <= maxWidth {
                currentRow.append(subview)
                currentWidth = requiredWidth
            } else {
                rows.append(currentRow)
                currentRow = [subview]
                currentWidth = size.width
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    /// Returns the height of a row (the maximum height among its subviews).
    private func rowHeight(_ row: [LayoutSubviews.Element]) -> CGFloat {
        row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PokemonDetailView(
            viewModel: PokemonDetailViewModel(
                pokemonID: 25,
                pokemonName: "pikachu",
                service: MockPokemonService(simulatedDelay: 0)
            )
        )
        .environmentObject(FavoritesStore())
    }
}
