//
//  EpisodeDetailsViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct EpisodeDetailsViewModelTests {
    @Test func loadsNetworkDetailsAndPersistsThem() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: EpisodeDetailsModel.self,
            configurations: configuration
        )
        let repository = SwiftDataEpisodeDetailsRepository(modelContext: container.mainContext)
        let episode = makeEpisode()
        let refreshedDetails = EpisodeDetails(
            episode: ShowEpisode(
                provider: .tmdb,
                showID: 42,
                seasonNumber: 1,
                number: 3,
                title: "The refreshed episode",
                overview: "A detailed synopsis.",
                airDate: .now,
                stillURL: URL(string: "https://example.com/still.jpg"),
                runtimeMinutes: 52
            ),
            voteAverage: 8.4
        )
        let viewModel = EpisodeDetailsViewModel(
            candidate: makeCandidate(),
            episode: episode,
            useCase: EpisodeDetailsUseCaseStub(details: refreshedDetails),
            episodeDetailsStore: EpisodeDetailsStore(repository: repository),
            episodeWatchStore: EpisodeWatchStore(repository: EpisodeWatchRepositoryStub())
        )

        await viewModel.load()

        #expect(try repository.loadEpisodeDetails() == [refreshedDetails])
    }

    private func makeCandidate() -> SearchCandidate {
        SearchCandidate(
            provider: .tmdb,
            providerID: 42,
            kind: .tvShow,
            title: "A show",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    private func makeEpisode() -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: 42,
            seasonNumber: 1,
            number: 3,
            title: "Episode 3",
            overview: nil,
            airDate: .now,
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}

private struct EpisodeDetailsUseCaseStub: ShowDetailsUseCase {
    let details: EpisodeDetails

    func fetchDetails(for _: SearchCandidate) async throws -> ShowDetails {
        throw EpisodeDetailsError.notFound
    }

    func fetchEpisodes(for _: SearchCandidate) async throws -> [ShowSeason] {
        []
    }

    func fetchEpisodeDetails(
        for _: SearchCandidate,
        episode _: ShowEpisode
    ) async throws -> EpisodeDetails {
        details
    }
}

@MainActor
private struct EpisodeWatchRepositoryStub: EpisodeWatchRepository {
    func loadWatchedEpisodes() throws -> [WatchedEpisode] {
        []
    }

    func save(_: WatchedEpisode) throws {}
    func save(_: [WatchedEpisode]) throws {}
    func delete(id _: String) throws {}
}
