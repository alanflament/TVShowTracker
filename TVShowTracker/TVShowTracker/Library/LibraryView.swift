//
//  LibraryView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import SwiftUI

struct LibraryView: View {
    @Namespace private var categorySelectionNamespace
    @State private var pendingSelection: LibrarySelection?
    @State private var scrollPosition = ScrollPosition(edge: .top)

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
                        }
                    }
                }
                .scrollPosition($scrollPosition)
            }
        }
        .navigationTitle("My Shows")
        .searchable(text: $viewModel.query, prompt: "Search your library")
    }

    private func filterTabs(_ viewModel: LibraryViewModel) -> some View {
        GlassEffectContainer(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(LibraryCategory.allCases) { category in
                        LibraryCategoryTab(
                            category: category,
                            count: viewModel.count(for: category),
                            isSelected: viewModel.category == category,
                            selectionNamespace: categorySelectionNamespace
                        ) {
                            select(category, in: viewModel)
                        }
                    }
                }
                .padding(4)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))

                if !viewModel.category.secondaryFilters.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.category.secondaryFilters) { filter in
                                LibraryStatusTab(
                                    filter: filter,
                                    count: viewModel.count(for: filter),
                                    isSelected: viewModel.filter == filter
                                ) {
                                    select(filter, in: viewModel)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func select(
        _ category: LibraryCategory,
        in viewModel: LibraryViewModel
    ) {
        guard category != viewModel.category else {
            pendingSelection = nil
            return
        }

        let selection = LibrarySelection.category(category)
        pendingSelection = selection

        scrollToTop {
            guard pendingSelection == selection else {
                return
            }

            pendingSelection = nil
            withAnimation(.snappy(duration: 0.28, extraBounce: 0.05)) {
                viewModel.category = category
            }
        }
    }

    private func select(
        _ filter: LibraryFilter,
        in viewModel: LibraryViewModel
    ) {
        guard filter != viewModel.filter else {
            pendingSelection = nil
            return
        }

        let selection = LibrarySelection.filter(filter)
        pendingSelection = selection

        scrollToTop {
            guard pendingSelection == selection else {
                return
            }

            pendingSelection = nil
            withAnimation(.snappy(duration: 0.2)) {
                viewModel.filter = filter
            }
        }
    }

    private func scrollToTop(completion: @escaping () -> Void) {
        withAnimation(.smooth(duration: 0.32)) {
            scrollPosition.scrollTo(edge: .top)
        } completion: {
            completion()
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

private enum LibrarySelection: Equatable {
    case category(LibraryCategory)
    case filter(LibraryFilter)
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
