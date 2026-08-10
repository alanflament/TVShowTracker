//
//  AniListAnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

struct AniListAnimeSearchRepository: AnimeSearchRepository {
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func searchAnime(matching query: String) async throws -> [SearchCandidate] {
        let requestBody = GraphQLRequest(
            query: Self.searchQuery,
            variables: ["search": query]
        )

        var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await httpClient.data(for: request)

        if let graphQLResponse = try? JSONDecoder().decode(AniListGraphQLResponse.self, from: data),
           let message = graphQLResponse.errors?.first?.message
        {
            throw AniListAPIError.queryFailed(message)
        }

        try response.validateSuccessfulStatusCode()

        let graphQLResponse = try JSONDecoder().decode(AniListGraphQLResponse.self, from: data)

        guard let page = graphQLResponse.data?.page else {
            throw AniListAPIError.queryFailed(graphQLResponse.errors?.first?.message ?? "Unknown error")
        }

        return page.media.map(SearchCandidate.init(_:))
    }
}

private extension AniListAnimeSearchRepository {
    static let searchQuery = """
    query SearchAnime($search: String!) {
      Page(page: 1, perPage: 20) {
        media(search: $search, type: ANIME, isAdult: false) {
          id
          title {
            userPreferred
            english
            romaji
            native
          }
          coverImage {
            large
            medium
          }
          status
          episodes
          startDate {
            year
          }
          nextAiringEpisode {
            episode
            airingAt
          }
        }
      }
    }
    """
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: String]
}

private struct AniListGraphQLResponse: Decodable {
    let data: AniListData?
    let errors: [AniListGraphQLError]?
}
