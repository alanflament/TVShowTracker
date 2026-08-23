//
//  FullScreenMediaPosterView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 23/08/2026.
//

import SwiftUI

struct FullScreenMediaPosterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var settledOffset = CGSize.zero
    @State private var isDismissing = false

    let title: String
    let posterURL: URL?
    let kind: SearchMediaKind

    private let maximumScale: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let displayedPosterSize = posterSize(in: proxy.size)

            ZStack(alignment: .topTrailing) {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPoster()
                    }

                MediaPoster(
                    url: fullScreenPosterURL,
                    kind: kind,
                    width: displayedPosterSize.width,
                    height: displayedPosterSize.height,
                    cornerRadius: 16
                )
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .scaleEffect(scale)
                .offset(offset)
                .accessibilityElement()
                .accessibilityIdentifier("Full-screen poster")
                .accessibilityLabel("\(title) poster")
                .accessibilityValue(scale > 1 ? "Zoomed" : "Fit to screen")
                .accessibilityHint("Pinch or double-tap to zoom. Drag to move while zoomed.")
                .onTapGesture(count: 2) {
                    toggleZoom(in: proxy.size, posterSize: displayedPosterSize)
                }

                Button {
                    dismissPoster()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close poster")
                .disabled(isDismissing)
                .padding(20)
            }
            .contentShape(.rect)
            .gesture(dragGesture(availableSize: proxy.size, posterSize: displayedPosterSize))
            .simultaneousGesture(
                magnificationGesture(availableSize: proxy.size, posterSize: displayedPosterSize)
            )
        }
        .background(Color.black)
        .navigationTitle("\(title) poster")
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden()
    }

    private var fullScreenPosterURL: URL? {
        guard
            let posterURL,
            posterURL.host() == "image.tmdb.org",
            var components = URLComponents(url: posterURL, resolvingAgainstBaseURL: false)
        else {
            return posterURL
        }

        var pathComponents = components.path.split(separator: "/").map(String.init)
        guard let sizeIndex = pathComponents.firstIndex(where: isTMDBImageSize) else {
            return posterURL
        }
        pathComponents[sizeIndex] = "w780"
        components.path = "/" + pathComponents.joined(separator: "/")
        return components.url ?? posterURL
    }

    private func isTMDBImageSize(_ component: String) -> Bool {
        component == "original" || (
            component.first == "w" && component.dropFirst().allSatisfy(\.isNumber)
        )
    }

    private func posterSize(in availableSize: CGSize) -> CGSize {
        let maximumWidth = max(0, availableSize.width - 32)
        let maximumHeight = max(0, availableSize.height - 64)
        let width = min(maximumWidth, maximumHeight * 2 / 3)
        return CGSize(width: width, height: width * 3 / 2)
    }

    private func constrainedOffset(
        _ proposedOffset: CGSize,
        availableSize: CGSize,
        posterSize: CGSize
    ) -> CGSize {
        let maximumX = max(0, (posterSize.width * scale - availableSize.width) / 2)
        let maximumY = max(0, (posterSize.height * scale - availableSize.height) / 2)
        return CGSize(
            width: min(maximumX, max(-maximumX, proposedOffset.width)),
            height: min(maximumY, max(-maximumY, proposedOffset.height))
        )
    }

    private func dragGesture(availableSize: CGSize, posterSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard scale > 1 else { return }
                offset = constrainedOffset(
                    CGSize(
                        width: settledOffset.width + value.translation.width,
                        height: settledOffset.height + value.translation.height
                    ),
                    availableSize: availableSize,
                    posterSize: posterSize
                )
            }
            .onEnded { value in
                if scale > 1 {
                    offset = constrainedOffset(
                        offset,
                        availableSize: availableSize,
                        posterSize: posterSize
                    )
                    settledOffset = offset
                } else if value.translation.height > 80 {
                    dismissPoster()
                }
            }
    }

    private func magnificationGesture(availableSize: CGSize, posterSize: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(maximumScale, max(1, settledScale * value))
                offset = constrainedOffset(
                    offset,
                    availableSize: availableSize,
                    posterSize: posterSize
                )
            }
            .onEnded { _ in
                settledScale = scale
                if scale == 1 {
                    resetPosition()
                } else {
                    offset = constrainedOffset(
                        offset,
                        availableSize: availableSize,
                        posterSize: posterSize
                    )
                    settledOffset = offset
                }
            }
    }

    private func toggleZoom(in availableSize: CGSize, posterSize: CGSize) {
        withAnimation(.snappy(duration: 0.25)) {
            if scale > 1 {
                resetPosition()
            } else {
                scale = 2
                settledScale = 2
                offset = constrainedOffset(
                    .zero,
                    availableSize: availableSize,
                    posterSize: posterSize
                )
                settledOffset = offset
            }
        }
    }

    private func resetPosition() {
        scale = 1
        settledScale = 1
        offset = .zero
        settledOffset = .zero
    }

    private func dismissPoster() {
        guard !isDismissing else { return }
        guard scale > 1 || offset != .zero else {
            dismiss()
            return
        }

        isDismissing = true
        withAnimation(.snappy(duration: 0.2)) {
            resetPosition()
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            dismiss()
        }
    }
}
