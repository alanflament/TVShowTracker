//
//  JikanImage.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanImage: Decodable {
    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case largeImageURL = "large_image_url"
    }

    let imageURL: URL?
    let largeImageURL: URL?
}
