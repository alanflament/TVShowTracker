//
//  EpisodeScheduleRefreshUseCaseTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct EpisodeScheduleRefreshUseCaseTests {
    @Test func refreshLimitsTheNumberOfConcurrentProviderRequests() async {
        let probe = RefreshConcurrencyProbe()
        let useCase = DefaultEpisodeScheduleRefreshUseCase(
            showDetailsUseCase: ConcurrentDetailsUseCase(probe: probe)
        )
        let items = (1 ... 10).map { makeItem(id: $0) }

        let results = await useCase.refreshSchedules(for: items)
        let peakConcurrentRequests = await probe.peakConcurrentRequests()

        #expect(results.count == items.count)
        #expect(peakConcurrentRequests <= 4)
    }

    private func makeItem(
        id: Int,
        trackingStatus: TrackingStatus = .watching
    ) -> LibraryItem {
        LibraryItem(candidate: MediaCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: "Show \(id)",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        ), trackingStatus: trackingStatus)
    }
}

private actor RefreshConcurrencyProbe {
    private var activeRequestCount = 0
    private var maximumRequestCount = 0

    func beginRequest() {
        activeRequestCount += 1
        maximumRequestCount = max(maximumRequestCount, activeRequestCount)
    }

    func finishRequest() {
        activeRequestCount -= 1
    }

    func peakConcurrentRequests() -> Int {
        maximumRequestCount
    }
}

private struct ConcurrentDetailsUseCase: ShowDetailsUseCase {
    let probe: RefreshConcurrencyProbe

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        ShowDetails(
            provider: candidate.provider,
            providerID: candidate.providerID,
            kind: candidate.kind,
            title: candidate.title,
            alternateTitle: nil,
            overview: nil,
            posterURL: nil,
            backdropURL: nil,
            releaseYear: nil,
            status: .airing,
            totalEpisodeCount: nil,
            genres: [],
            seasonSummaries: []
        )
    }

    func fetchEpisodes(for _: MediaCandidate) async throws -> [ShowSeason] {
        await probe.beginRequest()
        try? await Task.sleep(nanoseconds: 20_000_000)
        await probe.finishRequest()
        return []
    }
}
