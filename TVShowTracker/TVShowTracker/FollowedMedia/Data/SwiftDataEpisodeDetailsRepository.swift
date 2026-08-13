//
//  SwiftDataEpisodeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataEpisodeDetailsRepository: EpisodeDetailsRepository {
    private let modelContext: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadEpisodeDetails() throws -> [EpisodeDetails] {
        try modelContext.fetch(FetchDescriptor<EpisodeDetailsModel>()).map {
            try $0.asDomain(decoder: decoder)
        }
    }

    func save(_ details: EpisodeDetails) throws {
        let detailsID = details.id
        let descriptor = FetchDescriptor<EpisodeDetailsModel>(
            predicate: #Predicate { $0.id == detailsID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            try existing.update(with: details, encoder: encoder)
        } else {
            try modelContext.insert(EpisodeDetailsModel(details: details, encoder: encoder))
        }
        try modelContext.save()
    }
}
