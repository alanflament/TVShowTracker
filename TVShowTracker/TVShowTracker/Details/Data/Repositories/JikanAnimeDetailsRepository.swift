//
//  JikanAnimeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct JikanAnimeDetailsRepository: AnimeDetailsRepository {
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        let id = try await jikanID(for: candidate)
        let anime: JikanDetailsAnime = try await request(path: "/v4/anime/\(id)/full")
        return anime.asDomain
    }

    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason] {
        let id = try await jikanID(for: candidate)
        let anime: JikanDetailsAnime = try await request(path: "/v4/anime/\(id)/full")
        var page = 1
        var allEpisodes = [JikanEpisode]()

        while true {
            let response: JikanEpisodePage = try await request(
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
            .map { $0.asDomain(provider: .jikan, showID: anime.id) }

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
    func jikanID(for candidate: SearchCandidate) async throws -> Int {
        guard candidate.provider != .jikan else {
            return candidate.providerID
        }

        var components = URLComponents(string: "https://api.jikan.moe/v4/anime")
        components?.queryItems = [
            URLQueryItem(name: "q", value: candidate.title),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await httpClient.data(for: request)
        try response.validateSuccessfulStatusCode()
        let searchResponse = try JSONDecoder().decode(JikanSearchEnvelope.self, from: data)

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

    func request<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        var components = URLComponents(string: "https://api.jikan.moe")
        components?.path = path
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await httpClient.data(for: request)
        try response.validateSuccessfulStatusCode()
        return try JSONDecoder().decode(JikanEnvelope<Response>.self, from: data).data
    }
}
