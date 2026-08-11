//
//  SearchProviderResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct SearchProviderResult: Sendable {
    let candidates: [SearchCandidate]
    let unavailableProviders: Set<SearchProvider>
    let providerErrors: [SearchProvider: String]

    init(
        candidates: [SearchCandidate] = [],
        unavailableProviders: Set<SearchProvider> = [],
        providerErrors: [SearchProvider: String] = [:]
    ) {
        self.candidates = candidates
        self.unavailableProviders = unavailableProviders
        self.providerErrors = providerErrors
    }
}
