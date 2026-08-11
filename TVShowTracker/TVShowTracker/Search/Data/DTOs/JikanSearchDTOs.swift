//
//  JikanSearchDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

import Foundation

struct JikanSearchResponse: Decodable {
    let data: [JikanAnime]
}

struct JikanAnime: Decodable {
    let id: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let titleSynonyms: [String]
    let images: JikanImages
    let episodes: Int?
    let status: String?
    let aired: JikanAired

    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case titleSynonyms = "title_synonyms"
        case images
        case episodes
        case status
        case aired
    }

    var preferredTitle: String {
        titleEnglish ?? title
    }

    var alternateTitle: String? {
        ([title, titleJapanese] + titleSynonyms)
            .compactMap { $0 }
            .first { $0 != preferredTitle }
    }

    var releaseYear: Int? {
        aired.from.flatMap { Int($0.prefix(4)) }
    }
}

struct JikanImages: Decodable {
    let jpg: JikanImage
}

struct JikanImage: Decodable {
    let imageURL: URL?
    let largeImageURL: URL?

    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case largeImageURL = "large_image_url"
    }
}

struct JikanAired: Decodable {
    let from: String?
}

extension SearchMediaStatus {
    init?(jikanStatus: String?) {
        switch jikanStatus {
        case "Currently Airing":
            self = .airing
        case "Finished Airing":
            self = .finished
        case "Not yet aired":
            self = .upcoming
        default:
            return nil
        }
    }
}
