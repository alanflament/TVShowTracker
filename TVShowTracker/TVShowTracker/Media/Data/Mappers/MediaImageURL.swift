//
//  MediaImageURL.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

enum MediaImageURL {
    static func fullScreen(_ posterURL: URL?) -> URL? {
        guard
            let posterURL,
            posterURL.host() == "image.tmdb.org",
            var components = URLComponents(url: posterURL, resolvingAgainstBaseURL: false)
        else {
            return posterURL
        }

        var pathComponents = components.path.split(separator: "/").map(String.init)
        guard let sizeIndex = pathComponents.firstIndex(where: isTMDBImageSize) else {
            return posterURL
        }
        pathComponents[sizeIndex] = "w780"
        components.path = "/" + pathComponents.joined(separator: "/")
        return components.url ?? posterURL
    }

    private static func isTMDBImageSize(_ component: String) -> Bool {
        component == "original" || (
            component.first == "w" && component.dropFirst().allSatisfy(\.isNumber)
        )
    }
}
