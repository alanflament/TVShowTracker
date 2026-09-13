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
