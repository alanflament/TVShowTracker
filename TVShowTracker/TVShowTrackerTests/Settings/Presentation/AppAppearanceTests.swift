//
//  AppAppearanceTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 18/08/2026.
//

import SwiftUI
import Testing
@testable import TVShowTracker

@MainActor
struct AppAppearanceTests {
    @Test func mapsEachPreferenceToItsColorScheme() {
        #expect(AppAppearance.automatic.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test func exposesAllUserFacingChoices() {
        #expect(AppAppearance.allCases.map(\.title) == ["Automatic", "Light", "Dark"])
    }
}
