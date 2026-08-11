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

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Finding your next episode…")
            case let .loaded(episode, missingScheduleCount):
                calendarContent(episode: episode, missingScheduleCount: missingScheduleCount)
            case let .failed(message):
                ContentUnavailableView(
                    "Calendar unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Calendar")
        .task(id: viewModel.calendarDataID) {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refreshFromServer()
        }
    }

    private func calendarContent(
        episode: CalendarEpisode?,
        missingScheduleCount: Int
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let episode {
                    Text("Next episode")
                        .font(.title2.bold())
                    CalendarEpisodeCard(
                        episode: episode,
                        onMarkWatched: {
                            Task {
                                await viewModel.markEpisodeWatched()
                            }
                        }
                    )
                } else {
                    ContentUnavailableView(
                        "Nothing to watch next",
                        systemImage: "calendar",
                        description: Text("Follow a TV show or anime to see its next episode here.")
                    )
                }

                if missingScheduleCount > 0 {
                    Text("Episode schedules for \(missingScheduleCount) followed \(missingScheduleCount == 1 ? "show" : "shows") have not been refreshed yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

private struct CalendarEpisodeCard: View {
    let episode: CalendarEpisode
    let onMarkWatched: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: episode.posterURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(.quaternary)
                    .overlay { Image(systemName: "tv") }
            }
            .frame(width: 96, height: 144)
            .clipShape(.rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(episode.showTitle)
                    .font(.headline)
                Text("Season \(episode.episode.seasonNumber), Episode \(episode.episode.number)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(episode.episode.title)
                    .font(.title3.bold())

                if let overview = episode.episode.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
                calendarAction
            }
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var calendarAction: some View {
        if episode.episode.isReleased {
            Button(action: onMarkWatched) {
                Label("Mark as watched", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
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
