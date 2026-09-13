//
//  EpisodeDurationHTTPClientStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct EpisodeDurationHTTPClientStub: HTTPClient {
    let data: Data

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: 200,
                  httpVersion: nil,
                  headerFields: nil
              )
        else {
            throw EpisodeDurationTestError.invalidRequest
        }
        return (data, response)
    }
}
