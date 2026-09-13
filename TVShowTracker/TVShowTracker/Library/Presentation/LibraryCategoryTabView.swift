//
//  LibraryCategoryTabView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct LibraryCategoryTabView: View {
    let category: LibraryCategory
    let count: Int
    let isSelected: Bool
    let selectionNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(count, format: .number)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.16))
                        .matchedGeometryEffect(
                            id: "library-category-selection",
                            in: selectionNamespace
                        )
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.title), \(count) \(count == 1 ? "show" : "shows")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
