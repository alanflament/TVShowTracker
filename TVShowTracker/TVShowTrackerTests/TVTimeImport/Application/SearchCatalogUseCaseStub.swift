//
//  SearchCatalogUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct SearchCatalogUseCaseStub: SearchCatalogUseCase {
    let candidate: MediaCandidate

    func search(matching _: String) async -> SearchCatalog {
        SearchCatalog(
            tvShows: [candidate],
            anime: [],
            unavailableProviders: [],
            providerErrors: [:]
        )
    }
}
