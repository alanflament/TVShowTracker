//
//  SearchResultsLoadingIndicatorModifier.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct SearchResultsLoadingIndicatorModifier: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isVisible {
                    SearchResultsLoadingIndicatorView()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}
