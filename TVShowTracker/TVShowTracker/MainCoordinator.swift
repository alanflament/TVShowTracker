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
        case search
        case settings
    }

    var selectedTab: Tab = .library

    let libraryCoordinator: LibraryCoordinator
    let searchCoordinator: SearchCoordinator
    let settingsCoordinator: SettingsCoordinator

    init(container: AppContainer) {
        libraryCoordinator = container.makeLibraryCoordinator()
        searchCoordinator = container.makeSearchCoordinator()
        settingsCoordinator = container.makeSettingsCoordinator()
    }
}
