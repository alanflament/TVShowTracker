//
//  WatchedEpisodeModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftData

@Model
final class WatchedEpisodeModel {
    @Attribute(.unique) var id: String
    var watchedAt: Date

    init(id: String, watchedAt: Date) {
        self.id = id
        self.watchedAt = watchedAt
    }
}
