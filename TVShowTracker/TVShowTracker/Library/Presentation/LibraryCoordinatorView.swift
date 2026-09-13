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

    var body: some View {
        NavigationStack {
            LibraryView(
                viewModel: coordinator.viewModel,
                makeDetailsView: coordinator.makeDetailsView(for:),
                searchDiscover: searchDiscover
            )
        }
    }
}
