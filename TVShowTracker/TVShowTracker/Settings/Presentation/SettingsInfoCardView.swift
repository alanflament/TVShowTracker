//
//  SettingsInfoCardView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsInfoCardView: View {
    let title: String
    let description: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.07), in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.04), in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
