//
//  TVShowTrackerBackupDocument.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct TVShowTrackerBackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
