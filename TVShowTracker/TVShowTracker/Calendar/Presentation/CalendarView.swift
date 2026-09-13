//
//  CalendarView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftUI

struct CalendarView: View {
    let viewModel: CalendarViewModel
    let onSelectMedia: (MediaCandidate) -> Void
    let onSelectEpisode: (CalendarEpisode) -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Finding your next episode…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(episodes, availableEpisodeCount, undatedMedia):
                calendarContent(
                    episodes: episodes,
                    availableEpisodeCount: availableEpisodeCount,
                    undatedMedia: undatedMedia
                )
            }
        }
        .navigationTitle("Up Next")
        .task(id: viewModel.calendarDataID) {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refreshFromServer()
        }
    }

    private func calendarContent(
        episodes: [CalendarEpisode],
        availableEpisodeCount: Int,
        undatedMedia: [CalendarUndatedMedia]
    ) -> some View {
        let availableEpisodes = episodes.filter(\.episode.isReleased)
        let upcomingEpisodes = episodes
            .filter { !$0.episode.isReleased }
            .sorted(by: upcomingEpisodeOrder)

        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if episodes.isEmpty, undatedMedia.isEmpty {
                    emptyContent()
                } else {
                    UpNextSummaryView(
                        availableEpisodeCount: availableEpisodeCount,
                        undatedMediaCount: undatedMedia.count
                    )

                    if !availableEpisodes.isEmpty {
                        episodeSection(
                            title: "Available now",
                            subtitle: "Ready when you are",
                            episodes: availableEpisodes
                        )
                    }

                    if !upcomingEpisodes.isEmpty {
                        episodeSection(
                            title: "Coming soon",
                            subtitle: "Your next releases",
                            episodes: upcomingEpisodes
                        )
                    }

                    if !undatedMedia.isEmpty {
                        undatedMediaSection(undatedMedia)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func episodeSection(
        title: String,
        subtitle: String,
        episodes: [CalendarEpisode]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVStack(spacing: 14) {
                ForEach(episodes, id: \.candidate.id) { episode in
                    CalendarEpisodeCardView(
                        episode: episode,
                        onSelect: {
                            onSelectEpisode(episode)
                        },
                        onMarkWatched: {
                            await viewModel.markEpisodeWatched(episode)
                        }
                    )
                    .id(episode.episode.id)
                    .transition(cardTransition)
                }
            }
            .animation(cardAnimation, value: episodes.map(\.episode.id))
        }
    }

    private var cardAnimation: Animation {
        .smooth(duration: 0.45)
    }

    private var cardTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        )
    }

    private func undatedMediaSection(_ media: [CalendarUndatedMedia]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("To be announced")
                    .font(.title2.bold())
                Text("Still in release, with no next episode date yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVStack(spacing: 14) {
                ForEach(media, id: \.candidate.id) { item in
                    CalendarUndatedMediaCardView(item: item) {
                        onSelectMedia(item.candidate)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func emptyContent() -> some View {
        if viewModel.followedMediaIDs.isEmpty {
            TrackerEmptyStateView(
                title: "Your next episode starts here",
                systemImage: "play.circle.fill",
                description: "Follow TV shows and anime in Discover to build your personal queue."
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else if viewModel.watchingMediaIDs.isEmpty {
            TrackerEmptyStateView(
                title: "Nothing in Up Next",
                systemImage: "pause.circle.fill",
                description: "Set a show to Watching from its details to include its episodes here."
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            TrackerEmptyStateView(
                title: "You’re all caught up",
                systemImage: "checkmark.circle.fill",
                description: "There are no unwatched episodes in your saved schedules right now. Pull down to check for new releases."
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        }
    }

    private func upcomingEpisodeOrder(_ lhs: CalendarEpisode, _ rhs: CalendarEpisode) -> Bool {
        switch (lhs.episode.airDate, rhs.episode.airDate) {
        case let (lhsDate?, rhsDate?):
            return lhsDate == rhsDate
                ? lhs.showTitle.localizedCaseInsensitiveCompare(rhs.showTitle) == .orderedAscending
                : lhsDate < rhsDate
        case (.some, .none):
            return true
        default:
            return false
        }
    }
}
