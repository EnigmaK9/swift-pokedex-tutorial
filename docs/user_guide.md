# Power User Guide — Pokédex Tutorial

**Created:** 2026-07-07 | **Last modified:** 2026-07-07 | **Author:** enigmak9

Advanced usage patterns, customization recipes, and architectural extension points for developers who want to go beyond the tutorial and build on top of this codebase.

---

## Table of Contents

1. [App Features Overview](#1-app-features-overview)
2. [Customization Recipes](#2-customization-recipes)
3. [Adding a New Feature](#3-adding-a-new-feature)
4. [Performance Profiling](#4-performance-profiling)
5. [Debugging Tips](#5-debugging-tips)
6. [Extension Points](#6-extension-points)
7. [Code Style Guide](#7-code-style-guide)
8. [Contributing Checklist](#8-contributing-checklist)

---

## 1. App Features Overview

### Main Screen

| Feature | Gesture/Control | Behavior |
|---------|----------------|----------|
| **Browse Pokémon** | Scroll vertically | Infinite scroll loads 20 at a time |
| **Search** | Pull down or tap search bar | Debounced (300ms), case-insensitive name search |
| **Filter by type** | Tap type chips (horizontal row) | Filters to matching type; tap again to clear |
| **Toggle favorites filter** | Tap star toolbar button | Shows only favorited Pokémon |
| **Switch list/grid** | Tap layout toolbar button | Toggles between list and 2-column grid |
| **Pull to refresh** | Swipe down from top | Reloads page 1 from API |
| **View detail** | Tap any Pokémon | Pushes detail screen |
| **Toggle favorite** | Tap star on any row | Adds/removes from persisted favorites |

### Detail Screen

| Feature | Location | Behavior |
|---------|----------|----------|
| **Artwork** | Top (hero section) | High-res official artwork, tinted background |
| **Pokédex number** | Below artwork | Formatted as #0001 |
| **Types** | Below name | Colored badges with icons |
| **Base stats** | Stats section | Color-coded bars (red→green→blue) |
| **Abilities** | Abilities section | Hidden abilities marked purple |
| **Type effectiveness** | Expandable section | Lazy-loaded weakness/resistance/immunity |
| **Favorite toggle** | Toolbar (star) | Same as list row — shared state |

### Data

| Source | Default | Fallback |
|--------|---------|----------|
| Pokémon list | PokéAPI v2 (live) | `MockPokemonService` (10 local) |
| Pokémon detail | PokéAPI v2 (live) | Mock JSON per ID |
| Images | GitHub PokeAPI/sprites (CDN) | SF Symbol placeholder |
| Type relations | PokéAPI v2 (lazy) | Empty (shown only on expand) |
| Favorites | UserDefaults (local) | Persisted across launches |

---

## 2. Customization Recipes

### 2.1 Change the Number of Pokémon per Page

**File:** `PokedexTutorial/ViewModels/PokemonListViewModel.swift`

```swift
// In PokemonListView:
@StateObject var viewModel = PokemonListViewModel(
    service: pokemonService,
    pageSize: 50  // Change from default 20 to 50
)
```

### 2.2 Adjust Search Debounce Timing

**File:** `PokedexTutorial/ViewModels/PokemonListViewModel.swift`

```swift
// In setupSearchDebounce(), change 300ms to your preference:
$searchText
    .debounce(for: .milliseconds(150), scheduler: RunLoop.main)  // Faster: 150ms
    // .debounce(for: .milliseconds(500), scheduler: RunLoop.main)  // Slower: 500ms
```

### 2.3 Change the Type Colors

**File:** `PokedexTutorial/Models/PokemonType.swift`

Each case in the `color` computed property returns a `Color`. Modify the RGB values to match your preferred color scheme. Colors are defined as `Color(red:green:blue:)` with values in the 0.0–1.0 range.

### 2.4 Add a New Pokémon Type

**File:** `PokedexTutorial/Models/PokemonType.swift`

1. Add a new case to the enum (e.g., `case shadow`)
2. Add color and icon entries in the respective switch statements
3. The type automatically appears in filter chips (via `CaseIterable`)

### 2.5 Switch to SwiftData for Favorites

If your favorites outgrow UserDefaults (e.g., you want to store notes or timestamps):

1. Create a `Favorite` `@Model` class with `id`, `dateAdded`, and `notes` properties
2. Replace `FavoritesStore` with a `ModelContainer`-backed store
3. Change `@EnvironmentObject` injection to use `.modelContainer` in the App
4. Views access favorites via `@Query` instead of `@EnvironmentObject`

The protocol-based architecture means no ViewModel or View changes are needed beyond the store swap.

### 2.6 Add Offline Support

```swift
// In PokemonAPIService, add a cache layer:
// 1. On successful fetch, cache the response to a local file
// 2. On network failure, attempt to read from cache
// 3. Return cached data with a "stale data" warning

func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse {
    do {
        let response = try await performNetworkFetch(limit: limit, offset: offset)
        try cacheResponse(response, for: "list_\(offset)")
        return response
    } catch PokemonServiceError.networkUnavailable {
        if let cached = try? loadCachedResponse(for: "list_\(offset)") {
            return cached  // Serve stale data offline
        }
        throw PokemonServiceError.networkUnavailable
    }
}
```

---

## 3. Adding a New Feature

Follow this recipe to add features while maintaining the architecture:

### Step-by-Step: Add "Pokémon Cries" (Play Sound)

**A. Model Layer** — Add audio URL to `PokemonDetail`:

```swift
// In PokemonDetail.swift, add:
let cries: Cries?

struct Cries: Codable, Equatable {
    let latest: String?   // URL to latest-generation cry
    let legacy: String?   // URL to legacy cry
}
```

**B. Service Layer** — No change needed (URL comes from existing detail endpoint).

**C. ViewModel Layer** — Add play trigger:

```swift
// In PokemonDetailViewModel.swift, add:
func playCry() {
    guard let detail = state.value,
          let cryURL = detail.cries?.latest else { return }
    // Post notification or use AVPlayer
}
```

**D. View Layer** — Add play button:

```swift
// In PokemonDetailView.swift, add a toolbar button:
ToolbarItem(placement: .navigationBarTrailing) {
    Button { viewModel.playCry() } label: {
        Image(systemName: "speaker.wave.2.fill")
    }
    .disabled(viewModel.detail?.cries?.latest == nil)
}
```

**E. Tests** — Add decoding test for the new JSON field.

---

## 4. Performance Profiling

### Key Metrics to Watch

| Metric | Target | Tool |
|--------|--------|------|
| First list load | < 2s on WiFi | Instruments > Network |
| Scroll FPS | 60 fps | Instruments > Core Animation |
| Memory (list) | < 80 MB for 200+ Pokémon | Xcode Debug Navigator |
| Memory (detail) | < 50 MB per detail view | Xcode Debug Navigator |
| Search responsiveness | < 100ms after debounce | Instruments > Time Profiler |
| App launch | < 1s cold start | Instruments > App Launch |

### Profiling Commands

```bash
# Profile with Instruments (Time Profiler template)
xcrun xctrace record --template 'Time Profiler' \
  --attach com.enigmak9.PokedexTutorial \
  --time-limit 30s \
  --output profile.trace

# Check memory usage
xcrun simctl spawn booted leaks com.enigmak9.PokedexTutorial

# Measure cold launch time
xcrun xcresulttool get --path result.xcresult --format json \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['metrics']['appLaunch'])"  # placeholder
```

### Known Optimizations

1. **Image caching**: `AsyncImage` uses URLSession's shared cache by default. For a production app, configure a larger `URLCache`:
   ```swift
   let cache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000)
   URLCache.shared = cache
   ```

2. **List performance**: `LazyVGrid` with `ForEach` is already lazy-loaded. For very large lists (500+), consider using `.id()` on rows to help SwiftUI's diffing.

3. **Search**: The Combine debounce prevents filtering on every keystroke. The current 300ms is optimal for most users.

---

## 5. Debugging Tips

### Enable Network Logging

```swift
// In PokemonAPIService.performRequest, add before the return:
#if DEBUG
print("🌐 [PokedexAPI] \(url.absoluteString) → HTTP \(httpResponse.statusCode)")
print("📦 [PokedexAPI] Response size: \(data.count) bytes")
#endif
```

### Inspect the View Hierarchy

```bash
# In the simulator, press Cmd+Shift+D to toggle the debug HUD,
# or use:
xcrun simctl ui booted appearance
```

### Debug Combine Pipelines

```swift
// In PokemonListViewModel.setupSearchDebounce(), add:
$searchText
    .handleEvents(receiveOutput: { text in
        print("🔍 Search text changed: '\(text)'")
    })
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    // ...
```

### Debug @Published Updates

```swift
// In any ViewModel, use didSet on @Published:
@Published var state: LoadingState<[Pokemon]> = .idle {
    didSet {
        print("🔄 State changed: \(state)")
    }
}
```

---

## 6. Extension Points

The architecture has explicit extension points designed for modification:

| Extension Point | Location | What You Can Do |
|----------------|----------|-----------------|
| **Service Protocol** | `PokemonServiceProtocol` | Add new data sources (GraphQL, SQLite, Firebase) |
| **LoadingState** | `LoadingState<T>` | Add new states (`.cached`, `.stale`) |
| **PokemonType** | Enum cases + properties | Add types, change colors, add icons |
| **FavoritesStore** | `Stores/` | Swap UserDefaults for SwiftData/CloudKit |
| **View Extensions** | `View+Extensions.swift` | Add shared modifiers (`.shimmer()`, `.skeleton()`) |
| **FilterChipView** | `Views/` | Generalize to `FilterChip<T: Filterable>` |
| **FlowLayout** | `PokemonDetailView.swift` | Extract to reusable component |

---

## 7. Code Style Guide

Every file follows these conventions:

```swift
//
//  FileName.swift
//  PokedexTutorial
//
//  Created: YYYY-MM-DD
//  Last modified: YYYY-MM-DD
//  Description: One-line summary of what this file does.
//  Author: enigmak9
//

import Foundation

// MARK: - Type Name

/// Documentation comment explaining the type's purpose.
/// Includes usage examples, edge cases, and design rationale.
struct TypeName {
    // MARK: - Properties
    // MARK: - Initialization
    // MARK: - Public Methods
    // MARK: - Private Methods
}

// MARK: - Protocol Conformance

extension TypeName: SomeProtocol {
    // ...
}
```

Rules:
- **Immutability first**: Prefer `let` over `var` unless the value changes
- **No force-unwrapping**: Use `guard let` or optional chaining
- **No `print` in production**: Use `#if DEBUG` or proper logging
- **Comments explain WHY, not WHAT**: The code says what; comments say why
- **200–400 lines per file**: Split before 800 lines
- **Mark sections**: Use `// MARK: -` before every logical section

---

## 8. Contributing Checklist

Before submitting changes:

- [ ] Build succeeds: `xcodebuild ... build`
- [ ] All 24 tests pass: `xcodebuild ... test`
- [ ] New code follows the file header convention
- [ ] New public methods have documentation comments
- [ ] ViewModels are `@MainActor` if they have `@Published` properties
- [ ] Services are protocol-backed (can be mocked for tests)
- [ ] New features have corresponding tests
- [ ] No force-unwrapping introduced
- [ ] No `print()` statements remain (use `#if DEBUG` or remove)
- [ ] File modified date is updated in the header
- [ ] No dead code or commented-out blocks

---

## Key Files Reference

| File | Lines | Purpose |
|------|-------|---------|
| `Pokemon.swift` | ~120 | Core model with custom JSON decoding |
| `PokemonAPIService.swift` | ~190 | Full API client with error handling |
| `PokemonListView.swift` | ~320 | Most complex view: search, filter, pagination, grid |
| `PokemonDetailView.swift` | ~500 | Layout-heavy detail screen with FlowLayout |
| `PokemonListViewModel.swift` | ~190 | State management, Combine, filtering |

---

*For the architectural rationale behind these patterns, see [architecture.md](architecture.md). For visual flow diagrams, see [flowcharts.md](flowcharts.md).*
