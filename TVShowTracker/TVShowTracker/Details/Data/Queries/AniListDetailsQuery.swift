//
//  AniListDetailsQuery.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

enum AniListDetailsQuery {
    static let detailsQuery = """
    query AnimeDetails($id: Int!) {
      Media(id: $id, type: ANIME) {
        id
        title { userPreferred english romaji native }
        description(asHtml: false)
        coverImage { large medium }
        status
        episodes
        duration
        startDate { year }
        genres
        format
        relations {
          edges {
            relationType
            node {
              id
              title { userPreferred english romaji native }
              format
              status
              episodes
              startDate { year month day }
              relations {
                edges {
                  relationType
                  node {
                    id
                    title { userPreferred english romaji native }
                    format
                    status
                    episodes
                    startDate { year month day }
                  }
                }
              }
            }
          }
        }
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
        duration
        startDate { year }
        genres
        airingSchedule(perPage: 100) {
          nodes { episode airingAt }
        }
      }
    }
    """
}
