//
//  MediaCandidateMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

import Foundation

extension MediaCandidate {
    init(_ anime: AniListAnime) {
        self.init(anime, installments: [anime])
    }

    init(_ anime: AniListAnime, installments: [AniListAnime]) {
        let knownEpisodeCounts = installments.compactMap(\.episodes)
        let latestInstallment = installments.last ?? anime
        let nextEpisode = installments
            .compactMap(\.nextAiringEpisode)
            .min { $0.airingAt < $1.airingAt }

        self = .init(
            provider: .aniList,
            providerID: anime.id,
            kind: .anime,
            title: anime.title.preferredTitle,
            alternateTitle: anime.title.alternateTitle,
            posterURL: anime.coverImage.large ?? anime.coverImage.medium,
            releaseYear: anime.startDate.year,
            totalEpisodeCount: knownEpisodeCounts.isEmpty ? nil : knownEpisodeCounts.reduce(0, +),
            status: MediaStatus(anilistStatus: latestInstallment.status),
            nextEpisodeNumber: nextEpisode?.episode,
            nextEpisodeAirDate: nextEpisode.map { Date(timeIntervalSince1970: TimeInterval($0.airingAt)) },
            animeInstallments: installments.map(\.installmentReference)
        )
    }

    init(_ anime: JikanAnime) {
        self = .init(
            provider: .jikan,
            providerID: anime.id,
            kind: .anime,
            title: anime.preferredTitle,
            alternateTitle: anime.alternateTitle,
            posterURL: anime.images.jpg.largeImageURL ?? anime.images.jpg.imageURL,
            releaseYear: anime.releaseYear,
            totalEpisodeCount: anime.episodes,
            status: MediaStatus(jikanStatus: anime.status),
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    init(_ show: TMDBTVSearchResult) {
        self = .init(
            provider: .tmdb,
            providerID: show.id,
            kind: .tvShow,
            title: show.name,
            alternateTitle: show.originalName,
            posterURL: show.posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w342\($0)") },
            releaseYear: show.firstAirDate.flatMap { Int($0.prefix(4)) },
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }
}
