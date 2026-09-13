//
//  TVTimeExportParsing.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

protocol TVTimeExportParsing: Sendable {
    func parseExport(at folderURL: URL) throws -> TVTimeExport
}
