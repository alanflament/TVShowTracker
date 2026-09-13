//
//  CollapsibleEpisodeListView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct CollapsibleEpisodeListView<Content: View>: View {
    let isExpanded: Bool
    let content: Content
    @State private var contentHeight: CGFloat = 0

    init(isExpanded: Bool, @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { newHeight in
                contentHeight = newHeight
            }
            .offset(y: isExpanded ? 0 : -14)
            .frame(height: isExpanded ? contentHeight : 0, alignment: .top)
            .clipped()
            .allowsHitTesting(isExpanded)
            .accessibilityHidden(!isExpanded)
    }
}
