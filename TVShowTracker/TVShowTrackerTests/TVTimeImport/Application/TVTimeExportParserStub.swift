//
//  TVTimeExportParserStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct TVTimeExportParserStub: TVTimeExportParsing {
    let export: TVTimeExport

    func parseExport(at _: URL) throws -> TVTimeExport {
        export
    }
}
