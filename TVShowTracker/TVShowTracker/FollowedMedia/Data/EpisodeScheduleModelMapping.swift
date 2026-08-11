//
//  EpisodeScheduleModelMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

extension EpisodeScheduleModel {
    convenience init(schedule: EpisodeSchedule, encoder: JSONEncoder = JSONEncoder()) throws {
        try self.init(
            id: schedule.id,
            seasonsData: encoder.encode(schedule.seasons),
            refreshedAt: schedule.refreshedAt
        )
    }

    func update(with schedule: EpisodeSchedule, encoder: JSONEncoder = JSONEncoder()) throws {
        seasonsData = try encoder.encode(schedule.seasons)
        refreshedAt = schedule.refreshedAt
    }

    func asDomain(decoder: JSONDecoder = JSONDecoder()) throws -> EpisodeSchedule {
        try EpisodeSchedule(
            itemID: id,
            seasons: decoder.decode([ShowSeason].self, from: seasonsData),
            refreshedAt: refreshedAt
        )
    }
}
