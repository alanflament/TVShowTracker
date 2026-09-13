//
//  TVTimeSearchCandidateMatcher.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TVTimeSearchCandidateMatcher {
    func match(_ show: TVTimeShow, in catalog: SearchCatalog) -> MediaCandidate? {
        let tvShowMatches = exactMatches(in: catalog.tvShows, for: show)
        if tvShowMatches.count == 1 {
            return tvShowMatches[0]
        }

        let animeMatches = exactMatches(in: catalog.anime, for: show)
        guard animeMatches.count == 1 else {
            return nil
        }

        return animeMatches[0]
    }

    private func normalized(_ title: String) -> String {
        TVTimeShow(title: title).normalizedTitle
    }

    private func exactMatches(in candidates: [MediaCandidate], for show: TVTimeShow) -> [MediaCandidate] {
        candidates.filter { candidate in
            normalized(candidate.title) == show.normalizedTitle
                || candidate.alternateTitle.map(normalized) == show.normalizedTitle
        }
    }
}
