//
//  SearchCatalogUseCaseProbe.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

actor SearchCatalogUseCaseProbe: SearchCatalogUseCase {
    private let results: [SearchCatalog]
    private let suspendedRequestIndex: Int?
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var requests = [String]()

    init(results: [SearchCatalog], suspendedRequestIndex: Int? = nil) {
        self.results = results
        self.suspendedRequestIndex = suspendedRequestIndex
    }

    var isSuspended: Bool {
        continuation != nil
    }

    func search(matching query: String) async -> SearchCatalog {
        let requestIndex = requests.count
        requests.append(query)

        if requestIndex == suspendedRequestIndex {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }

        return results[requestIndex]
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
