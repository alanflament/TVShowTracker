//
//  TVTimeCSVExportParserTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct TVTimeCSVExportParserTests {
    @Test func findsTheExportInsideAnEnclosingFolder() throws {
        let rootURL = try makeExportFolder()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let export = try TVTimeCSVExportParser().parseExport(at: rootURL)

        #expect(export.followedShows.map(\.title) == ["Example Show"])
        #expect(export.watchedEpisodes.map(\.showTitle) == ["Example Show"])
    }
}

private func makeExportFolder() throws -> URL {
    let rootURL = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let exportURL = rootURL.appending(path: "gdpr-data", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: exportURL, withIntermediateDirectories: true)

    try "archived,tv_show_name\n0,Example Show\n".write(
        to: exportURL.appending(path: "followed_tv_show.csv"),
        atomically: true,
        encoding: .utf8
    )
    try "updated_at,tv_show_name,episode_season_number,episode_number\n2026-01-01 00:00:00,Example Show,1,1\n".write(
        to: exportURL.appending(path: "seen_episode_source.csv"),
        atomically: true,
        encoding: .utf8
    )
    return rootURL
}
