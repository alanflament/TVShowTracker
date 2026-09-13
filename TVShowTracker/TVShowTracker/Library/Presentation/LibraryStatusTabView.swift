//
//  LibraryStatusTabView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct LibraryStatusTabView: View {
    let filter: LibraryFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(filter.title)
                    .foregroundStyle(.primary)
                Text(count, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(
                .regular
                    .tint(isSelected ? Color.accentColor.opacity(0.14) : nil)
                    .interactive(),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(filter.title), \(count) \(count == 1 ? "show" : "shows")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
