//
//  JikanAnimeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct JikanAnimeDetailsRepository: AnimeDetailsRepository {
    private let apiClient: JikanAPIClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        apiClient = JikanAPIClient(httpClient: httpClient)
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        let id = try await jikanID(for: candidate)
        let response: JikanEnvelope<JikanDetailsAnime> = try await apiClient.get(path: "/v4/anime/\(id)/full")
        let anime = response.data
        return anime.asDomain
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
        let id = try await jikanID(for: candidate)
        let response: JikanEnvelope<JikanDetailsAnime> = try await apiClient.get(path: "/v4/anime/\(id)/full")
        let anime = response.data
        var page = 1
        var allEpisodes = [JikanEpisode]()

        while true {
            let response: JikanEpisodePage = try await apiClient.get(
                path: "/v4/anime/\(id)/episodes",
                queryItems: [URLQueryItem(name: "page", value: String(page))]
            )
            allEpisodes.append(contentsOf: response.data)

            guard page < response.pagination.lastPage else {
                break
            }
            page += 1
        }

        let episodes = allEpisodes
            .sorted { $0.number < $1.number }
            .map {
                $0.asDomain(
                    provider: .jikan,
                    showID: anime.id,
                    runtimeMinutes: anime.episodeDurationMinutes
                )
            }

        guard !episodes.isEmpty else {
            return []
        }

        return [ShowSeason(
            provider: .jikan,
            showID: anime.id,
            number: 1,
            name: "Episodes",
            episodes: episodes
        )]
    }
}

private extension JikanAnimeDetailsRepository {
    func jikanID(for candidate: MediaCandidate) async throws -> Int {
        guard candidate.provider != .jikan else {
            return candidate.providerID
        }

        let searchResponse: JikanSearchEnvelope = try await apiClient.get(
            path: "/v4/anime",
            queryItems: [
                URLQueryItem(name: "q", value: candidate.title),
                URLQueryItem(name: "limit", value: "10"),
                URLQueryItem(name: "sfw", value: "true")
            ]
        )

        let normalizedTitle = normalized(candidate.title)
        if let match = searchResponse.data.first(where: {
            normalized($0.title) == normalizedTitle
                || normalized($0.titleEnglish ?? "") == normalizedTitle
        }) {
            return match.id
        }

        guard let first = searchResponse.data.first else {
            throw HTTPClientError.unacceptableStatusCode(404)
        }
        return first.id
    }

    func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }
}
