//
//  DateParser.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

enum DateParser {
    nonisolated static func parseISO8601(_ value: String?) -> Date? {
        guard let value else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value)
            ?? ISO8601DateFormatter().date(from: "\(value)T00:00:00Z")
    }

    nonisolated static func parseYear(_ value: String?) -> Int? {
        value.flatMap { Int($0.prefix(4)) }
    }
}
