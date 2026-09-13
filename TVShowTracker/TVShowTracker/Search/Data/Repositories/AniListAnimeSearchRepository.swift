//
//  AniListAnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

struct AniListAnimeSearchRepository: AnimeSearchRepository {
    private let apiClient: AniListAPIClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        apiClient = AniListAPIClient(httpClient: httpClient)
    }

    func searchAnime(matching query: String) async throws -> [MediaCandidate] {
        let response: AniListData = try await apiClient.query(
            AniListSearchQuery.document,
            variables: ["search": query]
        )
        return AniListSearchMapping.groupedCandidates(from: response.page.media)
    }
}
