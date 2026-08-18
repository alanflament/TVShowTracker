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
    let onSelectMedia: (SearchCandidate) -> Void
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
                    UpNextSummary(
                        availableEpisodeCount: availableEpisodeCount,
                        undatedMediaCount: undatedMedia.count
                    )
                    .contentTransition(.numericText())

                    if !availableEpisodes.isEmpty {
                        episodeSection(
                            title: "Available now",
                            subtitle: "Ready when you are",
                            episodes: availableEpisodes
                        )
                        .transition(sectionTransition)
                    }

                    if !upcomingEpisodes.isEmpty {
                        episodeSection(
                            title: "Coming soon",
                            subtitle: "Your next releases",
                            episodes: upcomingEpisodes
                        )
                        .transition(sectionTransition)
                    }

                    if !undatedMedia.isEmpty {
                        undatedMediaSection(undatedMedia)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .animation(cardAnimation, value: episodes.map(\.episode.id))
            .animation(cardAnimation, value: availableEpisodeCount)
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
                    CalendarEpisodeCard(
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

    private var sectionTransition: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
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
                    CalendarUndatedMediaCard(item: item) {
                        onSelectMedia(item.candidate)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func emptyContent() -> some View {
        if viewModel.followedMediaIDs.isEmpty {
            TrackerEmptyState(
                title: "Your next episode starts here",
                systemImage: "play.circle.fill",
                description: "Follow TV shows and anime in Discover to build your personal queue."
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else if viewModel.watchingMediaIDs.isEmpty {
            TrackerEmptyState(
                title: "Nothing in Up Next",
                systemImage: "pause.circle.fill",
                description: "Set a show to Watching from its details to include its episodes here."
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            TrackerEmptyState(
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

private struct CalendarEpisodeCard: View {
    let episode: CalendarEpisode
    let onSelect: () -> Void
    let onMarkWatched: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isConfirmingWatched = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            MediaPoster(url: episode.posterURL, kind: episode.candidate.kind, width: 80, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(episode.showTitle.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    if episode.additionalAvailableEpisodeCount > 0 {
                        AdditionalEpisodesBadge(count: episode.additionalAvailableEpisodeCount)
                    }
                }
                HStack(spacing: 7) {
                    Text("Season \(episode.episode.seasonNumber), Episode \(episode.episode.number)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let duration = episode.episode.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
                Text(episode.episode.title)
                    .font(.headline)
                    .lineLimit(2, reservesSpace: true)
                calendarAction
                    .frame(height: 32, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.08))
        }
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens episode details")
    }

    @ViewBuilder
    private var calendarAction: some View {
        if episode.episode.isReleased {
            Button {
                guard !isConfirmingWatched else {
                    return
                }

                withAnimation(.snappy(duration: 0.28)) {
                    isConfirmingWatched = true
                }
                Task {
                    let feedbackDuration = accessibilityReduceMotion ? 150_000_000 : 650_000_000
                    try? await Task.sleep(nanoseconds: UInt64(feedbackDuration))
                    await onMarkWatched()
                }
            } label: {
                ZStack(alignment: .leading) {
                    Label("Mark as watched", systemImage: "checkmark.circle")
                        .opacity(isConfirmingWatched ? 0 : 1)
                    Label("Watched", systemImage: "checkmark.circle.fill")
                        .opacity(isConfirmingWatched ? 1 : 0)
                        .symbolEffect(.bounce, value: isConfirmingWatched)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .scaleEffect(isConfirmingWatched && !accessibilityReduceMotion ? 1.04 : 1)
            .animation(.snappy(duration: 0.28), value: isConfirmingWatched)
            .sensoryFeedback(.success, trigger: isConfirmingWatched)
            .accessibilityLabel(isConfirmingWatched ? "Watched" : "Mark as watched")
        } else if let airDate = episode.episode.airDate {
            Label(
                ReleaseCountdown(
                    airDate: airDate,
                    precision: episode.episode.releaseDatePrecision
                ).text,
                systemImage: "clock"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.orange)
        } else {
            Label("Release date unavailable", systemImage: "calendar.badge.exclamationmark")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AdditionalEpisodesBadge: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.14), in: .capsule)
            .accessibilityLabel("\(count) more \(count == 1 ? "episode" : "episodes") available")
    }
}

private struct UpNextSummary: View {
    let availableEpisodeCount: Int
    let undatedMediaCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summaryTitle)
                .font(.title.bold())
            Text(summaryDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryTitle: String {
        switch availableEpisodeCount {
        case 0:
            "Your upcoming episodes"
        case 1:
            "One episode is ready"
        default:
            "\(availableEpisodeCount) episodes are ready"
        }
    }

    private var summaryDescription: String {
        if availableEpisodeCount > 0 {
            return "Pick up where you left off."
        }
        if undatedMediaCount > 0 {
            return "Some of your shows have not announced their next episode yet."
        }
        return "Keep an eye on what is coming next."
    }
}

private struct CalendarUndatedMediaCard: View {
    let item: CalendarUndatedMedia
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            MediaPoster(url: item.posterURL, kind: item.candidate.kind, width: 56, height: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.showTitle)
                    .font(.headline)
                Label("Next episode to be announced", systemImage: "calendar.badge.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens show details")
    }
}

private struct ReleaseCountdown {
    let airDate: Date
    let precision: EpisodeReleaseDatePrecision

    var text: String {
        let interval = max(0, airDate.timeIntervalSinceNow)
        if precision == .time, interval < 86400 {
            let hours = max(1, Int(ceil(interval / 3600)))
            return "Available in \(hours) \(hours == 1 ? "hour" : "hours")"
        }

        let days = Int(ceil(interval / 86400))
        return "Available in \(days) \(days == 1 ? "day" : "days")"
    }
}
