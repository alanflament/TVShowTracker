//
//  LibraryCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct LibraryCoordinatorView: View {
    let coordinator: LibraryCoordinator
    let searchDiscover: (String) -> Void
    @State private var viewModel: LibraryViewModel

    init(
        coordinator: LibraryCoordinator,
        searchDiscover: @escaping (String) -> Void
    ) {
        self.coordinator = coordinator
        self.searchDiscover = searchDiscover
        _viewModel = State(initialValue: coordinator.makeLibraryViewModel())
    }

    var body: some View {
        NavigationStack {
            LibraryView(
                viewModel: viewModel,
                makeDetailsView: coordinator.makeDetailsView(for:),
                searchDiscover: searchDiscover
            )
        }
    }
}
