//
//  AniListAnimeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct AniListAnimeDetailsRepository: AnimeDetailsRepository {
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        let id = try await aniListID(for: candidate)
        let details = try await request(id: id, query: Self.detailsQuery).asDomain
        guard !candidate.animeInstallments.isEmpty else {
            return details
        }

        return ShowDetails(
            provider: details.provider,
            providerID: details.providerID,
            kind: details.kind,
            title: details.title,
            alternateTitle: details.alternateTitle,
            overview: details.overview,
            posterURL: details.posterURL,
            backdropURL: details.backdropURL,
            releaseYear: details.releaseYear,
            status: candidate.status,
            totalEpisodeCount: candidate.totalEpisodeCount,
            genres: details.genres,
            seasonSummaries: candidate.animeInstallments.enumerated().map { index, installment in
                SeasonSummary(
                    provider: .aniList,
                    showID: installment.providerID,
                    number: index + 1,
                    name: installment.title,
                    episodeCount: installment.episodeCount ?? 0,
                    airDate: nil
                )
            }
        )
    }

    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason] {
        let installments: [AnimeInstallmentReference]
        if candidate.animeInstallments.isEmpty {
            let id = try await aniListID(for: candidate)
            installments = [AnimeInstallmentReference(
                providerID: id,
                title: candidate.title,
                releaseYear: candidate.releaseYear,
                releaseMonth: nil,
                releaseDay: nil,
                episodeCount: candidate.totalEpisodeCount,
                status: candidate.status
            )]
        } else {
            installments = candidate.animeInstallments
        }

        var seasons = [ShowSeason]()
        for (index, installment) in installments.enumerated() {
            let anime = try await request(id: installment.providerID, query: Self.episodesQuery)
            seasons.append(makeSeason(from: anime, installment: installment, number: index + 1))
        }
        return seasons
    }

    private func makeSeason(
        from anime: AniListDetailsAnime,
        installment: AnimeInstallmentReference,
        number seasonNumber: Int
    ) -> ShowSeason {
        let totalEpisodes = anime.episodes ?? anime.airingSchedule?.nodes.map(\.episode).max() ?? 0

        let airingDates = Dictionary(uniqueKeysWithValues: (anime.airingSchedule?.nodes ?? []).map {
            ($0.episode, Date(timeIntervalSince1970: TimeInterval($0.airingAt)))
        })

        let episodeNumbers = totalEpisodes > 0 ? Array(1 ... totalEpisodes) : []
        let episodes = episodeNumbers.map { number in
            ShowEpisode(
                provider: .aniList,
                showID: anime.id,
                seasonNumber: seasonNumber,
                number: number,
                title: "Episode \(number)",
                overview: nil,
                airDate: airingDates[number],
                stillURL: nil,
                runtimeMinutes: nil
            )
        }

        return ShowSeason(
            provider: .aniList,
            showID: anime.id,
            number: seasonNumber,
            name: installment.title,
            episodes: episodes
        )
    }
}

private extension AniListAnimeDetailsRepository {
    func aniListID(for candidate: SearchCandidate) async throws -> Int {
        switch candidate.provider {
        case .aniList:
            return candidate.providerID
        case .jikan:
            let body = AniListDetailsGraphQLRequest(
                query: Self.malIDQuery,
                variables: ["idMal": candidate.providerID]
            )
            var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await httpClient.data(for: request)
            try response.validateSuccessfulStatusCode()
            let result = try JSONDecoder().decode(AniListDetailsResponse.self, from: data)
            guard let id = result.data?.media?.id else {
                throw AniListAPIError.queryFailed("Anime details were not found.")
            }
            return id
        case .tmdb:
            throw AniListAPIError.queryFailed("This result is not an anime.")
        }
    }

    func request(id: Int, query: String) async throws -> AniListDetailsAnime {
        let body = AniListDetailsGraphQLRequest(
            query: query,
            variables: ["id": id]
        )

        var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await httpClient.data(for: request)
        if let graphQLResponse = try? JSONDecoder().decode(AniListDetailsResponse.self, from: data),
           let message = graphQLResponse.errors?.first?.message
        {
            throw AniListAPIError.queryFailed(message)
        }
        try response.validateSuccessfulStatusCode()

        let graphQLResponse = try JSONDecoder().decode(AniListDetailsResponse.self, from: data)
        guard let anime = graphQLResponse.data?.media else {
            throw AniListAPIError.queryFailed("Anime details were not found.")
        }
        return anime
    }

    static let detailsQuery = """
    query AnimeDetails($id: Int!) {
      Media(id: $id, type: ANIME) {
        id
        title { userPreferred english romaji native }
        description(asHtml: false)
        coverImage { large medium }
        status
        episodes
        startDate { year }
        genres
      }
    }
    """

    static let malIDQuery = """
    query AnimeID($idMal: Int!) {
      Media(idMal: $idMal, type: ANIME) {
        id
        title { userPreferred english romaji native }
        coverImage { large medium }
        startDate { year }
        genres
      }
    }
    """

    static let episodesQuery = """
    query AnimeEpisodes($id: Int!) {
      Media(id: $id, type: ANIME) {
        id
        title { userPreferred english romaji native }
        description(asHtml: false)
        coverImage { large medium }
        status
        episodes
        startDate { year }
        genres
        airingSchedule(perPage: 100) {
          nodes { episode airingAt }
        }
      }
    }
    """
}
