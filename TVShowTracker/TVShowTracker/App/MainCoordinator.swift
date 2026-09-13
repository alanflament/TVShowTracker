//
//  MainCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class MainCoordinator {
    enum Tab: Hashable {
        case library
        case calendar
        case search
        case settings

        static func initial(isLibraryEmpty: Bool, hasUpNextEpisodes: Bool) -> Self {
            if isLibraryEmpty {
                return .search
            }
            return hasUpNextEpisodes ? .calendar : .library
        }
    }

    var selectedTab: Tab

    let libraryCoordinator: LibraryCoordinator
    let calendarCoordinator: CalendarCoordinator
    let searchCoordinator: SearchCoordinator
    let settingsCoordinator: SettingsCoordinator

    init(
        initialTab: Tab,
        libraryCoordinator: LibraryCoordinator,
        calendarCoordinator: CalendarCoordinator,
        searchCoordinator: SearchCoordinator,
        settingsCoordinator: SettingsCoordinator
    ) {
        selectedTab = initialTab
        self.libraryCoordinator = libraryCoordinator
        self.calendarCoordinator = calendarCoordinator
        self.searchCoordinator = searchCoordinator
        self.settingsCoordinator = settingsCoordinator
    }

    func searchDiscover(for query: String) {
        searchCoordinator.search(for: query)
        selectedTab = .search
    }
}
