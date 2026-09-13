//
//  SettingsCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct SettingsCoordinatorView: View {
    let coordinator: SettingsCoordinator

    var body: some View {
        NavigationStack {
            SettingsView(
                viewModel: coordinator.viewModel,
                makeTVTimeImportView: coordinator.makeTVTimeImportView
            )
        }
    }
}
