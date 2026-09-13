//
//  CalendarUndatedMediaCardView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftUI

struct CalendarUndatedMediaCardView: View {
    let item: CalendarUndatedMedia
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            MediaPosterView(url: item.posterURL, kind: item.candidate.kind, width: 56, height: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.showTitle)
                    .font(.headline)
                Label("Next episode to be announced", systemImage: "calendar.badge.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens show details")
    }
}
