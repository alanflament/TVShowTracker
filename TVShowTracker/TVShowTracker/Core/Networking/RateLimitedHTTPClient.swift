//
//  RateLimitedHTTPClient.swift
//  TVShowTracker
//
//  Created by Alan Flament on 16/08/2026.
//

import Foundation

actor RateLimitedHTTPClient: HTTPClient {
    private let httpClient: any HTTPClient
    private let minimumInterval: TimeInterval
    private var nextRequestDate = Date.distantPast

    init(httpClient: any HTTPClient, minimumInterval: TimeInterval) {
        self.httpClient = httpClient
        self.minimumInterval = minimumInterval
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await waitForRequestTurn()
        let result = try await httpClient.data(for: request)
        if result.1.statusCode == 429 {
            deferRequests(using: result.1)
        }
        return result
    }
}

private extension RateLimitedHTTPClient {
    func waitForRequestTurn() async throws {
        while true {
            try Task.checkCancellation()
            let now = Date.now
            let delay = nextRequestDate.timeIntervalSince(now)
            guard delay > 0 else {
                nextRequestDate = now.addingTimeInterval(minimumInterval)
                return
            }

            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    func deferRequests(using response: HTTPURLResponse) {
        guard let retryAfterValue = response.value(forHTTPHeaderField: "Retry-After"),
              let retryAfter = TimeInterval(retryAfterValue)
        else {
            return
        }

        nextRequestDate = max(nextRequestDate, Date.now.addingTimeInterval(retryAfter))
    }
}
