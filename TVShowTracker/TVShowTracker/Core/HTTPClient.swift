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
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.nonHTTPResponse
        }

        return (data, httpResponse)
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
