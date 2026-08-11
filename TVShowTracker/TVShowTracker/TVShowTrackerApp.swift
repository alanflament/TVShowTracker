//
//  TVShowTrackerApp.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import SwiftData
import SwiftUI

@main
struct TVShowTrackerApp: App {
    @State private var coordinator: AppCoordinator
    private let modelContainer: ModelContainer

    init() {
        let container = AppContainer()
        modelContainer = container.modelContainer
        _coordinator = State(initialValue: container.makeAppCoordinator())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(coordinator)
        }
        .modelContainer(modelContainer)
    }
}
