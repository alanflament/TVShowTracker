//
//  TVTimeImportUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
protocol TVTimeImportUseCase {
    func importExport(
        at folderURL: URL,
        onProgress: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws -> TVTimeImportReport
}
