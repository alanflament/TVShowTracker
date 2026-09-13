//
//  SettingsCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
final class SettingsCoordinator {
    let viewModel: DataBackupViewModel
    private let tvTimeImportUseCase: any TVTimeImportUseCase

    init(
        tvTimeImportUseCase: any TVTimeImportUseCase,
        dataExportUseCase: any DataExportUseCase,
        dataImportUseCase: any DataImportUseCase
    ) {
        self.tvTimeImportUseCase = tvTimeImportUseCase
        viewModel = DataBackupViewModel(
            exportUseCase: dataExportUseCase,
            importUseCase: dataImportUseCase
        )
    }

    func makeTVTimeImportView() -> TVTimeImportView {
        TVTimeImportView(viewModel: TVTimeImportViewModel(useCase: tvTimeImportUseCase))
    }
}
