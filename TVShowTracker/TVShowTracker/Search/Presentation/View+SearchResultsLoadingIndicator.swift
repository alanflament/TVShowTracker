//
//  View+SearchResultsLoadingIndicator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

extension View {
    func searchResultsLoadingIndicator(isVisible: Bool) -> some View {
        modifier(SearchResultsLoadingIndicatorModifier(isVisible: isVisible))
    }
}
