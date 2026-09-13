//
//  DataImportReport.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

nonisolated struct DataImportReport: Equatable, Sendable {
    let mediaCount: Int
    let watchedEpisodeCount: Int
    let refreshedMediaCount: Int
    let refreshedScheduleCount: Int

    var mediaRefreshFailureCount: Int {
        mediaCount - refreshedMediaCount
    }
}
