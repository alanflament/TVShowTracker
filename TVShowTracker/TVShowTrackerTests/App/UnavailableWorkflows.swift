//
//  UnavailableWorkflows.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct UnavailableWorkflows: TVTimeImportUseCase, DataExportUseCase, DataImportUseCase {
    func export(at _: Date) throws -> Data {
        throw CancellationError()
    }

    func importBackup(
        _: Data,
        onProgress _: @escaping @MainActor (DataImportProgress) -> Void
    ) async throws -> DataImportReport {
        throw CancellationError()
    }

    func importExport(
        at _: URL,
        onProgress _: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws -> TVTimeImportReport {
        throw CancellationError()
    }
}
