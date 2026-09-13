//
//  AniListTestRequestBody.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct AniListTestRequestBody: Decodable {
    let query: String
    let variables: [String: Int]
}
