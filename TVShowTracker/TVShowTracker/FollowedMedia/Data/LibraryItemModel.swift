//
//  LibraryItemModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation
import SwiftData

@Model
final class LibraryItemModel {
    @Attribute(.unique) var id: String
    var providerRawValue: String
    var providerID: Int
    var kindRawValue: String
    var title: String
    var alternateTitle: String?
    var posterURLString: String?
    var releaseYear: Int?
    var totalEpisodeCount: Int?
    var statusRawValue: String?
    var nextEpisodeNumber: Int?
    var nextEpisodeAirDate: Date?
    var animeInstallmentsData: Data
    var addedAt: Date

    init(
        id: String,
        providerRawValue: String,
        providerID: Int,
        kindRawValue: String,
        title: String,
        alternateTitle: String?,
        posterURLString: String?,
        releaseYear: Int?,
        totalEpisodeCount: Int?,
        statusRawValue: String?,
        nextEpisodeNumber: Int?,
        nextEpisodeAirDate: Date?,
        animeInstallmentsData: Data,
        addedAt: Date
    ) {
        self.id = id
        self.providerRawValue = providerRawValue
        self.providerID = providerID
        self.kindRawValue = kindRawValue
        self.title = title
        self.alternateTitle = alternateTitle
        self.posterURLString = posterURLString
        self.releaseYear = releaseYear
        self.totalEpisodeCount = totalEpisodeCount
        self.statusRawValue = statusRawValue
        self.nextEpisodeNumber = nextEpisodeNumber
        self.nextEpisodeAirDate = nextEpisodeAirDate
        self.animeInstallmentsData = animeInstallmentsData
        self.addedAt = addedAt
    }
}
