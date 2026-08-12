//
//  MediaPoster.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import SwiftUI

struct MediaPoster: View {
    let url: URL?
    let kind: SearchMediaKind
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(
        url: URL?,
        kind: SearchMediaKind,
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = 12
    ) {
        self.url = url
        self.kind = kind
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: kind == .anime ? "sparkles.tv" : "tv")
                        .foregroundStyle(.secondary)
                }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .clipped()
        .clipShape(.rect(cornerRadius: cornerRadius))
        .id(url)
        .accessibilityHidden(true)
    }
}
