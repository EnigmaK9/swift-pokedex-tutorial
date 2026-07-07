# Run Guide — Pokédex Tutorial

**Created:** 2026-07-07 | **Last modified:** 2026-07-07 | **Author:** enigmak9

Minimum steps to build, test, and run the Pokédex Tutorial app. No prior Swift experience assumed beyond having Xcode installed.

---

## Prerequisites

| Requirement | Minimum Version | How to Check |
|-------------|----------------|--------------|
| macOS | 14.0 (Sonoma) | Apple menu > About This Mac |
| Xcode | 15.2 | `xcodebuild -version` |
| iOS Simulator | 17.0+ | `xcrun simctl list devices` |
| Internet | — | Required for live API data |

---

## Quick Start (3 Commands)

```bash
# 1. Clone and enter the project
cd swift-pokedex-tutorial

# 2. Build the app for the simulator
xcodebuild -project PokedexTutorial.xcodeproj \
  -scheme PokedexTutorial \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# 3. Boot simulator, install, and launch
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null
xcrun simctl install "iPhone 17 Pro" \
  ~/Library/Developer/Xcode/DerivedData/PokedexTutorial-*/Build/Products/Debug-iphonesimulator/PokedexTutorial.app
xcrun simctl launch "iPhone 17 Pro" com.enigmak9.PokedexTutorial
```

**That's it.** The app opens in the simulator showing Pokémon from the live PokéAPI.

---

## Using Xcode (GUI)

1. **Open the project:**
   ```bash
   open PokedexTutorial.xcodeproj
   ```
   Or double-click `PokedexTutorial.xcodeproj` in Finder.

2. **Select a simulator** from the scheme dropdown (top-left of Xcode, next to the stop button). Pick any iPhone or iPad running iOS 17.0+.

3. **Press Cmd+R** to build and run.

4. The app launches in the simulator. You'll see the Pokémon list load from the live API.

---

## Running Tests

### All Tests (Unit + Integration + UI)

```bash
xcodebuild -project PokedexTutorial.xcodeproj \
  -scheme PokedexTutorial \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

### Unit Tests Only

```bash
xcodebuild -project PokedexTutorial.xcodeproj \
  -scheme PokedexTutorial \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test \
  -only-testing:PokedexTutorialTests
```

### Specific Test Class

```bash
xcodebuild -project PokedexTutorial.xcodeproj \
  -scheme PokedexTutorial \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test \
  -only-testing:PokedexTutorialTests/PokemonModelTests
```

### In Xcode
- Press **Cmd+U** to run all tests.
- Click the diamond icon next to any test class or method to run it individually.

---

## Switching Between Real API and Mock Data

The app uses the real PokéAPI by default. To use local mock data (no network needed):

1. Open `PokedexTutorial/App/PokedexTutorialApp.swift`
2. Change this line:
   ```swift
   // From:
   @StateObject private var pokemonService: PokemonAPIService = PokemonAPIService()

   // To:
   @StateObject private var pokemonService = MockPokemonService()
   ```
3. Rebuild (Cmd+R).

The mock service returns 10 hardcoded Pokémon instantly (or with configurable simulated latency).

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **"No such module" errors** | Make sure you're opening the `.xcodeproj`, not individual files. The project file configures all build settings. |
| **"Scheme not found"** | Run `xcodebuild -list -project PokedexTutorial.xcodeproj` to verify the scheme exists. |
| **Simulator not found** | Run `xcrun simctl list devices available` and use a listed device name. |
| **"A build only device cannot be used to run this target"** | You're trying to build for a physical device. Switch to a simulator destination. |
| **API tests fail with network errors** | The PokéAPI may be rate-limiting. Wait a minute and retry. API tests pass when run individually. |
| **Build takes very long** | First build is slow (derived data cache is cold). Subsequent builds are fast (incremental). |

---

## Build Output Locations

| Artifact | Path |
|----------|------|
| Built .app | `~/Library/Developer/Xcode/DerivedData/PokedexTutorial-*/Build/Products/Debug-iphonesimulator/PokedexTutorial.app` |
| Test results (.xcresult) | `~/Library/Developer/Xcode/DerivedData/PokedexTutorial-*/Logs/Test/` |
| Derived data (cache) | `~/Library/Developer/Xcode/DerivedData/PokedexTutorial-*/` |

---

## Supported Simulators

Any simulator running iOS 17.0 or later:

```bash
# List all available simulators
xcrun simctl list devices available | grep iPhone
```

The deployment target is iOS 17.0, so the app runs on all modern iPhone and iPad simulators.

---

## Next Steps

- Read [architecture.md](architecture.md) for the full technical design
- Read [flowcharts.md](flowcharts.md) for visual flow diagrams
- Read [user_guide.md](user_guide.md) for advanced usage tips
- Read the [LaTeX guide](latex/pokedex-guide.tex) for a printable reference
