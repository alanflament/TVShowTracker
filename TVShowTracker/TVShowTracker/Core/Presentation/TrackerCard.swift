//
//  TrackerCard.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import SwiftUI

struct TrackerCard<Content: View>: View {
    let cornerRadius: CGFloat
    let opacity: Double
    let contentPadding: CGFloat
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.06,
        contentPadding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background(Color.primary.opacity(opacity), in: .rect(cornerRadius: cornerRadius))
    }
}
