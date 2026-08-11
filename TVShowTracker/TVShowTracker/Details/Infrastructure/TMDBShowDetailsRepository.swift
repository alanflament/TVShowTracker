//
//  TMDBShowDetailsRepository.swift
//  TVShowTracker
//

import Foundation

struct TMDBShowDetailsRepository: TVShowDetailsRepository {
    private let accessToken: String
    private let language: String
    private let httpClient: any HTTPClient

    init(
        accessToken: String,
        language: String,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        self.accessToken = accessToken
        self.language = language
        self.httpClient = httpClient
    }

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        let details: TMDBShowDetails = try await request(path: "/3/tv/\(candidate.providerID)")
        return details.asDomain
    }

    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason] {
        let details: TMDBShowDetails = try await request(path: "/3/tv/\(candidate.providerID)")

        return try await withThrowingTaskGroup(of: ShowSeason.self, returning: [ShowSeason].self) { group in
            for season in details.seasons where season.seasonNumber >= 0 {
                group.addTask {
                    let seasonDetails: TMDBSeasonDetails = try await request(
                        path: "/3/tv/\(candidate.providerID)/season/\(season.seasonNumber)"
                    )
                    return seasonDetails.asDomain(
                        provider: .tmdb,
                        showID: candidate.providerID
                    )
                }
            }

            var seasons = [ShowSeason]()
            for try await season in group {
                seasons.append(season)
            }
            return seasons.sorted { $0.number < $1.number }
        }
    }
}

private extension TMDBShowDetailsRepository {
    func request<Response: Decodable>(path: String) async throws -> Response {
        var components = URLComponents(string: "https://api.themoviedb.org")
        components?.path = path
        components?.queryItems = [URLQueryItem(name: "language", value: language)]

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await httpClient.data(for: request)
        try response.validateSuccessfulStatusCode()
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct TMDBShowDetails: Decodable {
    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let status: String?
    let numberOfEpisodes: Int?
    let genres: [TMDBGenre]
    let seasons: [TMDBSeasonSummary]

    enum CodingKeys: String, CodingKey {
        case id, name, overview, status, genres, seasons
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfEpisodes = "number_of_episodes"
    }

    var asDomain: ShowDetails {
        ShowDetails(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: name,
            alternateTitle: originalName,
            overview: overview,
            posterURL: imageURL(path: posterPath, size: "w500"),
            backdropURL: imageURL(path: backdropPath, size: "w1280"),
            releaseYear: DateParser.parseYear(firstAirDate),
            status: SearchMediaStatus(tmdbStatus: status),
            totalEpisodeCount: numberOfEpisodes,
            genres: genres.map(\.name),
            seasonSummaries: seasons.map { $0.asDomain(provider: .tmdb, showID: id) }
        )
    }
}

private struct TMDBGenre: Decodable {
    let name: String
}

private struct TMDBSeasonSummary: Decodable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let airDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case airDate = "air_date"
    }

    func asDomain(provider: SearchProvider, showID: Int) -> SeasonSummary {
        SeasonSummary(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodeCount: episodeCount,
            airDate: DateParser.parseISO8601(airDate)
        )
    }
}

private nonisolated struct TMDBSeasonDetails: Decodable {
    let seasonNumber: Int
    let name: String
    let episodes: [TMDBEpisode]

    enum CodingKeys: String, CodingKey {
        case name, episodes
        case seasonNumber = "season_number"
    }

    nonisolated func asDomain(provider: SearchProvider, showID: Int) -> ShowSeason {
        ShowSeason(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodes: episodes.map { $0.asDomain(provider: provider, showID: showID, seasonNumber: seasonNumber) }
        )
    }
}

private nonisolated struct TMDBEpisode: Decodable {
    let episodeNumber: Int
    let name: String
    let overview: String?
    let airDate: String?
    let stillPath: String?
    let runtime: Int?

    enum CodingKeys: String, CodingKey {
        case name, overview, runtime
        case episodeNumber = "episode_number"
        case airDate = "air_date"
        case stillPath = "still_path"
    }

    func asDomain(provider: SearchProvider, showID: Int, seasonNumber: Int) -> ShowEpisode {
        ShowEpisode(
            provider: provider,
            showID: showID,
            seasonNumber: seasonNumber,
            number: episodeNumber,
            title: name,
            overview: overview,
            airDate: DateParser.parseISO8601(airDate),
            stillURL: imageURL(path: stillPath, size: "w300"),
            runtimeMinutes: runtime
        )
    }
}

private nonisolated func imageURL(path: String?, size: String) -> URL? {
    path.flatMap { URL(string: "https://image.tmdb.org/t/p/\(size)\($0)") }
}

private extension SearchMediaStatus {
    init?(tmdbStatus: String?) {
        switch tmdbStatus {
        case "Returning Series", "In Production":
            self = .airing
        case "Ended", "Canceled":
            self = .finished
        case "Planned", "Pilot":
            self = .upcoming
        default:
            return nil
        }
    }
}
