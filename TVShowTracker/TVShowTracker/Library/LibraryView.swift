//
//  LibraryView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import SwiftUI
import UIKit

struct LibraryView: View {
    @State private var isFilterPopoverPresented = false
    let viewModel: LibraryViewModel
    let makeDetailsView: (SearchCandidate) -> ShowDetailsView

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            if let errorMessage = viewModel.errorMessage {
                TrackerEmptyState(
                    title: "Library unavailable",
                    systemImage: "externaldrive.badge.xmark",
                    description: errorMessage
                )
            } else if viewModel.isLibraryEmpty {
                TrackerEmptyState(
                    title: "Build your watchlist",
                    systemImage: "rectangle.stack.badge.plus",
                    description: "Find TV shows and anime in Discover, then add them here to keep track of every release."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            if viewModel.items.isEmpty {
                                noMatchesView(viewModel)
                                    .padding(.top, 80)
                            } else {
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 152, maximum: 180), spacing: 16)],
                                    spacing: 20
                                ) {
                                    ForEach(viewModel.items) { item in
                                        NavigationLink {
                                            makeDetailsView(item.candidate)
                                        } label: {
                                            LibraryItemCard(item: item)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                viewModel.remove(item)
                                            } label: {
                                                Label("Remove from My Shows", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                            }
                        } header: {
                            filterMenu(viewModel, isPresented: $isFilterPopoverPresented)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                                .background(Color(.systemBackground))
                        }
                    }
                }
            }
        }
        .navigationTitle("My Shows")
        .searchable(text: $viewModel.query, prompt: "Search your library")
        .background(OpaqueNavigationBarAppearance())
    }

    private func filterMenu(
        _ viewModel: LibraryViewModel,
        isPresented: Binding<Bool>
    ) -> some View {
        Button {
            isPresented.wrappedValue.toggle()
        } label: {
            Label(viewModel.filter.title, systemImage: "line.3.horizontal.decrease.circle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .popover(isPresented: isPresented, arrowEdge: .top) {
            VStack(spacing: 4) {
                ForEach(LibraryFilter.allCases) { filter in
                    Button {
                        viewModel.filter = filter
                        isPresented.wrappedValue = false
                    } label: {
                        HStack(spacing: 12) {
                            filterCountBadge(viewModel.count(for: filter))

                            Text(filter.title)
                                .foregroundStyle(.primary)

                            Spacer()

                            if viewModel.filter == filter {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .accessibilityLabel(filterAccessibilityLabel(filter, viewModel: viewModel))
                    .accessibilityAddTraits(viewModel.filter == filter ? .isSelected : [])
                }
            }
            .padding(.vertical, 8)
            .frame(width: 260)
            .presentationCompactAdaptation(.popover)
        }
    }

    private func filterCountBadge(_ count: Int) -> some View {
        Text(count, format: .number)
            .font(.caption2.bold())
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(minWidth: 22)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }

    private func filterAccessibilityLabel(
        _ filter: LibraryFilter,
        viewModel: LibraryViewModel
    ) -> String {
        let count = viewModel.count(for: filter)
        return "\(filter.title), \(count) \(count == 1 ? "show" : "shows")"
    }

    private func noMatchesView(_ viewModel: LibraryViewModel) -> some View {
        VStack(spacing: 0) {
            TrackerEmptyState(
                title: "No matching shows",
                systemImage: "magnifyingglass",
                description: "Try a different title, or clear the current filter to see your full library."
            )

            Button("Show all shows") {
                viewModel.resetFilters()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OpaqueNavigationBarAppearance: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> NavigationBarAppearanceController {
        NavigationBarAppearanceController()
    }

    func updateUIViewController(
        _ uiViewController: NavigationBarAppearanceController,
        context _: Context
    ) {
        uiViewController.applyAppearanceIfVisible()
    }

    final class NavigationBarAppearanceController: UIViewController {
        private var originalStandardAppearance: UINavigationBarAppearance?
        private var originalScrollEdgeAppearance: UINavigationBarAppearance?
        private var originalCompactAppearance: UINavigationBarAppearance?
        private var hasCapturedOriginalAppearance = false

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            applyAppearance()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restoreAppearance()
        }

        func applyAppearanceIfVisible() {
            guard viewIfLoaded?.window != nil else {
                return
            }
            applyAppearance()
        }

        private func applyAppearance() {
            guard let navigationBar = navigationController?.navigationBar else {
                return
            }

            if !hasCapturedOriginalAppearance {
                originalStandardAppearance = navigationBar.standardAppearance.copy()
                originalScrollEdgeAppearance = navigationBar.scrollEdgeAppearance?.copy()
                originalCompactAppearance = navigationBar.compactAppearance?.copy()
                hasCapturedOriginalAppearance = true
            }

            makeOpaque(navigationBar.standardAppearance)
            if let scrollEdgeAppearance = navigationBar.scrollEdgeAppearance {
                makeOpaque(scrollEdgeAppearance)
            }
            if let compactAppearance = navigationBar.compactAppearance {
                makeOpaque(compactAppearance)
            }
        }

        private func makeOpaque(_ appearance: UINavigationBarAppearance) {
            appearance.backgroundEffect = nil
            appearance.backgroundColor = .systemBackground
        }

        private func restoreAppearance() {
            guard hasCapturedOriginalAppearance,
                  let navigationBar = navigationController?.navigationBar,
                  let originalStandardAppearance
            else {
                return
            }

            navigationBar.standardAppearance = originalStandardAppearance
            navigationBar.scrollEdgeAppearance = originalScrollEdgeAppearance
            navigationBar.compactAppearance = originalCompactAppearance
        }
    }
}

private struct LibraryItemCard: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MediaPoster(url: item.posterURL, kind: item.kind, height: 252, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2, reservesSpace: true)

                Label(item.trackingStatus.title, systemImage: item.trackingStatus.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(details.isEmpty ? " " : details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens show details")
    }

    private var details: String {
        MediaMetadata.text(
            releaseYear: item.releaseYear,
            totalEpisodeCount: item.totalEpisodeCount
        )
    }

    private var accessibilityLabel: String {
        [item.title, item.trackingStatus.title, details]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
