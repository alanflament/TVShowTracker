//
//  DataImportError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

nonisolated enum DataImportError: LocalizedError, Equatable {
    case unsupportedSchemaVersion(Int)
    case invalidRecord(String)

    var errorDescription: String? {
        switch self {
        case .invalidRecord:
            "This backup contains an invalid record. Export a new backup and try again."
        case let .unsupportedSchemaVersion(version):
            "This backup uses unsupported schema version \(version). Update TVShowTracker and try again."
        }
    }
}
