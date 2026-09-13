//
//  UpNextSummaryView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftUI

struct UpNextSummaryView: View {
    let availableEpisodeCount: Int
    let undatedMediaCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summaryTitle)
                .font(.title.bold())
            Text(summaryDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryTitle: String {
        switch availableEpisodeCount {
        case 0:
            "Your upcoming episodes"
        case 1:
            "One episode is ready"
        default:
            "\(availableEpisodeCount) episodes are ready"
        }
    }

    private var summaryDescription: String {
        if availableEpisodeCount > 0 {
            return "Pick up where you left off."
        }
        if undatedMediaCount > 0 {
            return "Some of your shows have not announced their next episode yet."
        }
        return "Keep an eye on what is coming next."
    }
}
