//
//  JikanMediaDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

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
