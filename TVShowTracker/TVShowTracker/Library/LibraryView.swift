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
        Group {
            if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(
                    "Library unavailable",
                    systemImage: "externaldrive.badge.xmark",
                    description: Text(errorMessage)
                )
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "Your library is empty",
                    systemImage: "books.vertical",
                    description: Text("Add TV shows and anime from Search to follow them here.")
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            makeDetailsView(item.candidate)
                        } label: {
                            LibraryItemRow(item: item)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.remove(item)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Library")
    }
}

private struct LibraryItemRow: View {
    let item: LibraryItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: item.posterURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: item.kind == .anime ? "sparkles.tv" : "tv")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 56, height: 84)
            .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                if let alternateTitle = item.alternateTitle, alternateTitle != item.title {
                    Text(alternateTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(item.metadata)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
