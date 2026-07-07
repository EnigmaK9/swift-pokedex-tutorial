# Swift Pokédex Tutorial — Master Plan

A pedagogical iOS app that teaches Swift and SwiftUI development by building a fully functional Pokédex. Each step maps to a standard Swift syllabus topic, with detailed explanations, code comments, and learning objectives.

---

## Step 01: Project Foundation & Swift Language Primer
**Syllabus topics:** Xcode project structure, Swift types, optionals, protocols, extensions

- [x] Create Xcode project (`SwiftUI` + `SwiftData` unchecked to start simple)
- [x] Explain project structure: `App` entry point, `ContentView`, `Assets.xcassets`, `Info.plist`
- [x] Define the `Pokemon` model struct with `Codable`, `Identifiable`, `Hashable`
- [x] Define the `PokemonType` enum with raw `String` values and color mapping
- [x] Write unit tests for model decoding from a sample JSON fixture
- [x] Explain: value types vs reference types, `let` vs `var`, optionals, `Codable` protocol

**Checkpoint:** App compiles, model tests pass, student understands Swift type system basics.

---

## Step 02: SwiftUI Fundamentals — Layouts, Views & Modifiers
**Syllabus topics:** `View` protocol, `body`, stacks, lists, modifiers, state

- [x] Build the main `PokemonListView` with a static array of sample Pokémon
- [x] Create `PokemonRowView` — a reusable row component (image, name, type badges)
- [x] Build `TypeBadgeView` — a small colored capsule showing the Pokémon type
- [x] Explain: `HStack` / `VStack` / `ZStack`, `List`, `ForEach`, view modifiers chain
- [x] Explain: `@State` and how SwiftUI reacts to state changes
- [x] Add a segmented control to toggle between list and grid layout (`LazyVGrid`)

**Checkpoint:** App displays a static Pokémon list with type badges. Student understands view composition.

---

## Step 03: Data Layer — MVVM, Services & Dependency Injection
**Syllabus topics:** MVVM architecture, ObservableObject, @Published, protocol-oriented design

- [x] Refactor into MVVM folders: `Models/`, `ViewModels/`, `Views/`, `Services/`
- [x] Create `PokemonServiceProtocol` — define the API contract
- [x] Create `MockPokemonService` — returns local JSON for development
- [x] Create `PokemonListViewModel` as `@ObservableObject` with `@Published` properties
- [x] Explain: why protocols matter, dependency injection, testability
- [x] Write unit tests for `PokemonListViewModel` using the mock service
- [x] Explain: `@StateObject` vs `@ObservedObject` vs `@EnvironmentObject`

**Checkpoint:** MVVM architecture in place, ViewModel drives the list via mock service, tests pass.

---

## Step 04: Networking — Async/Await, API Integration & Error Handling
**Syllabus topics:** `async/await`, `URLSession`, `Result` type, error handling, `@MainActor`

- [x] Create `PokemonAPIService` conforming to `PokemonServiceProtocol`
- [x] Implement `fetchPokemonList(limit:offset:)` — call PokéAPI `https://pokeapi.co/api/v2/pokemon`
- [x] Implement `fetchPokemonDetail(id:)` — fetch individual Pokémon (stats, abilities, sprites)
- [x] Handle errors: network unavailable, decoding failures, rate limits
- [x] Create a `LoadingState` enum: `.idle`, `.loading`, `.loaded`, `.error(String)`
- [x] Add pull-to-refresh with `.refreshable` modifier
- [x] Explain: structured concurrency, `Task`, `MainActor.run`, `do/catch`, `try/await`

**Checkpoint:** App fetches real Pokémon from the API. Loading and error states handled. Student understands async/await.

---

## Step 05: Navigation & Data Flow
**Syllabus topics:** `NavigationStack`, `NavigationLink`, value-based navigation, `@Binding`

- [x] Wrap list in `NavigationStack` and add `.navigationTitle` and `.navigationBarTitleDisplayMode`
- [x] Create `PokemonDetailView` — receives a `Pokemon` and shows full details
- [x] Display: official artwork, stats bars, abilities list, type effectiveness
- [x] Implement navigation with `NavigationLink(value:)` (value-based, iOS 16+)
- [x] Explain: `@Binding` for two-way data flow, `NavigationPath`, programmatic navigation
- [x] Add a toolbar button to randomize Pokémon navigation

**Checkpoint:** Full list → detail navigation working. Data flows correctly. Student understands SwiftUI navigation.

---

## Step 06: Search, Filter & Persistent Favorites
**Syllabus topics:** Combine, search debouncing, `UserDefaults`, `@AppStorage`, `SwiftData` intro

- [x] Add `.searchable` modifier with search text binding
- [x] Implement client-side filtering by name and type
- [x] Add a type filter picker (horizontal scroll of type chips)
- [x] Debounce search input using Combine's `Debounce` publisher (explain Combine basics)
- [x] Persist favorites using `UserDefaults` via a `FavoritesStore` class
- [x] Add favorite toggle (star button) in list and detail views
- [x] Add a "Favorites" segmented tab to filter the list
- [x] Briefly introduce `SwiftData` as the modern alternative to `UserDefaults` for complex data

**Checkpoint:** Search, filter, and favorites fully working. Student understands Combine basics and persistence.

---

## Step 07: Polish — Animations, Accessibility & Testing
**Syllabus topics:** SwiftUI animations, `matchedGeometryEffect`, accessibility labels, XCTest, XCUITest

- [x] Add `withAnimation` to list appearance, row insertion, and layout transitions
- [x] Implement `matchedGeometryEffect` for smooth list→detail hero transition
- [x] Add accessibility labels and hints to all interactive elements
- [x] Support Dynamic Type — verify layouts don't break at larger text sizes
- [x] Add Dark Mode support — verify colors and contrast
- [x] Write UI tests (XCUITest) for critical flows: list loads, tap navigates, search works
- [x] Write a `README.md` with architecture diagram, setup instructions, and learning outcomes
- [x] Run full test suite and confirm all pass

**Checkpoint:** Polished, accessible, tested app. Student has a complete reference implementation.

---

## Architecture Overview

```
swift-pokedex-tutorial/
├── PokedexTutorial.xcodeproj
├── PokedexTutorial/
│   ├── App/
│   │   └── PokedexTutorialApp.swift          # @main entry point
│   ├── Models/
│   │   ├── Pokemon.swift                     # Core data model
│   │   ├── PokemonType.swift                 # Type enum
│   │   ├── PokemonDetail.swift               # Detail model (stats, abilities)
│   │   └── LoadingState.swift                # Generic loading/error/idle enum
│   ├── Services/
│   │   ├── PokemonServiceProtocol.swift      # API contract (protocol)
│   │   ├── MockPokemonService.swift          # Development mock
│   │   └── PokemonAPIService.swift           # Real PokéAPI client
│   ├── ViewModels/
│   │   ├── PokemonListViewModel.swift        # List screen logic
│   │   └── PokemonDetailViewModel.swift      # Detail screen logic
│   ├── Views/
│   │   ├── PokemonListView.swift             # Main list/grid screen
│   │   ├── PokemonRowView.swift              # Single row component
│   │   ├── PokemonDetailView.swift           # Detail screen
│   │   ├── TypeBadgeView.swift               # Reusable type chip
│   │   ├── StatBarView.swift                 # Stat visualization
│   │   └── FilterChipView.swift              # Type filter chip
│   ├── Stores/
│   │   └── FavoritesStore.swift              # UserDefaults-backed favorites
│   ├── Extensions/
│   │   ├── Color+PokemonType.swift           # Type → Color mapping
│   │   └── View+Extensions.swift             # Shared view modifiers
│   └── Resources/
│       ├── Assets.xcassets                   # App icons, colors
│       └── mock_pokemon_list.json            # Sample data fixture
├── PokedexTutorialTests/
│   ├── PokemonModelTests.swift               # Decoding tests
│   ├── PokemonListViewModelTests.swift       # ViewModel logic tests
│   └── PokemonAPIServiceTests.swift          # API integration tests
└── PokedexTutorialUITests/
    └── PokedexTutorialUITests.swift           # Critical flow tests
```

## Learning Outcomes

After completing this tutorial, the student will understand:

1. **Swift language:** types, optionals, generics, protocols, extensions, enums with associated values
2. **SwiftUI:** view composition, modifiers, state management, navigation, animations
3. **Architecture:** MVVM pattern, protocol-oriented design, dependency injection
4. **Concurrency:** async/await, MainActor, structured concurrency
5. **Networking:** URLSession, Codable, error handling, loading states
6. **Persistence:** UserDefaults, @AppStorage, intro to SwiftData
7. **Testing:** unit tests with XCTest, UI tests with XCUITest, mock services
8. **Accessibility:** labels, hints, Dynamic Type, Dark Mode
9. **Reactive programming:** Combine basics (Publishers, debounce, sink)

---

*Plan created 2026-07-02. Each step builds incrementally on the previous. Complete a step and verify its checkpoint before moving to the next.*
