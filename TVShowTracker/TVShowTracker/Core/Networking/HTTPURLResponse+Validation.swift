//
//  HTTPURLResponse+Validation.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension HTTPURLResponse {
    func validateSuccessfulStatusCode() throws {
        guard (200 ... 299).contains(statusCode) else {
            throw HTTPClientError.unacceptableStatusCode(statusCode)
        }
    }
}
