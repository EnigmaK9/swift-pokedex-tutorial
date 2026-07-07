# Flowcharts — Pokédex Tutorial

**Created:** 2026-07-07 | **Last modified:** 2026-07-07 | **Author:** enigmak9

Visual documentation of all major flows in the app using Mermaid diagrams. These charts document the actual runtime behavior — every branch and state transition shown here is implemented in the code.

---

## Table of Contents

1. [App Launch Sequence](#1-app-launch-sequence)
2. [Pokémon List Loading](#2-pokémon-list-loading)
3. [Search Flow](#3-search-flow)
4. [Type Filtering Flow](#4-type-filtering-flow)
5. [Navigation to Detail](#5-navigation-to-detail)
6. [Detail Data Loading](#6-detail-data-loading)
7. [Favorites Toggle](#7-favorites-toggle)
8. [Pull-to-Refresh](#8-pull-to-refresh)
9. [Infinite Scroll (Pagination)](#9-infinite-scroll-pagination)
10. [Layout Toggle (List / Grid)](#10-layout-toggle-list--grid)
11. [Complete State Machine](#11-complete-state-machine)
12. [Error Recovery Flow](#12-error-recovery-flow)
13. [Component Dependency Graph](#13-component-dependency-graph)

---

## 1. App Launch Sequence

```mermaid
sequenceDiagram
    participant System as iOS System
    participant App as PokedexTutorialApp
    participant Service as PokemonAPIService
    participant VM as PokemonListViewModel
    participant View as PokemonListView
    participant API as PokéAPI (pokeapi.co)

    System->>App: Launch (process starts)
    App->>Service: Create PokemonAPIService() [@StateObject]
    App->>App: Create FavoritesStore() [@StateObject]
    App->>VM: Create PokemonListViewModel(service:)
    App->>View: Render PokemonListView(viewModel:)
    App->>View: Inject .environmentObject(favoritesStore)
    View->>View: .task { await viewModel.fetchInitialData() }
    View->>VM: fetchInitialData()
    VM->>VM: state = .loading
    VM->>Service: await fetchPokemonList(limit:20, offset:0)
    Service->>API: GET /api/v2/pokemon?limit=20&offset=0
    API-->>Service: 200 OK + JSON (20 Pokémon)
    Service->>Service: Decode PokemonListResponse
    Service-->>VM: Return response
    VM->>VM: allPokemon = response.results
    VM->>VM: state = .loaded(filteredPokemon)
    VM-->>View: @Published triggers re-render
    View->>View: Render list with 20 Pokémon rows
```

---

## 2. Pokémon List Loading

```mermaid
flowchart TD
    A[View appears] --> B{State?}
    B -->|.idle| C[Call fetchInitialData()]
    B -->|.loading| D[Show ProgressView spinner]
    B -->|.loaded| E[Show list]
    B -->|.error| F[Show ErrorView with retry]

    C --> G[state = .loading]
    G --> H[await service.fetchPokemonList]
    H --> I{Success?}
    I -->|Yes| J[allPokemon = results]
    J --> K[state = .loaded results]
    I -->|No| L{Already have data?}
    L -->|Yes| M[Keep loaded data, log error]
    L -->|No| N[state = .error message]

    K --> E
    N --> F
    M --> E
    D --> H

    F -->|User taps Retry| C
```

---

## 3. Search Flow

```mermaid
flowchart LR
    subgraph "User Input"
        A[User types in .searchable field]
    end

    subgraph "Combine Pipeline (300ms debounce)"
        B["$searchText<br/>(@Published)"]
        C[".debounce(300ms)"]
        D[".removeDuplicates()"]
        E[".sink { update state }"]
    end

    subgraph "Filtering Logic"
        F[filteredPokemon computed property]
        G{selectedType != nil?}
        H[Filter by type]
        I[Filter by name<br/>case-insensitive contains]
        J[Merge results]
    end

    subgraph "UI Update"
        K["state = .loaded(filtered)<br/>(@Published triggers re-render)"]
    end

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G -->|Yes| H --> J
    G -->|No| I
    H --> I
    I --> J
    J --> K
```

---

## 4. Type Filtering Flow

```mermaid
flowchart TD
    A[User taps type chip] --> B{Chip already selected?}
    B -->|Yes| C["Deselect: selectedType = nil"]
    B -->|No| D["Select: selectedType = tappedType"]

    C --> E[filteredPokemon recomputed]
    D --> E

    E --> F{selectedType == nil?}
    F -->|Yes| G[Show all Pokémon]
    F -->|No| H["Filter: keep only Pokémon where<br/>pokemon.types.contains(selectedType)"]

    G --> I[state = .loaded results]
    H --> I
    I --> J[View re-renders]

    subgraph "Visual Feedback"
        K[Selected chip: solid fill]
        L[Deselected chips: outlined]
    end

    D --> K
    C --> L
```

---

## 5. Navigation to Detail

```mermaid
sequenceDiagram
    participant User
    participant List as PokemonListView
    participant Nav as NavigationStack
    participant Detail as PokemonDetailView
    participant DetailVM as PokemonDetailViewModel
    participant Service as PokemonAPIService
    participant API as PokéAPI

    User->>List: Tap Pokémon row
    List->>Nav: NavigationLink(value: pokemon) activated
    Nav->>Nav: Look up .navigationDestination(for: Pokemon.self)
    Nav->>DetailVM: Create PokemonDetailViewModel(pokemonID, pokemonName, service)
    Nav->>Detail: Push PokemonDetailView(viewModel:)
    Detail->>Detail: .task { await viewModel.fetchDetail() }
    Detail->>DetailVM: fetchDetail()
    DetailVM->>DetailVM: state = .loading
    DetailVM->>Service: await fetchPokemonDetail(id: pokemonID)
    Service->>API: GET /api/v2/pokemon/{id}
    API-->>Service: 200 OK + detail JSON
    Service->>Service: Decode PokemonDetail
    Service-->>DetailVM: Return detail
    DetailVM->>DetailVM: state = .loaded(detail)
    DetailVM-->>Detail: @Published triggers re-render
    Detail->>Detail: Show artwork, stats, abilities, types
```

---

## 6. Detail Data Loading

```mermaid
flowchart TD
    A[Detail view appears] --> B{state?}
    B -->|.idle| C[fetchDetail()]
    B -->|.loading| D[Show spinner]
    B -->|.loaded| E[Render full detail]
    B -->|.error| F[Show ErrorView]

    C --> G["state = .loading"]
    G --> H["await service.fetchPokemonDetail(id:)"]
    H --> I{Success?}
    I -->|Yes| J[state = .loaded detail]
    I -->|No| K[state = .error message]

    J --> E
    K --> F

    E --> L{User expands<br/>Type Effectiveness?}
    L -->|Yes| M[fetchTypeRelations()]
    M --> N[typeRelationsState = .loading]
    N --> O["await service.fetchTypeRelations(name:)"]
    O --> P{Success?}
    P -->|Yes| Q[Show weakness/resistance/immunity]
    P -->|No| R[Show error in section]
```

---

## 7. Favorites Toggle

```mermaid
flowchart TD
    A[User taps star button] --> B{favoritesStore.isFavorite id ?}
    B -->|Yes| C["Remove: favoriteIDs.remove(id)"]
    B -->|No| D["Add: favoriteIDs.insert(id)"]

    C --> E[saveFavorites()]
    D --> E

    E --> F["UserDefaults.standard.set(Array(favoriteIDs), forKey:)"]

    F --> G["@Published triggers view update"]

    G --> H[Star icon changes]
    H --> I{favoritesOnly filter active?}
    I -->|Yes| J[Filtered list re-renders]
    I -->|No| K[Just icon updates]

    subgraph "Animation"
        L[".spring(response:0.3, dampingFraction:0.6)"]
    end

    A --> L
    L --> H
```

---

## 8. Pull-to-Refresh

```mermaid
sequenceDiagram
    participant User
    participant View as PokemonListView
    participant VM as PokemonListViewModel
    participant Service as PokemonAPIService
    participant API as PokéAPI

    User->>View: Swipe down (pull-to-refresh)
    View->>VM: await refresh()
    VM->>VM: currentOffset = 0
    VM->>VM: hasMorePages = true
    VM->>VM: allPokemon = []
    VM->>VM: state = .loading
    VM->>Service: await fetchPokemonList(limit:20, offset:0)
    Service->>API: GET /api/v2/pokemon?limit=20&offset=0
    API-->>Service: 200 OK
    Service-->>VM: Fresh first page
    VM->>VM: allPokemon = response.results
    VM->>VM: state = .loaded(allPokemon)
    VM-->>View: Re-render with fresh data
    View->>View: RefreshControl hides
```

---

## 9. Infinite Scroll (Pagination)

```mermaid
flowchart TD
    A[User scrolls list] --> B[Last item appears on screen]
    B --> C[.task modifier fires]
    C --> D{loadMoreIfNeeded}
    D --> E{"Near bottom?<br/>(within 5 items of end)"}
    E -->|No| F[Do nothing]
    E -->|Yes| G{hasMorePages AND !isFetching?}
    G -->|No| H[Do nothing]
    G -->|Yes| I["await loadNextPage()"]

    I --> J["loadPage(offset: currentOffset + pageSize)"]
    J --> K[isFetching = true]
    K --> L["await service.fetchPokemonList(limit:20, offset:...)"]
    L --> M{Success?}
    M -->|Yes| N["allPokemon.append(contentsOf: newResults)"]
    N --> O["currentOffset = offset<br/>hasMorePages = (response.next != nil)"]
    O --> P[state = .loaded allPokemon]
    M -->|No| Q{Already have data?}
    Q -->|Yes| R[Keep data, log error]
    Q -->|No| S[state = .error]

    P --> T[View appends new rows]
    R --> T
```

---

## 10. Layout Toggle (List / Grid)

```mermaid
flowchart LR
    A[User taps layout button] --> B{Current layout?}
    B -->|List| C["Switch to Grid<br/>isGridView = true<br/>withAnimation(.easeInOut)"]
    B -->|Grid| D["Switch to List<br/>isGridView = false<br/>withAnimation(.easeInOut)"]

    C --> E[View re-renders]
    D --> E

    E --> F{isGridView?}
    F -->|true| G["ScrollView + LazyVGrid<br/>(adaptive columns, min 160pt)"]
    F -->|false| H["List + PokemonRowView<br/>(standard iOS table rows)"]

    subgraph "Button Icon"
        I[List mode: shows 'square.grid.2x2']
        J[Grid mode: shows 'list.bullet']
    end

    C --> J
    D --> I
```

---

## 11. Complete State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle : App launches

    Idle --> Loading : fetchInitialData()
    Loading --> Loaded : API success
    Loading --> Error : API / network failure

    Loaded --> Loading : pull-to-refresh
    Loaded --> Loading : infinite scroll<br/>(keeps loaded data)
    Loaded --> Idle : (never — stays loaded)

    Error --> Loading : user taps Retry
    Error --> Idle : (never — must retry)

    note right of Loaded
        Search/filter operations stay in .loaded.
        They filter allPokemon in-memory and
        republish as .loaded(filteredResults).
    end note

    note right of Loading
        Pagination while already loaded:
        • Keeps existing data visible
        • Appends new results on success
        • Silently handles failure
    end note
```

---

## 12. Error Recovery Flow

```mermaid
flowchart TD
    A[API call fails] --> B{Error type?}
    B -->|URLError .notConnectedToInternet| C[PokemonServiceError.networkUnavailable]
    B -->|URLError .timedOut| C
    B -->|HTTP 4xx/5xx| D["PokemonServiceError.invalidResponse(code:)"]
    B -->|DecodingError| E["PokemonServiceError.decodingFailed(detail:)"]
    B -->|Other| F["PokemonServiceError.invalidResponse(code: -1)"]

    C --> G["Error message:<br/>'No internet connection'"]
    D --> H["Error message:<br/>'Server error (code N)'"]
    E --> I["Error message:<br/>'Failed to process data: {detail}'"]
    F --> J["Error message from URLError"]

    G --> K{Have existing data?}
    H --> K
    I --> K
    J --> K

    K -->|Yes| L[Keep showing loaded data]
    K -->|No| M["state = .error(message)"]

    M --> N[Show ErrorView]
    N --> O[User taps 'Try Again']
    O --> P[Re-fetch from scratch]
    P --> Q{Success?}
    Q -->|Yes| R[state = .loaded]
    Q -->|No| M
```

---

## 13. Component Dependency Graph

```mermaid
graph TD
    subgraph "App Entry"
        APP[PokedexTutorialApp]
    end

    subgraph "Stores"
        FAV[FavoritesStore]
    end

    subgraph "Views"
        PLV[PokemonListView]
        PRV[PokemonRowView]
        PDV[PokemonDetailView]
        TBV[TypeBadgeView]
        SBV[StatBarView]
        FCV[FilterChipView]
        ERR[ErrorView]
    end

    subgraph "ViewModels"
        PLVM[PokemonListViewModel]
        PDVM[PokemonDetailViewModel]
    end

    subgraph "Services"
        PROTO[PokemonServiceProtocol]
        API[PokemonAPIService]
        MOCK[MockPokemonService]
    end

    subgraph "Models"
        POK[Pokemon]
        PTYPE[PokemonType]
        PDET[PokemonDetail]
        LS[LoadingState]
    end

    subgraph "Extensions"
        COL[Color+PokemonType]
        VEXT[View+Extensions]
    end

    APP -->|creates| API
    APP -->|creates| FAV
    APP -->|passes to| PLV
    PLV -->|owns via @StateObject| PLVM
    PLVM -->|depends on| PROTO
    API -.->|implements| PROTO
    MOCK -.->|implements| PROTO
    PLVM -->|uses| POK
    PLVM -->|uses| LS
    PLVM -->|uses| PTYPE

    PLV -->|renders| PRV
    PLV -->|renders| FCV
    PLV -->|renders| ERR
    PRV -->|uses| TBV
    PRV -->|uses| FAV
    FCV -->|uses| PTYPE

    PLV -->|navigates to| PDV
    PDV -->|owns via @StateObject| PDVM
    PDVM -->|depends on| PROTO
    PDVM -->|uses| PDET
    PDV -->|renders| TBV
    PDV -->|renders| SBV
    PDV -->|renders| ERR
    PDV -->|uses| FAV

    TBV -->|uses| PTYPE
    TBV -->|uses| COL
    SBV -->|uses| VEXT
    FCV -->|uses| VEXT
    PRV -->|uses| VEXT

    PROTO -->|returns| POK
    PROTO -->|returns| PDET
```

---

*These diagrams reflect the actual implementation. Every function call, state transition, and error path shown here is traceable in the source code.*
