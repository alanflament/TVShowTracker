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
    }

    var selectedTab: Tab = .library

    let libraryCoordinator: LibraryCoordinator
    let calendarCoordinator: CalendarCoordinator
    let searchCoordinator: SearchCoordinator
    let settingsCoordinator: SettingsCoordinator

    init(container: AppContainer) {
        libraryCoordinator = container.makeLibraryCoordinator()
        calendarCoordinator = container.makeCalendarCoordinator()
        searchCoordinator = container.makeSearchCoordinator()
        settingsCoordinator = container.makeSettingsCoordinator()
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--settings-tab") {
                selectedTab = .settings
            } else if ProcessInfo.processInfo.arguments.contains("--calendar-tab") {
                selectedTab = .calendar
            } else if ProcessInfo.processInfo.arguments.contains("--discover-tab") {
                selectedTab = .search
            }
        #endif
    }
}
