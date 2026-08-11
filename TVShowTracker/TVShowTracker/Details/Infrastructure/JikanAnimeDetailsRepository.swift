//
//  JikanAnimeDetailsRepository.swift
//  TVShowTracker
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
            URLQueryItem(name: "sfw", value: "true"),
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

private struct JikanSearchEnvelope: Decodable {
    let data: [JikanSearchAnime]
}

private struct JikanSearchAnime: Decodable {
    let id: Int
    let title: String
    let titleEnglish: String?

    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
    }
}

private struct JikanEnvelope<Response: Decodable>: Decodable {
    let data: Response
}

private struct JikanDetailsAnime: Decodable {
    let id: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let images: JikanImages
    let episodes: Int?
    let status: String?
    let aired: JikanAired
    let genres: [JikanNamedResource]

    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case synopsis, images, episodes, status, aired, genres
    }

    var asDomain: ShowDetails {
        ShowDetails(
            provider: .jikan,
            providerID: id,
            kind: .anime,
            title: titleEnglish ?? title,
            alternateTitle: titleJapanese,
            overview: synopsis,
            posterURL: images.jpg.largeImageURL ?? images.jpg.imageURL,
            backdropURL: nil,
            releaseYear: aired.from.flatMap { Int($0.prefix(4)) },
            status: SearchMediaStatus(jikanStatus: status),
            totalEpisodeCount: episodes,
            genres: genres.map(\.name),
            seasonSummaries: episodes.map {
                [SeasonSummary(
                    provider: .jikan,
                    showID: id,
                    number: 1,
                    name: "Episodes",
                    episodeCount: $0,
                    airDate: nil
                )]
            } ?? []
        )
    }
}

private struct JikanNamedResource: Decodable {
    let name: String
}

private struct JikanEpisodePage: Decodable {
    let data: [JikanEpisode]
    let pagination: JikanPagination
}

private struct JikanPagination: Decodable {
    let lastPage: Int

    enum CodingKeys: String, CodingKey {
        case lastPage = "last_visible_page"
    }
}

private struct JikanEpisode: Decodable {
    let number: Int
    let title: String?
    let aired: String?

    enum CodingKeys: String, CodingKey {
        case number = "mal_id"
        case title, aired
    }

    func asDomain(provider: SearchProvider, showID: Int) -> ShowEpisode {
        ShowEpisode(
            provider: provider,
            showID: showID,
            seasonNumber: 1,
            number: number,
            title: title ?? "Episode \(number)",
            overview: nil,
            airDate: DateParser.parseISO8601(aired),
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}
