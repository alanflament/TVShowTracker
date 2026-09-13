//
//  DataImportUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

@MainActor
protocol DataImportUseCase {
    func importBackup(
        _ data: Data,
        onProgress: @escaping @MainActor (DataImportProgress) -> Void
    ) async throws -> DataImportReport
}
