//
//  SearchMediaStatusTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct SearchMediaStatusTests {
    @Test func onlyTerminalMediaStatusesSkipEpisodeScheduleRefresh() {
        #expect(!SearchMediaStatus.finished.requiresEpisodeScheduleRefresh)
        #expect(!SearchMediaStatus.cancelled.requiresEpisodeScheduleRefresh)
        #expect(SearchMediaStatus.airing.requiresEpisodeScheduleRefresh)
        #expect(SearchMediaStatus.upcoming.requiresEpisodeScheduleRefresh)
        #expect(SearchMediaStatus.hiatus.requiresEpisodeScheduleRefresh)
    }

    @Test func terminalMediaUsesAMonthlyLifecycleCheckUnlessForced() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let candidate = SearchCandidate(
            provider: .tmdb,
            providerID: 1,
            kind: .tvShow,
            title: "Finished show",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .finished,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
        let recentlyChecked = LibraryItem(
            candidate: candidate,
            lastLifecycleCheckAt: now.addingTimeInterval(-29 * 24 * 60 * 60)
        )
        let overdue = LibraryItem(
            candidate: candidate,
            lastLifecycleCheckAt: now.addingTimeInterval(-30 * 24 * 60 * 60)
        )

        #expect(!recentlyChecked.requiresProviderRefresh(
            at: now,
            force: false,
            scheduleRefreshedAt: nil
        ))
        #expect(recentlyChecked.requiresProviderRefresh(
            at: now,
            force: true,
            scheduleRefreshedAt: now
        ))
        #expect(overdue.requiresProviderRefresh(
            at: now,
            force: false,
            scheduleRefreshedAt: nil
        ))
    }

    @Test func terminalLifecycleChecksIncludeCompletedButNotPausedMedia() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let completed = makeItem(
            status: .finished,
            trackingStatus: .completed,
            lastLifecycleCheckAt: now.addingTimeInterval(-30 * 24 * 60 * 60)
        )
        let paused = makeItem(
            status: .finished,
            trackingStatus: .paused,
            lastLifecycleCheckAt: now.addingTimeInterval(-30 * 24 * 60 * 60)
        )

        #expect(completed.requiresProviderRefresh(at: now, force: false, scheduleRefreshedAt: nil))
        #expect(!paused.requiresProviderRefresh(at: now, force: false, scheduleRefreshedAt: nil))
    }

    @Test func activeMediaUsesThePersistedScheduleRefreshDate() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let airing = makeItem(status: .airing)
        let upcoming = makeItem(status: .upcoming)
        let unknown = makeItem(status: nil)
        let hiatus = makeItem(status: .hiatus)

        for item in [airing, upcoming, unknown] {
            #expect(!item.requiresProviderRefresh(
                at: now,
                force: false,
                scheduleRefreshedAt: now.addingTimeInterval(-24 * 60 * 60 + 1)
            ))
            #expect(item.requiresProviderRefresh(
                at: now,
                force: false,
                scheduleRefreshedAt: now.addingTimeInterval(-24 * 60 * 60)
            ))
        }

        #expect(!hiatus.requiresProviderRefresh(
            at: now,
            force: false,
            scheduleRefreshedAt: now.addingTimeInterval(-7 * 24 * 60 * 60 + 1)
        ))
        #expect(hiatus.requiresProviderRefresh(
            at: now,
            force: false,
            scheduleRefreshedAt: now.addingTimeInterval(-7 * 24 * 60 * 60)
        ))
    }

    @Test func automaticRefreshOnlyIncludesWatchingMediaButForceOverridesIt() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let paused = makeItem(status: .airing, trackingStatus: .paused)

        #expect(!paused.requiresProviderRefresh(
            at: now,
            force: false,
            scheduleRefreshedAt: nil
        ))
        #expect(paused.requiresProviderRefresh(
            at: now,
            force: true,
            scheduleRefreshedAt: now
        ))
    }

    private func makeItem(
        status: SearchMediaStatus?,
        trackingStatus: TrackingStatus = .watching,
        lastLifecycleCheckAt: Date? = nil
    ) -> LibraryItem {
        LibraryItem(
            candidate: SearchCandidate(
                provider: .tmdb,
                providerID: 2,
                kind: .tvShow,
                title: "Show",
                alternateTitle: nil,
                posterURL: nil,
                releaseYear: nil,
                totalEpisodeCount: nil,
                status: status,
                nextEpisodeNumber: nil,
                nextEpisodeAirDate: nil
            ),
            trackingStatus: trackingStatus,
            lastLifecycleCheckAt: lastLifecycleCheckAt
        )
    }
}
