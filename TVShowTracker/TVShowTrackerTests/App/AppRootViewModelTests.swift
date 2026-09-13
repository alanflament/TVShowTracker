//
//  AppRootViewModelTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Observation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct AppRootViewModelTests {
    @Test(arguments: [1, 2], [false, true])
    func observesProgressFromRootAndExternalRefreshes(itemCount: Int, startedExternally: Bool) async throws {
        let fixture = try RefreshFixture(itemCount: itemCount)
        let viewModel = AppRootViewModel(followedMediaRefreshStore: fixture.store)
        #expect(!viewModel.isRefreshingFollowedMedia)

        await confirmation("Derived banner state observes the shared store") { changed in
            withObservationTracking {
                _ = viewModel.isRefreshingFollowedMedia
                _ = viewModel.followedMediaRefreshMessage
            } onChange: {
                changed()
            }

            let refreshTask = Task {
                if startedExternally {
                    await fixture.store.refresh(force: true)
                } else {
                    await viewModel.refreshFollowedMedia()
                }
            }
            await fixture.gate.waitUntilPaused()

            #expect(viewModel.isRefreshingFollowedMedia)
            let noun = itemCount == 1 ? "show" : "shows"
            #expect(viewModel.followedMediaRefreshMessage == "Checking 1 of \(itemCount) \(noun) for new episodes…")

            await fixture.gate.release()
            await refreshTask.value

            #expect(!viewModel.isRefreshingFollowedMedia)
            #expect(fixture.store.processedMediaCount == itemCount)
            #expect(viewModel.followedMediaRefreshMessage == "Checking \(itemCount) of \(itemCount) \(noun) for new episodes…")
        }
    }

    @Test func emptyLibraryKeepsTheBannerHidden() async throws {
        let fixture = try RefreshFixture(itemCount: 0)
        let viewModel = AppRootViewModel(followedMediaRefreshStore: fixture.store)

        await viewModel.refreshFollowedMedia()

        #expect(!viewModel.isRefreshingFollowedMedia)
        #expect(viewModel.followedMediaRefreshMessage == "Checking your saved shows for new episodes…")
        #expect(fixture.store.totalMediaCount == 0)
    }
}
