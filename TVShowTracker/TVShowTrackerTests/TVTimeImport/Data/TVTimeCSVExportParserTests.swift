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

    @Test func mergesSeenEpisodeFilesAndKeepsTheLatestDuplicate() throws {
        let rootURL = try makeExportFolderWithSplitSeenEpisodes()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let export = try TVTimeCSVExportParser().parseExport(at: rootURL)

        #expect(export.watchedEpisodes.map(\.episodeNumber) == [1, 2, 3, 4])
        #expect(export.watchedEpisodes.first { $0.episodeNumber == 2 }?.watchedAt == date(
            "2026-01-03 00:00:00"
        ))
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

private func makeExportFolderWithSplitSeenEpisodes() throws -> URL {
    let rootURL = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

    try "archived,tv_show_name\n0,Example Show\n".write(
        to: rootURL.appending(path: "followed_tv_show.csv"),
        atomically: true,
        encoding: .utf8
    )
    try seenEpisodeCSV(episode: 1, updatedAt: "2026-01-01 00:00:00").write(
        to: rootURL.appending(path: "seen_episode_source.csv"),
        atomically: true,
        encoding: .utf8
    )
    try seenEpisodeCSV(episode: 2, updatedAt: "2026-01-02 00:00:00").write(
        to: rootURL.appending(path: "seen_episode.csv"),
        atomically: true,
        encoding: .utf8
    )
    try seenEpisodeCSV(episode: 2, updatedAt: "2026-01-03 00:00:00").write(
        to: rootURL.appending(path: "seen_episode_unitarian.csv"),
        atomically: true,
        encoding: .utf8
    )
    try seenEpisodeCSV(episode: 3, updatedAt: "2026-01-04 00:00:00").write(
        to: rootURL.appending(path: "seen_episode_latest.csv"),
        atomically: true,
        encoding: .utf8
    )
    try seenEpisodeCSV(episode: 4, updatedAt: "2026-01-05 00:00:00").write(
        to: rootURL.appending(path: "rewatched_episode.csv"),
        atomically: true,
        encoding: .utf8
    )
    return rootURL
}

private func seenEpisodeCSV(episode: Int, updatedAt: String) -> String {
    "updated_at,tv_show_name,episode_season_number,episode_number,episode_id\n"
        + "\(updatedAt),Example Show,1,\(episode),\(episode)\n"
}

private func date(_ value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.date(from: value)
}
