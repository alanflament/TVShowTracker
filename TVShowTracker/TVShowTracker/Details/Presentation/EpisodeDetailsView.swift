//
//  EpisodeDetailsView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import SwiftUI

struct EpisodeDetailsView: View {
    @State private var viewModel: EpisodeDetailsViewModel
    private let onShowMediaDetails: (() -> Void)?

    init(
        viewModel: EpisodeDetailsViewModel,
        onShowMediaDetails: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onShowMediaDetails = onShowMediaDetails
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading episode details…")
            case let .loaded(details):
                detailsContent(details)
            case let .failed(message):
                ContentUnavailableView(
                    "Episode details unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle(viewModel.episode.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func detailsContent(_ details: EpisodeDetails) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if details.episode.stillURL != nil {
                    MediaPoster(
                        url: details.episode.stillURL,
                        kind: viewModel.candidate.kind,
                        height: 220,
                        cornerRadius: 16
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Season \(details.episode.seasonNumber), Episode \(details.episode.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(details.episode.title)
                        .font(.title.bold())
                }

                if let onShowMediaDetails {
                    mediaDetailsButton(action: onShowMediaDetails)
                }

                metadata(details)
                watchedButton

                if let overview = details.episode.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis")
                            .font(.title3.bold())
                        Text(overview)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    TrackerEmptyState(
                        title: "Synopsis not available",
                        systemImage: "text.alignleft",
                        description: "This provider has not published an episode synopsis yet."
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }

    private func mediaDetailsButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "tv")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.candidate.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("View show details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Replaces episode details with show details")
    }

    private func metadata(_ details: EpisodeDetails) -> some View {
        HStack(spacing: 8) {
            if let airDate = details.episode.airDate {
                Label(
                    airDate.formatted(date: .abbreviated, time: details.episode.releaseDatePrecision == .time ? .shortened : .omitted),
                    systemImage: "calendar"
                )
            }
            if let runtimeMinutes = details.episode.runtimeMinutes {
                Label("\(runtimeMinutes) min", systemImage: "clock")
            }
            if let voteAverage = details.voteAverage, voteAverage > 0 {
                Label(String(format: "%.1f", voteAverage), systemImage: "star.fill")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var watchedButton: some View {
        Button(action: viewModel.toggleWatched) {
            Label(
                viewModel.isWatched ? "Mark as unwatched" : "Mark as watched",
                systemImage: viewModel.isWatched ? "checkmark.circle.fill" : "circle"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.isWatched ? .green : .accentColor)
        .disabled(!viewModel.episode.isReleased)
        .accessibilityHint(viewModel.episode.isReleased ? "" : "This episode has not been released yet.")
    }
}
