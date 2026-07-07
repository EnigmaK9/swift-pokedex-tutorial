//
//  StatBarView.swift
//  PokedexTutorial
//
//  Created: 2026-07-02
//  Last modified: 2026-07-02
//  Description: A horizontal bar visualizing a single Pokémon base stat value.
//               The bar color changes based on the stat value (low/medium/high).
//  Author: enigmak9
//

import SwiftUI

/// A horizontal progress-style bar that visualizes a single Pokémon base stat.
///
/// Each stat bar shows:
/// - The abbreviated stat name (e.g., "HP", "Atk")
/// - The numeric base value
/// - A colored bar proportional to the value relative to the max (255)
///
/// Color coding:
/// - Red: Low stats (0-60)
/// - Yellow/Orange: Medium stats (61-100)
/// - Green: High stats (101-150)
/// - Blue: Exceptional stats (151+)
struct StatBarView: View {

    // MARK: - Properties

    /// The display label for this stat (e.g., "HP", "Attack").
    let label: String

    /// The base stat value (typically 1-255).
    let value: Int

    /// Maximum possible stat value for scaling the bar width.
    /// Defaults to 255, which is the highest base stat in the Pokémon games.
    let maxValue: Double

    // MARK: - Computed Properties

    /// The fraction of the max value, clamped to [0, 1] for the progress bar.
    private var fraction: Double {
        min(max(Double(value) / maxValue, 0), 1)
    }

    /// The bar color based on the stat value range.
    /// Higher stats get "stronger" colors for intuitive visual scanning.
    private var barColor: Color {
        switch value {
        case 0...60:   return .red
        case 61...100: return .orange
        case 101...150: return .green
        case 151...:   return .blue
        default:       return .gray
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Stat name label — fixed width for alignment across all six stats.
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)

            // Numeric value — monospaced for consistent digit width.
            Text(String(format: "%3d", value))
                .font(.caption)
                .fontWeight(.bold)
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
                .foregroundColor(.primary)

            // The progress bar.
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track.
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    // Filled portion proportional to the stat value.
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * fraction, height: 12)
                }
            }
            .frame(height: 12)
        }
        // Accessibility: conveys the stat value as a percentage for VoiceOver.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) out of \(Int(maxValue))")
        .accessibilityValue("\(Int(fraction * 100))%")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        StatBarView(label: "HP", value: 45, maxValue: 255)
        StatBarView(label: "Atk", value: 130, maxValue: 255)
        StatBarView(label: "Def", value: 80, maxValue: 255)
        StatBarView(label: "SpA", value: 180, maxValue: 255)
        StatBarView(label: "SpD", value: 55, maxValue: 255)
        StatBarView(label: "Spe", value: 100, maxValue: 255)
    }
    .padding()
}
