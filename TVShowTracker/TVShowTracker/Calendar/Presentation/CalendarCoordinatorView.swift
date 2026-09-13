//
//  CalendarCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct CalendarCoordinatorView: View {
    let coordinator: CalendarCoordinator
    @State private var path = [CalendarRoute]()

    var body: some View {
        NavigationStack(path: $path) {
            CalendarView(
                viewModel: coordinator.viewModel,
                onSelectMedia: { candidate in
                    path.append(.media(candidate))
                },
                onSelectEpisode: { episode in
                    path.append(.episode(episode))
                }
            )
            .navigationDestination(for: CalendarRoute.self) { route in
                switch route {
                case let .media(candidate):
                    coordinator.makeDetailsView(for: candidate)
                case let .episode(episode):
                    UpNextDetailsDestinationView(
                        coordinator: coordinator,
                        episode: episode
                    )
                }
            }
        }
    }
}
