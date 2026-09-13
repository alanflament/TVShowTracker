//
//  BackupCodec.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct BackupCodec {
    func encode(_ backup: TVShowTrackerBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(backup)
    }

    func decode(_ data: Data) throws -> TVShowTrackerBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(TVShowTrackerBackup.self, from: data)
        guard backup.schemaVersion == TVShowTrackerBackup.currentSchemaVersion else {
            throw DataImportError.unsupportedSchemaVersion(backup.schemaVersion)
        }
        for item in backup.media {
            guard item.providerID > 0,
                  item.id == "\(item.provider.rawValue):\(item.providerID)",
                  (item.provider == .tmdb) == (item.kind == .tvShow),
                  !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  item.animeInstallments.allSatisfy({ $0.providerID > 0 })
            else {
                throw DataImportError.invalidRecord(item.id)
            }
        }
        for episode in backup.watchedEpisodes {
            let parts = episode.id.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 4,
                  MediaProvider(rawValue: String(parts[0])) != nil,
                  let showID = Int(parts[1]), showID > 0,
                  let season = Int(parts[2]), season >= 0,
                  let number = Int(parts[3]), number > 0
            else {
                throw DataImportError.invalidRecord(episode.id)
            }
        }
        return backup
    }
}
