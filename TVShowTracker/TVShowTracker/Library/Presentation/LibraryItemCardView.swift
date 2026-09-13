//
//  LibraryItemCardView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct LibraryItemCardView: View {
    let item: LibraryItem

    var body: some View {
        GeometryReader { proxy in
            MediaPosterView(
                url: item.posterURL,
                kind: item.kind,
                width: proxy.size.width,
                height: proxy.size.height,
                cornerRadius: 0
            )
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.black.opacity(0.86), .black.opacity(0.22), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: min(proxy.size.height * 0.36, 68))
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                Label(item.trackingStatus.title, systemImage: item.trackingStatus.systemImage)
                    .font(.caption2.weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, y: 1)
                    .padding(8)
            }
        }
        .aspectRatio(2 / 3, contentMode: .fit)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens show details")
    }

    private var accessibilityLabel: String {
        "\(item.title), \(item.trackingStatus.title)"
    }
}
