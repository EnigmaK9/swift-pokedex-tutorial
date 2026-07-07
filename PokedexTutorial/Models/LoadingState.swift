//
//  LoadingState.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: Generic enum representing the loading state of asynchronous data.
//               Used across all ViewModels for consistent loading/error UI handling.
//  Author: enigmak9
//

import Foundation

/// A generic enum that models the four possible states of an asynchronous data fetch.
///
/// This pattern eliminates the need for separate `isLoading`, `errorMessage`, and
/// data properties scattered across ViewModels. Instead, the state is represented
/// as a single `@Published` property.
///
/// Usage:
/// ```swift
/// @Published var state: LoadingState<[Pokemon]> = .idle
///
/// func fetch() async {
///     state = .loading
///     do {
///         let data = try await service.fetch()
///         state = .loaded(data)
///     } catch {
///         state = .error(error.localizedDescription)
///     }
/// }
/// ```
enum LoadingState<T: Equatable>: Equatable {

    /// No fetch has been initiated yet. This is the initial state.
    case idle

    /// A fetch is currently in progress. The UI should show a loading indicator.
    case loading

    /// Data was successfully fetched and is available for display.
    /// - Parameter T: The fetched data.
    case loaded(T)

    /// The fetch failed with an error.
    /// - Parameter String: A human-readable error message for display.
    case error(String)

    // MARK: - Computed Properties

    /// Returns the loaded data if the state is `.loaded`, otherwise `nil`.
    /// Useful for safely accessing data without a switch statement.
    var value: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }

    /// Returns `true` when a network request is in progress.
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// Returns the error message if the state is `.error`, otherwise `nil`.
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }

    /// Returns `true` if data has been successfully loaded.
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}
