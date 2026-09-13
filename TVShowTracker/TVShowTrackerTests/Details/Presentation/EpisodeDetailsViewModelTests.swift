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

    @Test func cancellationDoesNotPersistResultsAndAllowsAnotherLoad() async throws {
        let container = try ModelContainer(
            for: EpisodeDetailsModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataEpisodeDetailsRepository(modelContext: container.mainContext)
        let details = EpisodeDetails(episode: makeEpisode())
        let viewModel = EpisodeDetailsViewModel(
            candidate: makeCandidate(), episode: makeEpisode(),
            useCase: EpisodeDetailsUseCaseStub(details: details),
            episodeDetailsStore: EpisodeDetailsStore(repository: repository),
            episodeWatchStore: EpisodeWatchStore(repository: EpisodeWatchRepositoryStub())
        )
        let cancelledLoad = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await viewModel.load()
        }
        await cancelledLoad.value
        #expect(try repository.loadEpisodeDetails().isEmpty)
        guard case .idle = viewModel.state else {
            Issue.record("A cancelled initial load must remain retryable")
            return
        }
        await viewModel.load()
        #expect(try repository.loadEpisodeDetails() == [details])
    }

    private func makeCandidate() -> MediaCandidate {
        MediaCandidate(
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

    func fetchDetails(for _: MediaCandidate) async throws -> ShowDetails {
        throw EpisodeDetailsError.notFound
    }

    func fetchEpisodes(for _: MediaCandidate) async throws -> [ShowSeason] {
        []
    }

    func fetchEpisodeDetails(
        for _: MediaCandidate,
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
    func delete(ids _: [String]) throws {}
}
