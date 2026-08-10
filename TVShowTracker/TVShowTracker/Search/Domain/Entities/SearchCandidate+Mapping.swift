//
//  SearchCandidate+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

import Foundation

extension SearchCandidate {
    init(_ anime: AniListAnime) {
        self = .init(
            provider: .aniList,
            providerID: anime.id,
            kind: .anime,
            title: anime.title.preferredTitle,
            alternateTitle: anime.title.alternateTitle,
            posterURL: anime.coverImage.large ?? anime.coverImage.medium,
            releaseYear: anime.startDate.year,
            totalEpisodeCount: anime.episodes,
            status: SearchMediaStatus(anilistStatus: anime.status),
            nextEpisodeNumber: anime.nextAiringEpisode?.episode,
            nextEpisodeAirDate: anime.nextAiringEpisode.map { Date(timeIntervalSince1970: TimeInterval($0.airingAt)) }
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
            status: SearchMediaStatus(jikanStatus: anime.status),
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
