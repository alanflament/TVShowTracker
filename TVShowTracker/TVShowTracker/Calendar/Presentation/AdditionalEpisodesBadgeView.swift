//
//  AdditionalEpisodesBadgeView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftUI

struct AdditionalEpisodesBadgeView: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.14), in: .capsule)
            .accessibilityLabel("\(count) more \(count == 1 ? "episode" : "episodes") available")
    }
}
