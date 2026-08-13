//
//  MediaPoster.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import SwiftUI
import UIKit

struct MediaPoster: View {
    @State private var image: UIImage?

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
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .clipped()
        .clipShape(.rect(cornerRadius: cornerRadius))
        .task(id: url) {
            await loadImage()
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                Image(systemName: kind == .anime ? "sparkles.tv" : "tv")
                    .foregroundStyle(.secondary)
            }
    }

    private func loadImage() async {
        image = nil

        guard let url else {
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let downloadedImage = UIImage(data: data)
            else {
                return
            }

            image = downloadedImage
        } catch {
            // Keep the placeholder visible when a poster cannot be downloaded.
        }
    }
}
