//
//  LibraryPersistenceError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation

enum LibraryPersistenceError: LocalizedError {
    case invalidStoredItem(id: String)

    var errorDescription: String? {
        switch self {
        case let .invalidStoredItem(id):
            "The saved item \(id) is no longer compatible with this version of the app."
        }
    }
}
