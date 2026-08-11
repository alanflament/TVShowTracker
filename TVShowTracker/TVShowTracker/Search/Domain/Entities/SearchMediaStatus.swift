//
//  SearchMediaStatus.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

enum SearchMediaStatus: String, Codable, Hashable, Sendable {
    case airing
    case finished
    case upcoming
    case cancelled
    case hiatus
}
