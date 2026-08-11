//
//  AnimeInstallmentReference.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct AnimeInstallmentReference: Codable, Hashable, Sendable {
    let providerID: Int
    let title: String
    let releaseYear: Int?
    let releaseMonth: Int?
    let releaseDay: Int?
    let episodeCount: Int?
    let status: SearchMediaStatus?
}
