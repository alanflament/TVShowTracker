//
//  ShowRefreshSnapshot.swift
//  TVShowTracker
//
//  Created by Alan Flament on 16/08/2026.
//

struct ShowRefreshSnapshot: Sendable {
    let details: ShowDetails
    let seasons: [ShowSeason]?
}
