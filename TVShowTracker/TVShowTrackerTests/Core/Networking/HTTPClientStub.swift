//
//  HTTPClientStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

actor HTTPClientStub: HTTPClient {
    let data: Data
    let statusCode: Int
    private(set) var requests = [URLRequest]()

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: statusCode,
                  httpVersion: nil,
                  headerFields: nil
              )
        else {
            throw TestError.expectedFailure
        }
        return (data, response)
    }
}

private enum TestError: Error {
    case expectedFailure
}
