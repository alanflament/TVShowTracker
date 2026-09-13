//
//  UpNextDetailsDestinationView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftUI

struct UpNextDetailsDestinationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isMediaDetailsAvailable = false
    @State private var isShowingMediaDetails = false
    let coordinator: CalendarCoordinator
    let episode: CalendarEpisode

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                coordinator.makeEpisodeDetailsView(
                    for: episode.candidate,
                    episode: episode.episode,
                    onShowMediaDetails: showMediaDetails
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(uiColor: .systemBackground))
                .allowsHitTesting(!isShowingMediaDetails)
                .accessibilityHidden(isShowingMediaDetails)

                Group {
                    if isMediaDetailsAvailable {
                        coordinator.makeDetailsView(for: episode.candidate)
                    } else {
                        Color(uiColor: .systemBackground)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(uiColor: .systemBackground))
                .allowsHitTesting(isShowingMediaDetails)
                .accessibilityHidden(!isShowingMediaDetails)
            }
            .frame(width: geometry.size.width * 2, alignment: .leading)
            .offset(x: isShowingMediaDetails ? -geometry.size.width : 0)
        }
        .clipped()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isShowingMediaDetails ? episode.candidate.title : episode.episode.title)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
    }

    private func showMediaDetails() {
        guard !isMediaDetailsAvailable else {
            return
        }

        isMediaDetailsAvailable = true

        if reduceMotion {
            isShowingMediaDetails = true
        } else {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.smooth(duration: 0.45)) {
                    isShowingMediaDetails = true
                }
            }
        }
    }
}
