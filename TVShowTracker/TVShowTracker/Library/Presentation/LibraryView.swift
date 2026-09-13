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
    let makeDetailsView: (MediaCandidate) -> ShowDetailsView
    let searchDiscover: (String) -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            if let errorMessage = viewModel.errorMessage {
                TrackerEmptyStateView(
                    title: "Library unavailable",
                    systemImage: "externaldrive.badge.xmark",
                    description: errorMessage
                )
            } else if viewModel.isLibraryEmpty, viewModel.discoverQuery == nil {
                TrackerEmptyStateView(
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
                                    columns: Array(
                                        repeating: GridItem(.flexible(minimum: 0), spacing: 0),
                                        count: 3
                                    ),
                                    spacing: 0
                                ) {
                                    ForEach(viewModel.items) { item in
                                        NavigationLink {
                                            makeDetailsView(item.candidate)
                                        } label: {
                                            LibraryItemCardView(item: item)
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
                        LibraryCategoryTabView(
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
                                LibraryStatusTabView(
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
            if let query = viewModel.discoverQuery {
                TrackerEmptyStateView(
                    title: "Not in My Shows",
                    systemImage: "magnifyingglass.circle.fill",
                    description: "Nothing in your library matches “\(query)”. Search for it in Discover and add it to My Shows."
                )

                Button {
                    viewModel.prepareForDiscoverSearch()
                    searchDiscover(query)
                } label: {
                    Label("Search in Discover", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
            } else {
                TrackerEmptyStateView(
                    title: "No matching shows",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: "No shows match these filters. Clear them to see your full library."
                )

                Button("Show all shows") {
                    viewModel.resetFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
