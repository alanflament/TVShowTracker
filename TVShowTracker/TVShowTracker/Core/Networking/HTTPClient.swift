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
