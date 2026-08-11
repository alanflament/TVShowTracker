//
//  SettingsCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

@MainActor
final class SettingsCoordinator {
    private let tvTimeImportUseCase: any TVTimeImportUseCase

    init(tvTimeImportUseCase: any TVTimeImportUseCase) {
        self.tvTimeImportUseCase = tvTimeImportUseCase
    }

    func makeSettingsView() -> SettingsView {
        SettingsView(makeTVTimeImportViewModel: {
            TVTimeImportViewModel(useCase: self.tvTimeImportUseCase)
        })
    }
}
