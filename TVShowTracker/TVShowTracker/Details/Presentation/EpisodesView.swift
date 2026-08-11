//
//  EpisodesView.swift
//  TVShowTracker
//

import SwiftUI

struct EpisodesView: View {
    @State private var viewModel: EpisodesViewModel

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
            }

            ForEach(seasons) { season in
                Section {
                    ForEach(season.episodes) { episode in
                        EpisodeRow(episode: episode)
                    }
                } header: {
                    HStack {
                        Text(season.name)
                        Spacer()
                        Text("\(season.episodes.count) episodes")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct EpisodeRow: View {
    let episode: ShowEpisode

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
        }
        .accessibilityElement(children: .combine)
    }
}
