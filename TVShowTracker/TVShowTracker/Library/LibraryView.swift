//
//  LibraryView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import SwiftUI

struct LibraryView: View {
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
            } else if viewModel.items.isEmpty {
                TrackerEmptyState(
                    title: "No matching shows",
                    systemImage: "magnifyingglass",
                    description: "Try a different title, or clear the current filter to see your full library."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        Picker("Filter", selection: $viewModel.filter) {
                            ForEach(LibraryFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

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
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Shows")
        .searchable(text: $viewModel.query, prompt: "Search your library")
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

                Text(item.status?.rawValue.capitalized ?? " ")
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
        [item.title, item.status?.rawValue.capitalized, details]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
