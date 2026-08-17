//
//  MainCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

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

    init(container: AppContainer, initialTab: Tab) {
        selectedTab = initialTab
        libraryCoordinator = container.makeLibraryCoordinator()
        calendarCoordinator = container.makeCalendarCoordinator()
        searchCoordinator = container.makeSearchCoordinator()
        settingsCoordinator = container.makeSettingsCoordinator()
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--library-tab") {
                selectedTab = .library
            } else if ProcessInfo.processInfo.arguments.contains("--settings-tab") {
                selectedTab = .settings
            } else if ProcessInfo.processInfo.arguments.contains("--calendar-tab") {
                selectedTab = .calendar
            } else if ProcessInfo.processInfo.arguments.contains("--discover-tab") {
                selectedTab = .search
            }
        #endif
    }

    func searchDiscover(for query: String) {
        searchCoordinator.search(for: query)
        selectedTab = .search
    }
}
