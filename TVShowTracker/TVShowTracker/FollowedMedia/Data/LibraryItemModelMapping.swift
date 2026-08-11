//
//  LibraryItemModelMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation

extension LibraryItemModel {
    convenience init(item: LibraryItem, encoder: JSONEncoder = JSONEncoder()) throws {
        try self.init(
            id: item.id,
            providerRawValue: item.provider.rawValue,
            providerID: item.providerID,
            kindRawValue: item.kind.rawValue,
            title: item.title,
            alternateTitle: item.alternateTitle,
            posterURLString: item.posterURL?.absoluteString,
            releaseYear: item.releaseYear,
            totalEpisodeCount: item.totalEpisodeCount,
            statusRawValue: item.status?.rawValue,
            nextEpisodeNumber: item.nextEpisodeNumber,
            nextEpisodeAirDate: item.nextEpisodeAirDate,
            animeInstallmentsData: encoder.encode(item.animeInstallments),
            addedAt: item.addedAt
        )
    }

    func update(with item: LibraryItem, encoder: JSONEncoder = JSONEncoder()) throws {
        providerRawValue = item.provider.rawValue
        providerID = item.providerID
        kindRawValue = item.kind.rawValue
        title = item.title
        alternateTitle = item.alternateTitle
        posterURLString = item.posterURL?.absoluteString
        releaseYear = item.releaseYear
        totalEpisodeCount = item.totalEpisodeCount
        statusRawValue = item.status?.rawValue
        nextEpisodeNumber = item.nextEpisodeNumber
        nextEpisodeAirDate = item.nextEpisodeAirDate
        animeInstallmentsData = try encoder.encode(item.animeInstallments)
    }

    func asDomain(decoder: JSONDecoder = JSONDecoder()) throws -> LibraryItem {
        guard let provider = SearchProvider(rawValue: providerRawValue),
              let kind = SearchMediaKind(rawValue: kindRawValue)
        else {
            throw LibraryPersistenceError.invalidStoredItem(id: id)
        }

        let installments: [AnimeInstallmentReference]
        if animeInstallmentsData.isEmpty {
            installments = []
        } else {
            installments = try decoder.decode([AnimeInstallmentReference].self, from: animeInstallmentsData)
        }

        return LibraryItem(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: title,
            alternateTitle: alternateTitle,
            posterURL: posterURLString.flatMap(URL.init(string:)),
            releaseYear: releaseYear,
            totalEpisodeCount: totalEpisodeCount,
            status: statusRawValue.flatMap(SearchMediaStatus.init(rawValue:)),
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: installments,
            addedAt: addedAt
        )
    }
}
