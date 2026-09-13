//
//  HTTPClientJSONTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct HTTPClientJSONTests {
    @Test func rejectsUnsuccessfulResponseBeforeDecoding() async {
        let client = HTTPClientStub(data: Data("not JSON".utf8), statusCode: 429)
        do {
            let _: [Int] = try await client.get(baseURL: "https://example.com", path: "/test")
            Issue.record("Expected HTTP failure")
        } catch let HTTPClientError.unacceptableStatusCode(statusCode) {
            #expect(statusCode == 429)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
