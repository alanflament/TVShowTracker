//
//  SeasonHeaderView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct SeasonHeaderView: View {
    let season: ShowSeason
    let isExpanded: Bool
    let isFullyWatched: Bool
    let watchedEpisodeCount: Int
    let unwatchedReleasedEpisodeCount: Int
    let onToggleExpanded: () -> Void
    let onToggleWatched: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            seasonWatchControl

            Button(action: onToggleExpanded) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(season.displayName)
                        .font(.headline)

                    if season.episodes.isEmpty {
                        Text("To be announced")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            ProgressView(value: progress)
                                .tint(isFullyWatched ? .green : .accentColor)
                            Text("\(watchedEpisodeCount) of \(season.episodes.count) watched")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(season.episodes.isEmpty)
            .accessibilityLabel(season.displayName)
            .accessibilityValue(expansionAccessibilityValue)
            .accessibilityHint(season.episodes.isEmpty ? "" : "Shows or hides the episode list")

            if !season.episodes.isEmpty {
                Button(action: onToggleExpanded) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, height: 28)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse \(season.displayName)" : "Expand \(season.displayName)")
            }
        }
        .padding(.vertical, 8)
        .textCase(nil)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var seasonWatchControl: some View {
        if season.episodes.isEmpty {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Episode schedule to be announced")
        } else {
            Button(action: onToggleWatched) {
                Image(systemName: isFullyWatched ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(isFullyWatched ? .green : .secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(unwatchedReleasedEpisodeCount == 0 && !isFullyWatched)
            .accessibilityLabel(seasonWatchAccessibilityLabel)
            .accessibilityValue(isFullyWatched ? "Complete" : "\(unwatchedReleasedEpisodeCount) available")
        }
    }

    private var seasonWatchAccessibilityLabel: String {
        if isFullyWatched {
            return "Mark all episodes in \(season.displayName) as unwatched"
        }
        return "Mark all released episodes in \(season.displayName) as watched"
    }

    private var progress: Double {
        guard !season.episodes.isEmpty else {
            return 0
        }
        return Double(watchedEpisodeCount) / Double(season.episodes.count)
    }

    private var expansionAccessibilityValue: String {
        guard !season.episodes.isEmpty else {
            return "To be announced"
        }
        return isExpanded ? "Expanded" : "Collapsed"
    }
}
