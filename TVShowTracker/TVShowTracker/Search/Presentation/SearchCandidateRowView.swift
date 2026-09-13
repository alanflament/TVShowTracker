//
//  SearchCandidateRowView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct SearchCandidateRowView: View {
    let candidate: MediaCandidate
    let onSelect: () -> Void
    let onAddToPlan: () -> Void
    let onSetTrackingStatus: (TrackingStatus) -> Void
    let onRemoveFromLibrary: () -> Void
    let trackingStatus: () -> TrackingStatus?

    var body: some View {
        let trackingStatus = trackingStatus()

        HStack(alignment: .top, spacing: 12) {
            MediaPosterView(url: candidate.posterURL, kind: candidate.kind, width: 72, height: 108)

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.title)
                    .font(.headline)
                    .lineLimit(2)

                if let alternateTitle, alternateTitle != candidate.title {
                    Text(alternateTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                trackingControl(for: trackingStatus)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 16))
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Opens show details")
    }

    @ViewBuilder
    private func trackingControl(for trackingStatus: TrackingStatus?) -> some View {
        if let trackingStatus {
            Menu {
                Picker("Tracking status", selection: trackingStatusBinding) {
                    ForEach(TrackingStatus.allCases) { status in
                        Label(status.title, systemImage: status.systemImage)
                            .tag(Optional(status))
                    }
                }

                Divider()
                Button(role: .destructive, action: onRemoveFromLibrary) {
                    Label("Remove from My Shows", systemImage: "trash")
                }
            } label: {
                trackingControlLabel(
                    title: trackingStatus.title,
                    systemImage: trackingStatus.systemImage,
                    color: .green
                )
            }
            .accessibilityLabel("Change tracking status")
            .buttonStyle(.borderless)
        } else {
            Button(action: onAddToPlan) {
                trackingControlLabel(
                    title: "Add",
                    systemImage: "plus",
                    color: .accentColor
                )
            }
            .accessibilityLabel("Add to Plan to Watch")
            .buttonStyle(.borderless)
        }
    }

    private func trackingControlLabel(
        title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(minWidth: 132)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }

    private var trackingStatusBinding: Binding<TrackingStatus?> {
        Binding(
            get: { trackingStatus() },
            set: { status in
                guard let status else {
                    return
                }
                onSetTrackingStatus(status)
            }
        )
    }

    private var alternateTitle: String? {
        candidate.alternateTitle
    }

    private var details: String {
        MediaMetadata.text(
            releaseYear: candidate.releaseYear,
            totalEpisodeCount: candidate.totalEpisodeCount
        )
    }
}
