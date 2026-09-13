//
//  HTTPClientError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

enum HTTPClientError: LocalizedError, Sendable {
    case nonHTTPResponse
    case unacceptableStatusCode(Int)
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            "The server returned an invalid response."
        case let .unacceptableStatusCode(statusCode):
            if statusCode == 429 {
                "The provider rate limit was reached. Try again later."
            } else {
                "The server returned HTTP status \(statusCode)."
            }
        case .invalidRequest:
            "The request could not be created."
        }
    }
}
