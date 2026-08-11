//
//  TVTimeExportParserError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

enum TVTimeExportParserError: LocalizedError {
    case missingFollowedShowsFile

    var errorDescription: String? {
        switch self {
        case .missingFollowedShowsFile:
            "Could not find followed_tv_show.csv in this folder. Choose the TV Time gdpr-data folder or its enclosing folder."
        }
    }
}
