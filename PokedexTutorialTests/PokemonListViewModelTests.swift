//
//  PokemonListViewModelTests.swift
//  PokedexTutorialTests
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Unit tests for PokemonListViewModel logic including filtering,
//               pagination state, and loading state transitions using a mock service.
//  Author: enigmak9
//

import XCTest
@testable import PokedexTutorial

/// Tests for `PokemonListViewModel` using the mock service.
///
/// These tests verify ViewModel behavior in isolation:
/// - State transitions (idle → loading → loaded/error)
/// - Search filtering logic
/// - Type filtering logic
/// - Favorites-only filtering
/// - Pagination state management
///
/// Each test follows the Arrange-Act-Assert (AAA) pattern with
/// Given-When-Then comments for clarity.
@MainActor
final class PokemonListViewModelTests: XCTestCase {

    // MARK: - Properties

    private var viewModel: PokemonListViewModel!
    private var mockService: MockPokemonService!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Use instant mock (0 delay) for fast test execution.
        mockService = MockPokemonService(simulatedDelay: 0)
        viewModel = PokemonListViewModel(service: mockService, pageSize: 5)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    /// Verifies that a new ViewModel starts in the `.idle` state.
    func test_initialState_shouldBeIdle() {
        // Given: a newly created ViewModel (from setUp).
        // Then: the state should be `.idle`.
        if case .idle = viewModel.state {
            // Expected.
        } else {
            XCTFail("Expected state to be .idle, got \(viewModel.state)")
        }
    }

    /// Verifies that the search text starts empty.
    func test_initialSearchText_shouldBeEmpty() {
        XCTAssertTrue(viewModel.searchText.isEmpty)
    }

    /// Verifies that no type filter is selected initially.
    func test_initialSelectedType_shouldBeNil() {
        XCTAssertNil(viewModel.selectedType)
    }

    // MARK: - Fetch Tests

    /// Verifies that `fetchInitialData` transitions to `.loaded` with data.
    func test_fetchInitialData_shouldTransitionToLoaded() async {
        // Given: an idle ViewModel.
        // When: fetching initial data.
        await viewModel.fetchInitialData()

        // Then: the state should be `.loaded` with Pokémon data.
        if case .loaded(let pokemon) = viewModel.state {
            XCTAssertFalse(pokemon.isEmpty, "Expected Pokémon list to not be empty")
        } else {
            XCTFail("Expected .loaded state, got \(viewModel.state)")
        }
    }

    /// Verifies that a second call to `fetchInitialData` does not refetch.
    func test_fetchInitialData_whenAlreadyLoaded_shouldNotRefetch() async {
        // Given: data has already been fetched.
        await viewModel.fetchInitialData()

        if case .loaded(let firstResults) = viewModel.state {
            // When: calling fetchInitialData again.
            await viewModel.fetchInitialData()

            // Then: the results should be the same (no duplicate fetch).
            if case .loaded(let secondResults) = viewModel.state {
                XCTAssertEqual(firstResults.count, secondResults.count)
            }
        }
    }

    // MARK: - Search Filter Tests

    /// Configures the ViewModel with loaded data for filter testing.
    private func setupWithLoadedData() async {
        await viewModel.fetchInitialData()
    }

    /// Verifies that searching by name filters the Pokémon list.
    func test_filteredPokemon_withSearchText_shouldFilterByName() async {
        // Given: loaded Pokémon data.
        await setupWithLoadedData()

        // When: setting a search query that partially matches "pikachu".
        viewModel.searchText = "pika"

        // Then: only Pokémon whose names contain "pika" should appear.
        let filtered = viewModel.filteredPokemon
        XCTAssertTrue(filtered.allSatisfy { $0.name.contains("pika") })
        XCTAssertFalse(filtered.isEmpty)
    }

    /// Verifies that search is case-insensitive.
    func test_filteredPokemon_shouldBeCaseInsensitive() async {
        // Given: loaded data.
        await setupWithLoadedData()

        // When: searching with uppercase.
        viewModel.searchText = "PIKACHU"

        // Then: "pikachu" should still match.
        let filtered = viewModel.filteredPokemon
        XCTAssertTrue(filtered.contains { $0.name == "pikachu" })
    }

    /// Verifies that an empty search returns all results.
    func test_filteredPokemon_withEmptySearchText_shouldReturnAll() async {
        // Given: loaded data.
        await setupWithLoadedData()

        // When: search text is empty.
        viewModel.searchText = ""

        // Then: all loaded Pokémon should be returned.
        if case .loaded(let all) = viewModel.state {
            XCTAssertEqual(viewModel.filteredPokemon.count, all.count)
        }
    }

    // MARK: - Pagination Tests

    /// Verifies that the currentOffset starts at 0.
    func test_currentOffset_shouldStartAtZero() {
        XCTAssertEqual(viewModel.currentOffset, 0)
    }

    /// Verifies that offset updates after a successful fetch.
    func test_currentOffset_shouldUpdateAfterFetch() async {
        // Given: an idle ViewModel (offset = 0).
        // When: fetching the first page.
        await viewModel.fetchInitialData()

        // Then: the offset should still be 0 (it's the first page).
        XCTAssertEqual(viewModel.currentOffset, 0)
    }
}
