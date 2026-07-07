# Architecture Guide — Pokédex Tutorial

**Created:** 2026-07-07 | **Last modified:** 2026-07-07 | **Author:** enigmak9

A comprehensive reference for the architectural decisions, patterns, and data flow in the Pokédex Tutorial app. This document is intended for developers who want to understand _why_ the code is structured the way it is, not just _what_ it does.

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [MVVM Pattern](#2-mvvm-pattern)
3. [Layer-by-Layer Breakdown](#3-layer-by-layer-breakdown)
4. [Data Flow](#4-data-flow)
5. [Dependency Injection](#5-dependency-injection)
6. [Navigation Architecture](#6-navigation-architecture)
7. [State Management](#7-state-management)
8. [Concurrency Model](#8-concurrency-model)
9. [Testing Strategy](#9-testing-strategy)
10. [Key Design Decisions](#10-key-design-decisions)

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      App Entry Point                      │
│                  PokedexTutorialApp.swift                 │
│              @main • Dependency Injection • Env          │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
     ┌────▼─────┐            ┌──────▼──────┐
     │   Views   │◄──reads───│  ViewModels  │
     │  SwiftUI  │──writes──►│  @Published  │
     └──────────┘            └──────┬──────┘
                                    │
                             ┌──────▼──────┐
                             │   Services   │
                             │  (Protocol)  │
                             └──────┬──────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
              ┌─────▼─────┐  ┌──────▼──────┐  ┌─────▼─────┐
              │  PokéAPI   │  │    Mock     │  │  Local    │
              │  Service   │  │   Service   │  │   JSON    │
              └────────────┘  └────────────┘  └───────────┘
                     │
              ┌──────▼──────┐
              │    Models    │
              │  (Codable)   │
              └─────────────┘
```

The app follows a **unidirectional data flow**: Services fetch data → ViewModels transform it → Views render it. User actions flow back through ViewModels to Services, never directly from Views to Models.

---

## 2. MVVM Pattern

### Why MVVM?

| Pattern | Pros | Cons | Verdict |
|---------|------|------|---------|
| **MVC** | Simple, Apple's default | Massive ViewControllers, tight coupling | Poor for SwiftUI |
| **MVVM** | Testable ViewModels, clean separation | More boilerplate | Best for SwiftUI |
| **TCA** | Predictable state, great debugging | Steep learning curve, heavy framework | Overkill for this scope |
| **VIPER** | Very modular | Excessive files, complex for small apps | Overkill |

**MVVM was chosen** because it maps naturally to SwiftUI's observation system (`@Published` → `@StateObject` → View re-render), provides clean separation for unit testing, and is the most widely adopted pattern in the iOS community.

### Responsibilities

```
┌──────────────────────────────────────────────────────────────┐
│                            VIEW                              │
│  • Declares layout (VStack, List, etc.)                      │
│  • Binds to ViewModel's @Published properties                │
│  • Forwards user actions to ViewModel methods                │
│  • NEVER contains business logic                             │
│  • NEVER accesses Services directly                          │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ @ObservedObject / @StateObject
                              │
┌──────────────────────────────────────────────────────────────┐
│                         VIEWMODEL                            │
│  • Owns UI state (@Published)                                │
│  • Transforms model data for display                         │
│  • Orchestrates service calls                                │
│  • Handles user intent (search, filter, toggle)              │
│  • @MainActor — all @Published updates on main thread        │
│  • NEVER imports SwiftUI (except for color/animation types)  │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ Protocol reference
                              │
┌──────────────────────────────────────────────────────────────┐
│                          SERVICE                             │
│  • Fetches raw data (network, local, mock)                   │
│  • Handles errors (throws typed errors)                      │
│  • Returns decoded models                                    │
│  • Stateless — no stored UI state                            │
│  • Protocol-based for testability                            │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Layer-by-Layer Breakdown

### 3.1 Models Layer (`Models/`)

| File | Purpose | Key Protocols |
|------|---------|---------------|
| `Pokemon.swift` | Core Pokémon entity with custom JSON decoding that extracts `id` from URL when the API omits it | `Codable`, `Identifiable`, `Hashable`, `Equatable` |
| `PokemonType.swift` | 18-type enum with brand colors and SF Symbol icons | `Codable`, `CaseIterable` |
| `PokemonDetail.swift` | Full detail model: stats, abilities, sprites, type entries | `Codable`, `Equatable` |
| `LoadingState.swift` | Generic enum: `.idle`, `.loading`, `.loaded(T)`, `.error(String)` | `Equatable` |

**Design decision:** `Pokemon` uses a custom `init(from decoder:)` because the PokéAPI list endpoint omits the `id` field (it's embedded in the URL). The custom decoder tries `id` first, then falls back to parsing the URL's last path component. This avoids maintaining separate list and detail models.

### 3.2 Services Layer (`Services/`)

```
PokemonServiceProtocol (protocol)
    │
    ├── PokemonAPIService (production)
    │   • URLSession.shared
    │   • async/await networking
    │   • Typed error handling (PokemonServiceError)
    │   • HTTP status validation
    │   • Decoding diagnostics
    │
    └── MockPokemonService (development/testing)
        • Bundled JSON fixture
        • Simulated latency (configurable)
        • Deterministic results
```

**Design decision:** The protocol is marked `AnyObject` because services are reference types (`final class`). This enables `@StateObject` ownership in SwiftUI views and allows the compiler to optimize witness table dispatch.

### 3.3 ViewModels Layer (`ViewModels/`)

**PokemonListViewModel:**
- `@Published var state: LoadingState<[Pokemon]>` — drives the list UI
- `@Published var searchText: String` — bound to `.searchable`
- `@Published var selectedType: PokemonType?` — type filter
- `@Published var isGridView: Bool` — layout toggle
- Combine pipeline for debounced search (300ms)
- Pagination state management (`currentOffset`, `hasMorePages`, `isFetching`)

**PokemonDetailViewModel:**
- `@Published var state: LoadingState<PokemonDetail>`
- `@Published var typeRelationsState: LoadingState<PokemonDetail.TypeRelations>`
- Lazy-loads type effectiveness data (only fetches when user expands section)
- `@MainActor` ensures all published updates happen on the main thread

### 3.4 Views Layer (`Views/`)

| View | Complexity | Key Concepts Demonstrated |
|------|-----------|--------------------------|
| `PokemonListView` | High | NavigationStack, .searchable, .task, .refreshable, infinite scroll, List/Grid toggle |
| `PokemonDetailView` | High | ScrollView layout, AsyncImage, custom Layout protocol, expandable sections |
| `PokemonRowView` | Medium | AsyncImage phases, @EnvironmentObject, accessibility labels |
| `TypeBadgeView` | Low | Reusable component, Label view, Capsule shape |
| `StatBarView` | Medium | GeometryReader, color-coded bars, accessibility |
| `FilterChipView` | Low | Toggle-style button, selected/deselected states |

### 3.5 Stores Layer (`Stores/`)

**FavoritesStore:**
- `ObservableObject` with `@Published` favorite IDs
- `UserDefaults` persistence (load on init, save on every toggle)
- `Set<Int>` for O(1) lookup
- Injected via `@EnvironmentObject` — available to all views without prop drilling

---

## 4. Data Flow

### 4.1 List Loading Flow

```
User opens app
    │
    ▼
PokemonListView appears (.task)
    │
    ▼
PokemonListViewModel.fetchInitialData()
    │
    ├── state = .loading ──────────────► View shows ProgressView
    │
    ├── service.fetchPokemonList(limit:20, offset:0)
    │       │
    │       ├── PokemonAPIService.performRequest(url:)
    │       │       │
    │       │       ├── URLSession.data(from:) [await]
    │       │       ├── Validate HTTP 2xx
    │       │       └── Return raw Data
    │       │
    │       └── decode(PokemonListResponse.self, from: data)
    │               │
    │               ├── JSONDecoder.decode(...)
    │               └── Custom Pokemon decoder extracts IDs from URLs
    │
    ├── state = .loaded(pokemon) ──────► View renders List/Grid
    │
    └── On error:
        state = .error(message) ───────► View shows ErrorView with retry
```

### 4.2 Search Flow

```
User types in search bar
    │
    ▼
$viewModel.searchText is updated (via binding)
    │
    ▼
Combine pipeline:
    $searchText
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .removeDuplicates()
        .sink { [weak self] _ in
            self?.state = .loaded(self?.filteredPokemon ?? [])
        }
    │
    ▼
filteredPokemon computed property:
    1. Filter by selectedType (if non-nil)
    2. Filter by name (case-insensitive contains)
    │
    ▼
state = .loaded(filteredResults) ──────► View re-renders
```

### 4.3 Favorites Flow

```
User taps star button
    │
    ▼
favoritesStore.toggle(pokemon.id)
    │
    ├── favoriteIDs.insert(id) or .remove(id)
    ├── saveFavorites() → UserDefaults.standard.set(...)
    │
    ▼
@Published triggers view update
    │
    ▼
PokemonRowView re-renders:
    star.fill (yellow) or star (gray)
```

---

## 5. Dependency Injection

### Approach: Constructor Injection with Protocol Types

```swift
// The ViewModel depends on the protocol, not the concrete class.
// At init time, any conforming service can be injected.
final class PokemonListViewModel: ObservableObject {
    let service: any PokemonServiceProtocol

    init(service: any PokemonServiceProtocol, pageSize: Int = 20) {
        self.service = service
        // ...
    }
}

// Production: real API
let vm = PokemonListViewModel(service: PokemonAPIService())

// Testing: mock with instant responses
let vm = PokemonListViewModel(service: MockPokemonService(simulatedDelay: 0))

// Previews: mock with realistic latency
let vm = PokemonListViewModel(service: MockPokemonService(simulatedDelay: 500_000_000))
```

### Why not `@EnvironmentObject` for services?

`@EnvironmentObject` is used for `FavoritesStore` (app-wide shared state) but **not** for services. Services are injected via constructor because:

1. **Explicit dependencies** — you can see what a ViewModel needs from its initializer
2. **Compile-time safety** — missing an `@EnvironmentObject` crashes at runtime
3. **Testability** — constructor injection makes swapping implementations trivial
4. **Preview isolation** — each preview can have its own service instance

---

## 6. Navigation Architecture

### Value-Based Navigation (iOS 16+)

```swift
NavigationStack {
    List {
        ForEach(pokemon) { pokemon in
            NavigationLink(value: pokemon) {  // Pass the Pokemon VALUE
                PokemonRowView(pokemon: pokemon)
            }
        }
    }
    .navigationDestination(for: Pokemon.self) { pokemon in
        PokemonDetailView(                    // Destination built from value
            viewModel: PokemonDetailViewModel(
                pokemonID: pokemon.id,
                pokemonName: pokemon.name,
                service: viewModel.service
            )
        )
    }
}
```

**Why value-based?** The older `NavigationLink(destination:label:)` eagerly constructs the destination view for every row. With 1302 Pokémon, that's a memory problem. Value-based navigation constructs the destination lazily, only when navigation occurs.

**Why `Pokemon` as the navigation value?** Because `Pokemon` conforms to `Hashable`, SwiftUI can track which value is currently presented and handle back-navigation and deep-linking automatically.

---

## 7. State Management

### State Ownership Hierarchy

```
PokedexTutorialApp (@main)
├── @StateObject var pokemonService: PokemonAPIService
├── @StateObject var favoritesStore = FavoritesStore()
│
└── PokemonListView
    ├── @StateObject var viewModel: PokemonListViewModel
    │       (owns: searchText, selectedType, isGridView, state, offset)
    │
    ├── @EnvironmentObject var favoritesStore: FavoritesStore
    │       (shared: read in rows, written on star tap)
    │
    └── NavigationLink → PokemonDetailView
        ├── @StateObject var viewModel: PokemonDetailViewModel
        │       (owns: state, typeRelationsState)
        │
        └── @EnvironmentObject var favoritesStore: FavoritesStore
                (shared: star button in toolbar)
```

### Wrapper Cheat Sheet

| Wrapper | When to Use | Lifecycle |
|---------|------------|-----------|
| `@State` | Local view state (toggle, text field) | Tied to view lifetime |
| `@Binding` | Pass read-write access to parent's state | References parent's @State |
| `@StateObject` | View OWNS the ObservableObject | Created once, survives re-renders |
| `@ObservedObject` | View RECEIVES an ObservableObject | Recreated on re-render if passed in |
| `@EnvironmentObject` | Access shared state without explicit passing | Injected by ancestor, crash if missing |
| `@Published` | Inside ObservableObject, triggers view updates | Tied to ObservableObject lifetime |

---

## 8. Concurrency Model

### Structured Concurrency with async/await

```
┌─────────────────────────────────────────────────────────┐
│                      Main Actor                          │
│  (@MainActor ViewModels)                                 │
│                                                          │
│  • All @Published updates happen here                    │
│  • UI updates happen here                                │
│  • Combine pipelines run on RunLoop.main                 │
└──────────────┬──────────────────────────────────────────┘
               │
               │ await service.fetchPokemonList(...)
               │ (suspends — frees main thread)
               │
┌──────────────▼──────────────────────────────────────────┐
│                   Background (URLSession)                 │
│                                                          │
│  • Network I/O runs on URLSession's delegate queue       │
│  • JSON decoding happens on cooperative thread pool      │
│  • No explicit DispatchQueue management needed           │
└─────────────────────────────────────────────────────────┘
```

**Key points:**
- ViewModels are `@MainActor` — the compiler guarantees `@Published` updates happen on the main thread
- `await` suspends the ViewModel without blocking the main thread
- `Task.sleep` in the mock service simulates async work cooperatively
- No `DispatchQueue.main.async` needed — structured concurrency handles it

---

## 9. Testing Strategy

### Test Pyramid

```
         ┌──────┐
         │  UI   │  XCUITest: critical flows only
         │ Tests │  (launch, navigate, search)
         ├──────┤
         │  API  │  Integration: real PokéAPI
         │ Tests │  (fetch list, detail, types)
         ├──────┤
         │ ViewM │  Unit: ViewModel logic
         │ Tests │  (filter, search, pagination)
         ├──────┤
         │ Model │  Unit: Codable, computed props
         │ Tests │  (decode, displayName, spriteURL)
         └──────┘
```

### Test Coverage

| Layer | Tests | What's Verified |
|-------|-------|-----------------|
| **Model** | 7 tests | JSON decoding, computed properties, Equatable/Hashable |
| **ViewModel** | 10 tests | State transitions, search filter, pagination, initial state |
| **API Integration** | 7 tests | Real API structure, known data points, pagination |
| **UI** | 6 tests | App launch, navigation, search, favorites, layout toggle |

### Mocking Strategy

```swift
// The protocol is the seam.
protocol PokemonServiceProtocol: AnyObject {
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponse
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail
    func fetchTypeRelations(name: String) async throws -> PokemonDetail.TypeRelations
}

// Tests inject MockPokemonService(simulatedDelay: 0) for instant, deterministic results.
// Previews inject MockPokemonService(simulatedDelay: 500_000_000) for realistic loading states.
// Production injects PokemonAPIService() for live data.
```

---

## 10. Key Design Decisions

### 10.1 Custom JSON Decoder vs. Separate Models

**Decision:** Custom `init(from decoder:)` on `Pokemon` that extracts `id` from the URL.

**Alternative considered:** Separate `PokemonSummary` (list) and `PokemonDetail` models.

**Rationale:** Two models would mean duplicating `name`, `url`, computed properties, and navigation logic. The custom decoder is 15 lines of well-documented code that handles both API shapes transparently.

### 10.2 Combine for Search vs. onChange Modifier

**Decision:** Combine's `.debounce` pipeline.

**Alternative considered:** `.onChange(of: searchText)` with `Task.sleep`.

**Rationale:** Combine provides exact control over debounce timing (300ms), `removeDuplicates`, and cancellation. The pipeline is self-documenting and the `cancellables` set ensures cleanup on deinit.

### 10.3 UserDefaults vs. SwiftData for Favorites

**Decision:** `UserDefaults` with a custom `FavoritesStore` class.

**Alternative considered:** SwiftData `@Model` with a `Favorite` entity.

**Rationale:** For a `Set<Int>` (favorite IDs), UserDefaults is simpler, faster, and has zero migration overhead. SwiftData would be appropriate if favorites carried additional metadata (date favorited, notes, custom order).

### 10.4 Layout Protocol for FlowLayout

**Decision:** Custom `Layout` protocol implementation for type effectiveness chips.

**Alternative considered:** `LazyVGrid` with adaptive columns, or wrapping `HStack`s.

**Rationale:** The `Layout` protocol (iOS 16+) provides precise control over flow/wrap behavior. `LazyVGrid` doesn't wrap naturally — items are fixed to columns. The implementation is educational, demonstrating the `Layout` protocol for students.

### 10.5 Final Classes

**Decision:** All classes are marked `final`.

**Rationale:** There's no inheritance in this architecture (composition over inheritance). `final` enables compiler optimizations (direct dispatch instead of vtable lookup) and clearly communicates that these classes are not designed for subclassing.

---

## Appendix: Directory Map

```
PokedexTutorial/
├── App/
│   └── PokedexTutorialApp.swift          @main entry point, DI setup
├── Models/
│   ├── Pokemon.swift                     Core entity, custom decoder
│   ├── PokemonType.swift                 18-type enum + colors
│   ├── PokemonDetail.swift               Stats, abilities, sprites, types
│   └── LoadingState.swift                Generic async state enum
├── Services/
│   ├── PokemonServiceProtocol.swift      Protocol + typed errors
│   ├── PokemonAPIService.swift           Real PokéAPI client
│   └── MockPokemonService.swift          Bundled JSON, simulated latency
├── ViewModels/
│   ├── PokemonListViewModel.swift        List state, search, filter, pagination
│   └── PokemonDetailViewModel.swift      Detail state, lazy type relations
├── Views/
│   ├── PokemonListView.swift             Main screen (list/grid/search/filter)
│   ├── PokemonRowView.swift              Row component (sprite, name, types, star)
│   ├── PokemonDetailView.swift           Detail screen (stats, abilities, types)
│   ├── TypeBadgeView.swift               Reusable colored type chip
│   ├── StatBarView.swift                 Horizontal stat bar (color-coded)
│   └── FilterChipView.swift              Selectable type filter chip
├── Stores/
│   └── FavoritesStore.swift              UserDefaults-backed favorites
├── Extensions/
│   ├── Color+PokemonType.swift           Color convenience accessor
│   └── View+Extensions.swift             CardStyle modifier, conditional if
└── Resources/
    ├── Assets.xcassets/                  App icon, accent color
    └── mock_pokemon_list.json            Development fixture (10 Pokémon)
```

---

*For build and run instructions, see [run.md](run.md). For user-facing guidance, see [user_guide.md](user_guide.md).*
