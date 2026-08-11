//
//  HTTPClient.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var request = request
        if request.value(forHTTPHeaderField: "User-Agent") == nil {
            request.setValue("TVShowTracker/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        }

        for attempt in 0 ..< 3 {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.nonHTTPResponse
            }

            if !(500 ... 599).contains(httpResponse.statusCode) || attempt == 2 {
                return (data, httpResponse)
            }

            try await Task.sleep(nanoseconds: 250_000_000)
        }

        throw HTTPClientError.nonHTTPResponse
    }
}

enum HTTPClientError: LocalizedError, Sendable {
    case nonHTTPResponse
    case unacceptableStatusCode(Int)
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            "The server returned an invalid response."
        case let .unacceptableStatusCode(statusCode):
            "The server returned HTTP status \(statusCode)."
        case .invalidRequest:
            "The request could not be created."
        }
    }
}

extension HTTPURLResponse {
    func validateSuccessfulStatusCode() throws {
        guard (200 ... 299).contains(statusCode) else {
            throw HTTPClientError.unacceptableStatusCode(statusCode)
        }
    }
}
