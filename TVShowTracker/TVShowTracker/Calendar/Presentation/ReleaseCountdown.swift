//
//  ReleaseCountdown.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftUI

struct ReleaseCountdown {
    let airDate: Date
    let precision: EpisodeReleaseDatePrecision

    var text: String {
        let interval = max(0, airDate.timeIntervalSinceNow)
        if precision == .time, interval < 86400 {
            let hours = max(1, Int(ceil(interval / 3600)))
            return "Available in \(hours) \(hours == 1 ? "hour" : "hours")"
        }

        let days = Int(ceil(interval / 86400))
        return "Available in \(days) \(days == 1 ? "day" : "days")"
    }
}
