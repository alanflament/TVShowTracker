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
        List {
            if seasons.isEmpty {
                TrackerEmptyState(
                    title: "No episodes yet",
                    systemImage: "list.number",
                    description: "Episode information will appear here as soon as it is available."
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                progressSummary(seasons)
                markAllAvailableSection(seasons)

                ForEach(seasons) { season in
                    seasonSection(season)
                }
            }
        }
        .listStyle(.plain)
    }

    private func progressSummary(_ seasons: [ShowSeason]) -> some View {
        let episodes = seasons.flatMap(\.episodes)
        let watchedCount = viewModel.watchedEpisodeCount(in: episodes)

        return Section {
            VStack(alignment: .leading, spacing: 10) {
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
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func markAllAvailableSection(_ seasons: [ShowSeason]) -> some View {
        if viewModel.releasedUnwatchedEpisodeCount(in: seasons.flatMap(\.episodes)) > 0 {
            Section {
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
            }
        }
    }

    private func seasonSection(_ season: ShowSeason) -> some View {
        Section {
            DisclosureGroup(isExpanded: expansionBinding(for: season)) {
                LazyVStack(spacing: 10) {
                    ForEach(season.episodes) { episode in
                        EpisodeRow(
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
            } label: {
                SeasonHeader(
                    season: season,
                    isFullyWatched: viewModel.areAllWatched(in: season.episodes),
                    watchedEpisodeCount: viewModel.watchedEpisodeCount(in: season.episodes),
                    unwatchedReleasedEpisodeCount: viewModel.releasedUnwatchedEpisodeCount(
                        in: season.episodes
                    ),
                    onMarkWatched: {
                        viewModel.markSeasonWatched(season)
                        watchActionID += 1
                    }
                )
            }
            .tint(.primary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func expansionBinding(for season: ShowSeason) -> Binding<Bool> {
        Binding(
            get: {
                expandedSeasonIDs.contains(season.id)
            },
            set: { isExpanded in
                let update = {
                    if isExpanded {
                        expandedSeasonIDs.insert(season.id)
                    } else {
                        expandedSeasonIDs.remove(season.id)
                    }
                }

                if reduceMotion {
                    update()
                } else {
                    withAnimation(.snappy(duration: 0.32, extraBounce: 0.05), update)
                }
            }
        )
    }

    private func progress(watched: Int, total: Int) -> Double {
        guard total > 0 else {
            return 0
        }
        return Double(watched) / Double(total)
    }
}

private struct SeasonHeader: View {
    let season: ShowSeason
    let isFullyWatched: Bool
    let watchedEpisodeCount: Int
    let unwatchedReleasedEpisodeCount: Int
    let onMarkWatched: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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

            if season.episodes.isEmpty {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Episode schedule to be announced")
            } else {
                Button(action: onMarkWatched) {
                    Image(systemName: isFullyWatched ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle(isFullyWatched ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(unwatchedReleasedEpisodeCount == 0)
                .accessibilityLabel("Mark all released episodes in \(season.displayName) as watched")
                .accessibilityValue(isFullyWatched ? "Complete" : "\(unwatchedReleasedEpisodeCount) available")
            }
        }
        .padding(.vertical, 8)
        .textCase(nil)
        .accessibilityElement(children: .contain)
    }

    private var progress: Double {
        guard !season.episodes.isEmpty else {
            return 0
        }
        return Double(watchedEpisodeCount) / Double(season.episodes.count)
    }
}

private struct EpisodeRow: View {
    let episode: ShowEpisode
    let isWatched: Bool
    let onSelect: () -> Void
    let onToggleWatched: () -> Void

    var body: some View {
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

            Spacer(minLength: 0)

            Button(action: onToggleWatched) {
                Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isWatched ? .green : .secondary)
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
