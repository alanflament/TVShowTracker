//
//  DataImportProgress.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

nonisolated struct DataImportProgress: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case restoringBackup
        case refreshingMedia
    }

    let phase: Phase
    let completedUnitCount: Int
    let totalUnitCount: Int
    let currentTitle: String?
}
