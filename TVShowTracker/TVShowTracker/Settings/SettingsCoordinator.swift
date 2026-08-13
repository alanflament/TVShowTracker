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
    private let dataExportUseCase: any DataExportUseCase
    private let dataImportUseCase: any DataImportUseCase

    init(
        tvTimeImportUseCase: any TVTimeImportUseCase,
        dataExportUseCase: any DataExportUseCase,
        dataImportUseCase: any DataImportUseCase
    ) {
        self.tvTimeImportUseCase = tvTimeImportUseCase
        self.dataExportUseCase = dataExportUseCase
        self.dataImportUseCase = dataImportUseCase
    }

    func makeSettingsView() -> SettingsView {
        SettingsView(
            makeTVTimeImportViewModel: {
                TVTimeImportViewModel(useCase: self.tvTimeImportUseCase)
            },
            dataBackupViewModel: DataBackupViewModel(
                exportUseCase: dataExportUseCase,
                importUseCase: dataImportUseCase
            )
        )
    }
}
