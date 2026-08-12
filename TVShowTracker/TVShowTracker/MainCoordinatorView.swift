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
            LibraryCoordinatorView(coordinator: coordinator.libraryCoordinator)
                .tabItem {
                    Label("My Shows", systemImage: "rectangle.stack")
                }
                .tag(MainCoordinator.Tab.library)

            CalendarCoordinatorView(coordinator: coordinator.calendarCoordinator)
                .tabItem {
                    Label("Up Next", systemImage: "play.circle")
                }
                .tag(MainCoordinator.Tab.calendar)

            coordinator.searchCoordinator.makeSearchView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(MainCoordinator.Tab.search)

            coordinator.settingsCoordinator.makeSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(MainCoordinator.Tab.settings)
        }
    }
}
