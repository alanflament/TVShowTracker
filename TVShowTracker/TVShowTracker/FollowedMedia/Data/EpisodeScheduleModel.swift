//
//  EpisodeScheduleModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftData

@Model
final class EpisodeScheduleModel {
    @Attribute(.unique) var id: String
    var seasonsData: Data
    var refreshedAt: Date

    init(id: String, seasonsData: Data, refreshedAt: Date) {
        self.id = id
        self.seasonsData = seasonsData
        self.refreshedAt = refreshedAt
    }
}
