//
//  EpisodeDurationFormatter.swift
//  TVShowTracker
//
//  Created by Codex on 18/08/2026.
//

nonisolated enum EpisodeDurationFormatter {
    static func format(minutes: Int) -> String? {
        guard minutes > 0 else {
            return nil
        }

        guard minutes >= 60 else {
            return "\(minutes) min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours) hr \(remainingMinutes) min"
    }
}
