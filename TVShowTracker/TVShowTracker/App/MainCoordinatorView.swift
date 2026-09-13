//
//  MainCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct MainCoordinatorView: View {
    @Bindable var coordinator: MainCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            LibraryCoordinatorView(
                coordinator: coordinator.libraryCoordinator,
                searchDiscover: coordinator.searchDiscover(for:)
            )
            .tabItem {
                Label("My Shows", systemImage: "rectangle.stack")
            }
            .tag(MainCoordinator.Tab.library)

            CalendarCoordinatorView(coordinator: coordinator.calendarCoordinator)
                .tabItem {
                    Label("Up Next", systemImage: "play.circle")
                }
                .tag(MainCoordinator.Tab.calendar)

            SearchCoordinatorView(coordinator: coordinator.searchCoordinator)
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(MainCoordinator.Tab.search)

            SettingsCoordinatorView(coordinator: coordinator.settingsCoordinator)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(MainCoordinator.Tab.settings)
        }
    }
}
