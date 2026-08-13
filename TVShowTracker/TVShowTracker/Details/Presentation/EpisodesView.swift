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
                    TrackerEmptyState(
                        title: "No episodes yet",
                        systemImage: "list.number",
                        description: "Episode information will appear here as soon as it is available."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    progressSummary(seasons)
                        .padding(.top, 12)

                    markAllAvailableSection(seasons)

                    Divider()

                    ForEach(seasons) { season in
                        seasonSection(season)

                        if season.id != seasons.last?.id {
                            Divider()
                        }
                    }
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
        } else {
            Color.clear
                .frame(height: 14)
        }
    }

    private func seasonSection(_ season: ShowSeason) -> some View {
        let isExpanded = expandedSeasonIDs.contains(season.id)

        return VStack(spacing: 0) {
            SeasonHeader(
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
                onMarkWatched: {
                    viewModel.markSeasonWatched(season)
                    watchActionID += 1
                }
            )

            CollapsibleEpisodeList(isExpanded: isExpanded) {
                VStack(spacing: 10) {
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

private struct SeasonHeader: View {
    let season: ShowSeason
    let isExpanded: Bool
    let isFullyWatched: Bool
    let watchedEpisodeCount: Int
    let unwatchedReleasedEpisodeCount: Int
    let onToggleExpanded: () -> Void
    let onMarkWatched: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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

private struct CollapsibleEpisodeList<Content: View>: View {
    let isExpanded: Bool
    let content: Content
    @State private var contentHeight: CGFloat = 0

    init(isExpanded: Bool, @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { newHeight in
                contentHeight = newHeight
            }
            .offset(y: isExpanded ? 0 : -14)
            .frame(height: isExpanded ? contentHeight : 0, alignment: .top)
            .clipped()
            .allowsHitTesting(isExpanded)
            .accessibilityHidden(!isExpanded)
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
