//
//  SettingsView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct SettingsView: View {
    private let makeTVTimeImportViewModel: () -> TVTimeImportViewModel

    init(makeTVTimeImportViewModel: @escaping () -> TVTimeImportViewModel) {
        self.makeTVTimeImportViewModel = makeTVTimeImportViewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your data")
                            .font(.title2.bold())
                        Text("Manage the media and progress you bring into TVShowTracker.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        TVTimeImportView(viewModel: makeTVTimeImportViewModel())
                    } label: {
                        SettingsActionCard(
                            title: "Import TV Time data",
                            subtitle: "Bring in followed shows and watched episodes",
                            systemImage: "square.and.arrow.down"
                        )
                    }
                    .buttonStyle(.plain)

                    SettingsInfoCard(
                        title: "Kept on this device",
                        description: "Your followed shows, saved schedules, and watched progress are stored locally so your library remains available offline.",
                        systemImage: "lock.fill"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Settings")
        }
    }
}

private struct SettingsInfoCard: View {
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

private struct SettingsActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        TrackerCard {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 42, height: 42)
                    .background(Color.accentColor.opacity(0.14), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
