//
//  LibraryCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct LibraryCoordinatorView: View {
    @Bindable var coordinator: LibraryCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            LibraryView(
                viewModel: coordinator.makeLibraryViewModel(),
                onAddTapped: coordinator.createItem,
                onItemTapped: coordinator.showItem(id:)
            )
            .navigationDestination(for: LibraryCoordinator.Route.self) { route in
                switch route {
                case .detail:
                    Color.green
                }
            }
            .sheet(item: $coordinator.sheet) { sheet in
                switch sheet {
                case .create:
                    Color.yellow
                    // TODO: action: coordinator.sheet = nil
                }
            }
        }
    }
}
