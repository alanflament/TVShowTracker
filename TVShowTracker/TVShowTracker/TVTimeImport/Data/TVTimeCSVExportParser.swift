//
//  TVTimeCSVExportParser.swift
//  TVShowTracker
//

import Foundation

struct TVTimeCSVExportParser: TVTimeExportParsing {
    func parseExport(at folderURL: URL) throws -> TVTimeExport {
        guard let exportFolderURL = exportFolderURL(in: folderURL) else {
            throw TVTimeExportParserError.missingFollowedShowsFile
        }
        let followedShowsURL = exportFolderURL.appending(path: "followed_tv_show.csv")

        let followedShows = try TVTimeCSVDocument(contentsOf: followedShowsURL).rows.compactMap { row in
            row["tv_show_name"].flatMap { makeShow($0) }
        }

        var watchedEpisodes = [String: TVTimeWatchedEpisode]()
        for filename in episodeSourceFilenames {
            let fileURL = exportFolderURL.appending(path: filename)
            guard FileManager.default.fileExists(atPath: fileURL.path()) else {
                continue
            }

            let rows = try TVTimeCSVDocument(contentsOf: fileURL).rows
            for row in rows {
                guard let episode = makeEpisode(from: row, in: filename) else {
                    continue
                }

                let key = "\(episode.normalizedShowTitle):\(episode.seasonNumber):\(episode.episodeNumber)"
                if let existing = watchedEpisodes[key] {
                    watchedEpisodes[key] = latestEpisode(between: existing, and: episode)
                } else {
                    watchedEpisodes[key] = episode
                }
            }
        }

        return TVTimeExport(
            followedShows: Array(Set(followedShows)),
            watchedEpisodes: Array(watchedEpisodes.values)
        )
    }
}

private extension TVTimeCSVExportParser {
    func exportFolderURL(in selectedFolderURL: URL) -> URL? {
        let directFileURL = selectedFolderURL.appending(path: "followed_tv_show.csv")
        if FileManager.default.fileExists(atPath: directFileURL.path()) {
            return selectedFolderURL
        }

        guard let enumerator = FileManager.default.enumerator(
            at: selectedFolderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == "followed_tv_show.csv" {
            return fileURL.deletingLastPathComponent()
        }

        return nil
    }

    var episodeSourceFilenames: [String] {
        [
            "seen_episode_source.csv",
            "rewatched_episode.csv",
            "seen_episode.csv",
            "seen_episode_unitarian.csv",
            "seen_episode_latest.csv"
        ]
    }

    func makeShow(_ title: String) -> TVTimeShow? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? nil : TVTimeShow(title: trimmedTitle)
    }

    func makeEpisode(
        title: String?,
        seasonNumber: String?,
        episodeNumber: String?,
        watchedAt: String?
    ) -> TVTimeWatchedEpisode? {
        guard let show = title.flatMap({ makeShow($0) }),
              let seasonValue = seasonNumber.flatMap(Int.init),
              let episodeValue = episodeNumber.flatMap(Int.init)
        else {
            return nil
        }

        return TVTimeWatchedEpisode(
            showTitle: show.title,
            seasonNumber: seasonValue,
            episodeNumber: episodeValue,
            watchedAt: watchedAt.flatMap { date(from: $0) }
        )
    }

    func makeEpisode(from row: [String: String], in _: String) -> TVTimeWatchedEpisode? {
        makeEpisode(
            title: row["tv_show_name"],
            seasonNumber: row["episode_season_number"],
            episodeNumber: row["episode_number"],
            watchedAt: row["updated_at"]
        )
    }

    func latestEpisode(
        between lhs: TVTimeWatchedEpisode,
        and rhs: TVTimeWatchedEpisode
    ) -> TVTimeWatchedEpisode {
        guard let lhsDate = lhs.watchedAt else {
            return rhs
        }
        guard let rhsDate = rhs.watchedAt else {
            return lhs
        }
        return lhsDate >= rhsDate ? lhs : rhs
    }

    func date(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: value)
    }
}
