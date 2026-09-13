//
//  SearchCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct SearchCoordinatorView: View {
    let coordinator: SearchCoordinator
    @State private var selectedCandidate: MediaCandidate?

    var body: some View {
        NavigationStack {
            SearchView(
                viewModel: coordinator.viewModel,
                onSelectMedia: { selectedCandidate = $0 }
            )
            .sheet(item: $selectedCandidate) { candidate in
                coordinator.makeDetailsSheet(for: candidate)
            }
        }
    }
}
