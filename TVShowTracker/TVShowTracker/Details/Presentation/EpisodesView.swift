//
//  EpisodesView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct EpisodesView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: EpisodesViewModel
    @State private var expandedSeasonIDs = Set<String>()
    @State private var watchActionID = 0
    @State private var selectedEpisode: ShowEpisode?
    private let makeEpisodeDetailsView: (ShowEpisode) -> EpisodeDetailsView

    init(
        viewModel: EpisodesViewModel,
        makeEpisodeDetailsView: @escaping (ShowEpisode) -> EpisodeDetailsView
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeEpisodeDetailsView = makeEpisodeDetailsView
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
        .navigationDestination(item: $selectedEpisode) { episode in
            makeEpisodeDetailsView(episode)
        }
        .sensoryFeedback(.success, trigger: watchActionID)
    }

    private func episodesList(_ seasons: [ShowSeason]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if seasons.isEmpty {
                    TrackerEmptyStateView(
                        title: "No episodes yet",
                        systemImage: "list.number",
                        description: "Episode information will appear here as soon as it is available."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    progressSummary(seasons)
                        .padding(.top, 12)

                    Divider()

                    ForEach(seasons) { season in
                        seasonSection(season)

                        if season.id != seasons.last?.id {
                            Divider()
                        }
                    }

                    markAllAvailableSection(seasons)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func progressSummary(_ seasons: [ShowSeason]) -> some View {
        let episodes = seasons.flatMap(\.episodes)
        let watchedCount = viewModel.watchedEpisodeCount(in: episodes)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your progress")
                        .font(.headline)
                    Text("\(watchedCount) of \(episodes.count) episodes watched")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: watchedCount == episodes.count ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(watchedCount == episodes.count ? .green : Color.accentColor)
            }

            ProgressView(value: progress(watched: watchedCount, total: episodes.count))
                .tint(watchedCount == episodes.count ? .green : .accentColor)
        }
        .padding(16)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func markAllAvailableSection(_ seasons: [ShowSeason]) -> some View {
        if viewModel.releasedUnwatchedEpisodeCount(in: seasons.flatMap(\.episodes)) > 0 {
            VStack(spacing: 0) {
                Divider()

                Button {
                    viewModel.markAllWatched(seasons)
                    watchActionID += 1
                } label: {
                    Label(
                        "Mark all available episodes as watched",
                        systemImage: "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 14)
            }
        }
    }

    private func seasonSection(_ season: ShowSeason) -> some View {
        let isExpanded = expandedSeasonIDs.contains(season.id)

        return VStack(spacing: 0) {
            SeasonHeaderView(
                season: season,
                isExpanded: isExpanded,
                isFullyWatched: viewModel.areAllWatched(in: season.episodes),
                watchedEpisodeCount: viewModel.watchedEpisodeCount(in: season.episodes),
                unwatchedReleasedEpisodeCount: viewModel.releasedUnwatchedEpisodeCount(
                    in: season.episodes
                ),
                onToggleExpanded: {
                    toggleExpansion(for: season)
                },
                onToggleWatched: {
                    viewModel.toggleSeasonWatched(season)
                    watchActionID += 1
                }
            )

            CollapsibleEpisodeListView(isExpanded: isExpanded) {
                VStack(spacing: 10) {
                    ForEach(season.episodes) { episode in
                        EpisodeRowView(
                            episode: episode,
                            isWatched: viewModel.isWatched(episode),
                            onSelect: {
                                selectedEpisode = episode
                            },
                            onToggleWatched: {
                                viewModel.toggleWatched(episode)
                                watchActionID += 1
                            }
                        )
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleExpansion(for season: ShowSeason) {
        guard !season.episodes.isEmpty else {
            return
        }

        let update = {
            if expandedSeasonIDs.contains(season.id) {
                expandedSeasonIDs.remove(season.id)
            } else {
                expandedSeasonIDs.insert(season.id)
            }
        }

        if reduceMotion {
            update()
        } else {
            withAnimation(.smooth(duration: 0.42), update)
        }
    }

    private func progress(watched: Int, total: Int) -> Double {
        guard total > 0 else {
            return 0
        }
        return Double(watched) / Double(total)
    }
}
