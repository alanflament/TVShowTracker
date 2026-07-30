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
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(MainCoordinator.Tab.library)
            
            Color.red
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(MainCoordinator.Tab.search)
            
            Color.blue
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(MainCoordinator.Tab.settings)
        }
    }
}
