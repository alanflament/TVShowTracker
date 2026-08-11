//
//  LibraryCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct LibraryCoordinatorView: View {
    let coordinator: LibraryCoordinator
    @State private var viewModel: LibraryViewModel

    init(coordinator: LibraryCoordinator) {
        self.coordinator = coordinator
        _viewModel = State(initialValue: coordinator.makeLibraryViewModel())
    }

    var body: some View {
        NavigationStack {
            LibraryView(
                viewModel: viewModel,
                makeDetailsView: coordinator.makeDetailsView(for:)
            )
        }
    }
}
