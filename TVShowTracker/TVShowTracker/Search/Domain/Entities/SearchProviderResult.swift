//
//  SearchProviderResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

nonisolated struct SearchProviderResult: Sendable {
    let candidates: [MediaCandidate]
    let unavailableProviders: Set<MediaProvider>
    let providerErrors: [MediaProvider: String]

    init(
        candidates: [MediaCandidate] = [],
        unavailableProviders: Set<MediaProvider> = [],
        providerErrors: [MediaProvider: String] = [:]
    ) {
        self.candidates = candidates
        self.unavailableProviders = unavailableProviders
        self.providerErrors = providerErrors
    }
}
