//
//  AniListAPIClientTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct AniListAPIClientTests {
    @Test func sendsGraphQLVariablesAndJSONHeaders() async throws {
        let httpClient = HTTPClientStub(data: Data(#"{"data":{"value":42}}"#.utf8), statusCode: 200)
        let client = AniListAPIClient(httpClient: httpClient)

        let result: Payload = try await client.query("query Test", variables: ["id": 7])

        #expect(result.value == 42)
        let request = try #require(await httpClient.requests.first)
        #expect(request.url?.absoluteString == "https://graphql.anilist.co")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let data = try #require(request.httpBody)
        let body = try JSONDecoder().decode(RequestBody.self, from: data)
        #expect(body.query == "query Test")
        #expect(body.variables == ["id": 7])
    }

    @Test(arguments: [200, 400])
    func surfacesGraphQLErrorsRegardlessOfHTTPStatus(statusCode: Int) async {
        let client = AniListAPIClient(httpClient: HTTPClientStub(
            data: Data(#"{"data":null,"errors":[{"message":"Query rejected"}]}"#.utf8),
            statusCode: statusCode
        ))
        do {
            let _: Payload = try await client.query("query Test", variables: ["id": 7])
            Issue.record("Expected GraphQL failure")
        } catch let AniListAPIError.queryFailed(message) {
            #expect(message == "Query rejected")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func rejectsHTTPFailureBeforeDecodingPayload() async {
        let client = AniListAPIClient(httpClient: HTTPClientStub(data: Data(), statusCode: 503))
        do {
            let _: Payload = try await client.query("query Test", variables: ["id": 7])
            Issue.record("Expected HTTP failure")
        } catch let HTTPClientError.unacceptableStatusCode(statusCode) {
            #expect(statusCode == 503)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private struct Payload: Decodable {
    let value: Int
}

private struct RequestBody: Decodable {
    let query: String
    let variables: [String: Int]
}
