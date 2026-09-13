//
//  EpisodeRowView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct EpisodeRowView: View {
    let episode: ShowEpisode
    let isWatched: Bool
    let onSelect: () -> Void
    let onToggleWatched: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("E\(episode.number)")
                    .font(.caption.bold())
                    .foregroundStyle(isWatched ? .green : .secondary)
                    .frame(width: 38, height: 28)
                    .background(Color.primary.opacity(0.08), in: Capsule())

                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.title)
                        .font(.headline)
                    if let overview = episode.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Text(releaseLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(episode.isReleased ? .green : .orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onToggleWatched) {
                Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isWatched ? .green : .secondary)
                    .frame(width: 52, height: 52)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!episode.isReleased)
            .accessibilityLabel(isWatched ? "Mark as unwatched" : "Mark as watched")
            .accessibilityValue(isWatched ? "Watched" : "Unwatched")
            .accessibilityHint(episode.isReleased ? "" : "This episode has not been released yet.")
        }
        .opacity(episode.isReleased ? 1 : 0.6)
        .padding(14)
        .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 14))
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
    }

    private var releaseLabel: String {
        guard !episode.isReleased else {
            return "Available now"
        }
        guard let airDate = episode.airDate else {
            return "Release date to be announced"
        }
        return "Airs \(airDate.formatted(date: .abbreviated, time: .omitted))"
    }
}
