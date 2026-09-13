//
//  EpisodeDetailsModelMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

extension EpisodeDetailsModel {
    convenience init(details: EpisodeDetails, encoder: JSONEncoder = JSONEncoder()) throws {
        try self.init(id: details.id, detailsData: encoder.encode(details))
    }

    func update(with details: EpisodeDetails, encoder: JSONEncoder = JSONEncoder()) throws {
        detailsData = try encoder.encode(details)
    }

    func asDomain(decoder: JSONDecoder = JSONDecoder()) throws -> EpisodeDetails {
        try decoder.decode(EpisodeDetails.self, from: detailsData)
    }
}
