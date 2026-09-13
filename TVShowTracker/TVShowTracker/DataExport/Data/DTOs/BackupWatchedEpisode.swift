//
//  BackupWatchedEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct BackupWatchedEpisode: Codable, Equatable, Sendable {
    let id: String
    let watchedAt: Date
}
