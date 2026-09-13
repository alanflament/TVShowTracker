//
//  DataExportUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

@MainActor
protocol DataExportUseCase {
    func export(at date: Date) throws -> Data
}
