//
//  EpisodesView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct EpisodesView: View {
    @State private var viewModel: EpisodesViewModel
    @State private var expandedSeasonIDs = Set<String>()

    init(viewModel: EpisodesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading episodes…")
            case let .loaded(seasons):
                episodesList(seasons)
            case let .failed(message):
                ContentUnavailableView(
                    "Episodes unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Episodes")
        .task {
            await viewModel.load()
        }
    }

    private func episodesList(_ seasons: [ShowSeason]) -> some View {
        List {
            if seasons.isEmpty {
                ContentUnavailableView("No episodes", systemImage: "list.number")
            } else if viewModel.releasedUnwatchedEpisodeCount(in: seasons.flatMap(\.episodes)) > 0 {
                Section {
                    Button {
                        viewModel.markAllWatched(seasons)
                    } label: {
                        Label(
                            "Mark all released episodes as watched",
                            systemImage: "checkmark.circle.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            ForEach(seasons) { season in
                Section {
                    if expandedSeasonIDs.contains(season.id) {
                        ForEach(season.episodes) { episode in
                            EpisodeRow(
                                episode: episode,
                                isWatched: viewModel.isWatched(episode),
                                onToggleWatched: {
                                    viewModel.toggleWatched(episode)
                                }
                            )
                        }
                    }
                } header: {
                    SeasonHeader(
                        season: season,
                        isExpanded: expandedSeasonIDs.contains(season.id),
                        isFullyWatched: viewModel.areAllWatched(in: season.episodes),
                        unwatchedReleasedEpisodeCount: viewModel.releasedUnwatchedEpisodeCount(
                            in: season.episodes
                        ),
                        onToggle: {
                            toggleExpansion(for: season)
                        },
                        onMarkWatched: {
                            viewModel.markSeasonWatched(season)
                        }
                    )
                }
            }
        }
    }

    private func toggleExpansion(for season: ShowSeason) {
        if expandedSeasonIDs.contains(season.id) {
            expandedSeasonIDs.remove(season.id)
        } else {
            expandedSeasonIDs.insert(season.id)
        }
    }
}

private struct SeasonHeader: View {
    let season: ShowSeason
    let isExpanded: Bool
    let isFullyWatched: Bool
    let unwatchedReleasedEpisodeCount: Int
    let onToggle: () -> Void
    let onMarkWatched: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 12)
                    Text(season.displayName)
                    Spacer()
                    Text("\(season.episodes.count) episodes")
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(season.displayName), \(season.episodes.count) episodes")
            .accessibilityHint(isExpanded ? "Collapse season" : "Expand season")

            Button(action: onMarkWatched) {
                Image(systemName: isFullyWatched ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundStyle(isFullyWatched ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(unwatchedReleasedEpisodeCount == 0)
            .accessibilityLabel("Mark all released episodes in \(season.displayName) as watched")
        }
    }
}

private struct EpisodeRow: View {
    let episode: ShowEpisode
    let isWatched: Bool
    let onToggleWatched: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("E\(episode.number)")
                .font(.subheadline.bold())
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.headline)
                if let overview = episode.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let airDate = episode.airDate {
                    let formattedDate = airDate.formatted(date: .abbreviated, time: .omitted)
                    Text(airDate > .now ? "Airs \(formattedDate)" : formattedDate)
                        .font(.caption)
                        .foregroundStyle(airDate > .now ? .orange : .secondary)
                }
            }

            Spacer(minLength: 0)

            Button(action: onToggleWatched) {
                Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isWatched ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!episode.isReleased)
            .accessibilityLabel(isWatched ? "Mark as unwatched" : "Mark as watched")
            .accessibilityHint(episode.isReleased ? "" : "This episode has not been released yet.")
        }
        .opacity(episode.isReleased ? 1 : 0.6)
        .accessibilityElement(children: .contain)
    }
}
