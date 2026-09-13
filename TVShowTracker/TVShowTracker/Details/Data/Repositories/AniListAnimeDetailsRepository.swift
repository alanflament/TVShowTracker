//
//  AniListAnimeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct AniListAnimeDetailsRepository: AnimeDetailsRepository {
    private let apiClient: AniListAPIClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        apiClient = AniListAPIClient(httpClient: httpClient)
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        let id = try await aniListID(for: candidate)
        let details = try await request(id: id, query: AniListDetailsQuery.detailsQuery)
        let installments = mergedInstallments(from: details, existing: candidate.animeInstallments)
        let latestInstallment = installments.last

        return ShowDetails(
            provider: candidate.provider,
            providerID: candidate.providerID,
            kind: .anime,
            title: details.title.preferredTitle,
            alternateTitle: details.title.alternateTitle,
            overview: details.description,
            posterURL: details.coverImage.large ?? details.coverImage.medium,
            backdropURL: nil,
            releaseYear: details.startDate.year,
            status: latestInstallment?.status ?? MediaStatus(anilistStatus: details.status),
            totalEpisodeCount: installments.isEmpty
                ? nil
                : installments.compactMap(\.episodeCount).reduce(0, +),
            genres: details.genres,
            seasonSummaries: installments.enumerated().map { index, installment in
                SeasonSummary(
                    provider: .aniList,
                    showID: installment.providerID,
                    number: index + 1,
                    name: installment.title,
                    episodeCount: installment.episodeCount ?? 0,
                    airDate: nil
                )
            },
            animeInstallments: installments
        )
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
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
            let anime = try await request(id: installment.providerID, query: AniListDetailsQuery.episodesQuery)
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
                releaseDatePrecision: airingDates[number] == nil ? .day : .time,
                stillURL: nil,
                runtimeMinutes: anime.duration
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
    func mergedInstallments(
        from details: AniListDetailsAnime,
        existing: [AnimeInstallmentReference]
    ) -> [AnimeInstallmentReference] {
        let root = AniListDetailsInstallment(
            id: details.id,
            title: details.title,
            format: details.format,
            status: details.status,
            episodes: details.episodes,
            startDate: details.startDate,
            relations: details.relations
        )
        var installments = Dictionary(uniqueKeysWithValues: existing.map { ($0.providerID, $0) })

        func ingest(_ installment: AniListDetailsInstallment) {
            guard installment.isSeasonInstallment else {
                return
            }
            installments[installment.id] = installment.installmentReference
            for relation in installment.relations?.edges ?? [] where relation.connectsSeasons {
                ingest(relation.node)
            }
        }

        ingest(root)
        return installments.values.sorted { lhs, rhs in
            let lhsDate = (lhs.releaseYear ?? .max, lhs.releaseMonth ?? .max, lhs.releaseDay ?? .max)
            let rhsDate = (rhs.releaseYear ?? .max, rhs.releaseMonth ?? .max, rhs.releaseDay ?? .max)
            return lhsDate == rhsDate ? lhs.providerID < rhs.providerID : lhsDate < rhsDate
        }
    }

    func aniListID(for candidate: MediaCandidate) async throws -> Int {
        switch candidate.provider {
        case .aniList:
            return candidate.providerID
        case .jikan:
            let result: AniListDetailsData = try await apiClient.query(
                AniListDetailsQuery.malIDQuery,
                variables: ["idMal": candidate.providerID]
            )
            guard let id = result.media?.id else {
                throw AniListAPIError.queryFailed("Anime details were not found.")
            }
            return id
        case .tmdb:
            throw AniListAPIError.queryFailed("This result is not an anime.")
        }
    }

    func request(id: Int, query: String) async throws -> AniListDetailsAnime {
        let response: AniListDetailsData = try await apiClient.query(query, variables: ["id": id])
        guard let anime = response.media else {
            throw AniListAPIError.queryFailed("Anime details were not found.")
        }
        return anime
    }
}
