//
//  ShowDetailsView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct ShowDetailsView: View {
    @State private var viewModel: ShowDetailsViewModel
    @Namespace private var posterTransition
    private let makeEpisodesView: () -> EpisodesView

    init(
        viewModel: ShowDetailsViewModel,
        makeEpisodesView: @escaping () -> EpisodesView
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeEpisodesView = makeEpisodesView
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading details…")
            case let .loaded(details):
                detailsContent(details)
            case let .failed(message):
                ContentUnavailableView(
                    "Details unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle(viewModel.candidate.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func detailsContent(_ details: ShowDetails) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header(details)

                episodeNavigation(details)

                trackingControl

                if !details.genres.isEmpty {
                    genres(details.genres)
                }

                if let overview = details.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.title3.bold())
                        Text(overview)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private func header(_ details: ShowDetails) -> some View {
        HStack(alignment: .top, spacing: 16) {
            NavigationLink {
                FullScreenMediaPosterView(
                    title: details.title,
                    posterURL: details.posterURL,
                    kind: details.kind
                )
                .navigationTransition(
                    .zoom(sourceID: PosterTransitionID.poster, in: posterTransition)
                )
            } label: {
                MediaPosterView(url: details.posterURL, kind: details.kind, width: 120, height: 180)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: PosterTransitionID.poster, in: posterTransition)
            .accessibilityLabel("View \(details.title) poster full screen")
            .accessibilityHint("Opens the poster. Use the close button or swipe back to dismiss.")

            VStack(alignment: .leading, spacing: 8) {
                Text(details.title)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                if let alternateTitle = details.alternateTitle, alternateTitle != details.title {
                    Text(alternateTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(metadata(for: details))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let status = details.status {
                    Text(status.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }
            }
        }
    }

    private var trackingControl: some View {
        Menu {
            Picker("Tracking status", selection: trackingStatusBinding) {
                ForEach(TrackingStatus.allCases) { status in
                    Label(status.title, systemImage: status.systemImage)
                        .tag(status)
                }
            }

            if viewModel.isFollowed {
                Divider()
                Button(role: .destructive) {
                    viewModel.removeFromLibrary()
                } label: {
                    Label("Remove from My Shows", systemImage: "trash")
                }
            }
        } label: {
            Label(
                viewModel.trackingStatus?.title ?? "Add to My Shows",
                systemImage: viewModel.trackingStatus?.systemImage ?? "plus.circle"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(viewModel.isFollowed ? .green : .accentColor)
    }

    private var trackingStatusBinding: Binding<TrackingStatus> {
        Binding(
            get: { viewModel.trackingStatus ?? .watching },
            set: { viewModel.setTrackingStatus($0) }
        )
    }

    private func episodeNavigation(_ details: ShowDetails) -> some View {
        NavigationLink {
            makeEpisodesView()
        } label: {
            TrackerCardView {
                HStack(spacing: 14) {
                    Image(systemName: "list.number")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor.opacity(0.14), in: .circle)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Episodes")
                            .font(.headline)
                        Text(episodeNavigationSubtitle(for: details))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func genres(_ genres: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }
            }
        }
    }

    private func metadata(for details: ShowDetails) -> String {
        MediaMetadata.text(
            releaseYear: details.releaseYear,
            totalEpisodeCount: details.totalEpisodeCount
        )
    }

    private func episodeNavigationSubtitle(for details: ShowDetails) -> String {
        if let totalEpisodeCount = details.totalEpisodeCount {
            return "\(totalEpisodeCount) episodes"
        }
        return "Browse seasons and episodes"
    }
}
