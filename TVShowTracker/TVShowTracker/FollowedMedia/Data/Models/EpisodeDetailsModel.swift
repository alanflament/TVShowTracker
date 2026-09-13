//
//  EpisodeDetailsModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import SwiftData

@Model
final class EpisodeDetailsModel {
    @Attribute(.unique) var id: String
    var detailsData: Data

    init(id: String, detailsData: Data) {
        self.id = id
        self.detailsData = detailsData
    }
}
