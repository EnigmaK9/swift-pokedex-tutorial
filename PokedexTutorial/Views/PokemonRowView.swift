//
//  PokemonRowView.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: A single row in the Pokémon list displaying the sprite, name,
//               national Pokédex number, type badges, and a favorite toggle.
//  Author: enigmak9
//

import SwiftUI

/// A row component for displaying a Pokémon in the list or grid.
///
/// This view demonstrates several SwiftUI concepts:
/// - **@EnvironmentObject**: accessing shared state (favorites) without explicit passing
/// - **AsyncImage**: loading remote images with built-in placeholder/error handling
/// - **View composition**: building complex rows from smaller, reusable pieces
struct PokemonRowView: View {

    // MARK: - Properties

    /// The Pokémon to display in this row.
    let pokemon: Pokemon

    // MARK: - Environment

    /// The shared favorites store, provided by the app's root view.
    /// Using @EnvironmentObject avoids passing this through every view in the hierarchy.
    @EnvironmentObject var favoritesStore: FavoritesStore

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {

            // MARK: Sprite
            // AsyncImage handles the full lifecycle of loading a remote image:
            // 1. Shows nothing while loading (or a placeholder in the closure)
            // 2. Displays the image on success
            // 3. Shows a fallback on failure
            AsyncImage(url: pokemon.spriteURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .interpolation(.none) // Preserves pixel art sharpness
                        .scaledToFit()
                        .frame(width: 56, height: 56)

                case .failure:
                    // Fallback: a placeholder icon when the sprite fails to load.
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                        .frame(width: 56, height: 56)

                case .empty:
                    // Loading placeholder: a subtle progress indicator.
                    ProgressView()
                        .frame(width: 56, height: 56)

                @unknown default:
                    EmptyView()
                }
            }

            // MARK: Name & Number
            VStack(alignment: .leading, spacing: 4) {
                Text(pokemon.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                // National Pokédex number with leading zeros for consistency.
                Text(String(format: "#%04d", pokemon.id))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            // MARK: Type Badges
            // Display up to 2 types. Most Pokémon have 1-2 types.
            HStack(spacing: 6) {
                ForEach(pokemon.types, id: \.self) { type in
                    TypeBadgeView(type: type)
                }
            }

            // MARK: Favorite Button
            // Tapping the star toggles the favorite status.
            // The animation provides visual feedback: the star "pops" when toggled.
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    favoritesStore.toggle(pokemon.id)
                }
            } label: {
                Image(systemName: favoritesStore.isFavorite(pokemon.id) ? "star.fill" : "star")
                    .foregroundColor(favoritesStore.isFavorite(pokemon.id) ? .yellow : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain) // Prevents the whole row from being tappable
            .accessibilityLabel(
                favoritesStore.isFavorite(pokemon.id)
                    ? "Remove \(pokemon.displayName) from favorites"
                    : "Add \(pokemon.displayName) to favorites"
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    List {
        PokemonRowView(
            pokemon: Pokemon(
                id: 25,
                name: "pikachu",
                url: nil,
                types: [.electric],
                imageURL: nil
            )
        )
        PokemonRowView(
            pokemon: Pokemon(
                id: 1,
                name: "bulbasaur",
                url: nil,
                types: [.grass, .poison],
                imageURL: nil
            )
        )
    }
    .environmentObject(FavoritesStore())
}
