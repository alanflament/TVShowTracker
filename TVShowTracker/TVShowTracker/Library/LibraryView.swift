//
//  LibraryView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import SwiftUI
import UIKit

struct LibraryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var categorySelectionNamespace

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
                            filterTabs(viewModel)
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
        .background(OpaqueNavigationBarAppearance(colorScheme: colorScheme))
    }

    private func filterTabs(_ viewModel: LibraryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(LibraryCategory.allCases) { category in
                    LibraryCategoryTab(
                        category: category,
                        count: viewModel.count(for: category),
                        isSelected: viewModel.category == category,
                        selectionNamespace: categorySelectionNamespace
                    ) {
                        withAnimation(.snappy(duration: 0.28, extraBounce: 0.05)) {
                            viewModel.category = category
                        }
                    }
                }
            }
            .padding(4)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 14))

            if !viewModel.category.secondaryFilters.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.category.secondaryFilters) { filter in
                            LibraryStatusTab(
                                filter: filter,
                                count: viewModel.count(for: filter),
                                isSelected: viewModel.filter == filter
                            ) {
                                withAnimation(.snappy(duration: 0.2)) {
                                    viewModel.filter = filter
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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

private struct LibraryCategoryTab: View {
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

private struct LibraryStatusTab: View {
    let filter: LibraryFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(filter.title)
                Text(count, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .background(
                isSelected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(filter.title), \(count) \(count == 1 ? "show" : "shows")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OpaqueNavigationBarAppearance: UIViewControllerRepresentable {
    let colorScheme: ColorScheme

    func makeUIViewController(context _: Context) -> NavigationBarAppearanceController {
        NavigationBarAppearanceController(colorScheme: colorScheme)
    }

    func updateUIViewController(
        _ uiViewController: NavigationBarAppearanceController,
        context _: Context
    ) {
        uiViewController.colorScheme = colorScheme
        uiViewController.applyAppearanceIfVisible()
    }

    final class NavigationBarAppearanceController: UIViewController {
        var colorScheme: ColorScheme

        private var originalStandardAppearance: UINavigationBarAppearance?
        private var originalScrollEdgeAppearance: UINavigationBarAppearance?
        private var originalCompactAppearance: UINavigationBarAppearance?
        private var originalBarStyle: UIBarStyle?
        private var hasCapturedOriginalAppearance = false

        init(colorScheme: ColorScheme) {
            self.colorScheme = colorScheme
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

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
                originalBarStyle = navigationBar.barStyle
                hasCapturedOriginalAppearance = true
            }

            navigationBar.barStyle = colorScheme == .dark ? .black : .default
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
            appearance.titleTextAttributes[.foregroundColor] = UIColor.label
            appearance.largeTitleTextAttributes[.foregroundColor] = UIColor.label
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
            if let originalBarStyle {
                navigationBar.barStyle = originalBarStyle
            }
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
