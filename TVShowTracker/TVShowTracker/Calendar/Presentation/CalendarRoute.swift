//
//  CalendarRoute.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

enum CalendarRoute: Hashable {
    case media(MediaCandidate)
    case episode(CalendarEpisode)
}
