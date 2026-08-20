//
//  CalendarEpisodeCard.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation
import SwiftUI

struct CalendarEpisodeCard: View {
    let episode: CalendarEpisode
    let onSelect: () -> Void
    let onMarkWatched: () async -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var watchedConfirmationPhase = WatchedConfirmationPhase.idle

    private enum WatchedConfirmationPhase {
        case idle
        case success
        case celebration
    }

    private var isConfirmingWatched: Bool {
        watchedConfirmationPhase != .idle
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MediaPoster(url: episode.posterURL, kind: episode.candidate.kind, width: 80, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(episode.showTitle)
                        .font(.headline)
                        .lineLimit(2)
                        .layoutPriority(1)

                    if episode.additionalAvailableEpisodeCount > 0 {
                        AdditionalEpisodesBadge(count: episode.additionalAvailableEpisodeCount)
                    }
                }
                HStack(spacing: 7) {
                    Text(String(format: "S%02dE%02d", episode.episode.seasonNumber, episode.episode.number))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let duration = episode.episode.formattedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
                Text(episode.episode.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)

                if !episode.episode.isReleased {
                    releaseStatus
                        .frame(height: 32, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if episode.episode.isReleased {
                watchedButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.08))
        }
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens episode details")
    }

    private var watchedButton: some View {
        Button {
            guard !isConfirmingWatched else {
                return
            }

            withAnimation(
                accessibilityReduceMotion ? nil : .bouncy(duration: 0.3, extraBounce: 0.18)
            ) {
                watchedConfirmationPhase = .success
            }
            Task {
                if accessibilityReduceMotion {
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    await onMarkWatched()
                    return
                }

                try? await Task.sleep(nanoseconds: 350_000_000)
                withAnimation(.bouncy(duration: 0.4, extraBounce: 0.24)) {
                    watchedConfirmationPhase = .celebration
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                await onMarkWatched()
            }
        } label: {
            ZStack {
                Image(
                    systemName: watchedConfirmationPhase == .idle
                        ? "checkmark.circle"
                        : "checkmark.circle.fill"
                )
                .font(.title)
                .foregroundStyle(
                    watchedConfirmationPhase == .idle ? Color.secondary : Color.green
                )
                .scaleEffect(watchedConfirmationPhase == .success ? 1.12 : 1)
                .scaleEffect(watchedConfirmationPhase == .celebration ? 0.45 : 1)
                .opacity(watchedConfirmationPhase == .celebration ? 0 : 1)

                Text("🎉")
                    .font(.system(size: 34))
                    .scaleEffect(watchedConfirmationPhase == .celebration ? 1 : 0.35)
                    .rotationEffect(
                        .degrees(watchedConfirmationPhase == .celebration ? 8 : -24)
                    )
                    .opacity(watchedConfirmationPhase == .celebration ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .frame(width: 52, height: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isConfirmingWatched)
        .sensoryFeedback(.success, trigger: isConfirmingWatched)
        .accessibilityLabel(isConfirmingWatched ? "Watched" : "Mark as watched")
        .accessibilityValue(isConfirmingWatched ? "Watched" : "Unwatched")
    }

    @ViewBuilder
    private var releaseStatus: some View {
        if let airDate = episode.episode.airDate {
            Label(
                ReleaseCountdown(
                    airDate: airDate,
                    precision: episode.episode.releaseDatePrecision
                ).text,
                systemImage: "clock"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.orange)
        } else {
            Label("Release date unavailable", systemImage: "calendar.badge.exclamationmark")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AdditionalEpisodesBadge: View {
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

private struct ReleaseCountdown {
    let airDate: Date
    let precision: EpisodeReleaseDatePrecision

    var text: String {
        let interval = max(0, airDate.timeIntervalSinceNow)
        if precision == .time, interval < 86400 {
            let hours = max(1, Int(ceil(interval / 3600)))
            return "Available in \(hours) \(hours == 1 ? "hour" : "hours")"
        }

        let days = Int(ceil(interval / 86400))
        return "Available in \(days) \(days == 1 ? "day" : "days")"
    }
}
