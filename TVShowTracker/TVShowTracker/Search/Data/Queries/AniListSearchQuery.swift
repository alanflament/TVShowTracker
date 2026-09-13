//
//  AniListSearchQuery.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

enum AniListSearchQuery {
    static let document = """
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
          format
          status
          episodes
          startDate {
            year
            month
            day
          }
          nextAiringEpisode {
            episode
            airingAt
          }
          relations {
            edges {
              relationType
              node {
                id
                title { userPreferred english romaji native }
                coverImage { large medium }
                format
                status
                episodes
                startDate { year month day }
                nextAiringEpisode { episode airingAt }
                relations {
                  edges {
                    relationType
                    node {
                      id
                      title { userPreferred english romaji native }
                      coverImage { large medium }
                      format
                      status
                      episodes
                      startDate { year month day }
                      nextAiringEpisode { episode airingAt }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    """
}
