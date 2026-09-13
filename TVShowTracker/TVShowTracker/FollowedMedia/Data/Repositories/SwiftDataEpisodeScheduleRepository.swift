//
//  SwiftDataEpisodeScheduleRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataEpisodeScheduleRepository: EpisodeScheduleRepository {
    private let modelContext: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSchedules() throws -> [EpisodeSchedule] {
        let descriptor = FetchDescriptor<EpisodeScheduleModel>(
            sortBy: [SortDescriptor(\EpisodeScheduleModel.refreshedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { try $0.asDomain(decoder: decoder) }
    }

    func save(_ schedule: EpisodeSchedule) throws {
        try modelContext.saveChanges {
            let scheduleID = schedule.id
            let descriptor = FetchDescriptor<EpisodeScheduleModel>(
                predicate: #Predicate { $0.id == scheduleID }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                try existing.update(with: schedule, encoder: encoder)
            } else {
                try modelContext.insert(EpisodeScheduleModel(schedule: schedule, encoder: encoder))
            }
        }
    }

    func delete(id: String) throws {
        try modelContext.saveChanges {
            let descriptor = FetchDescriptor<EpisodeScheduleModel>(
                predicate: #Predicate { $0.id == id }
            )
            if let schedule = try modelContext.fetch(descriptor).first {
                modelContext.delete(schedule)
            }
        }
    }
}
