//
//  JikanEpisodePage.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanEpisodePage: Decodable {
    let data: [JikanEpisode]
    let pagination: JikanPagination
}
