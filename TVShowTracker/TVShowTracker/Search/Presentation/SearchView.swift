//
//  SearchView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var selectedCandidate: SearchCandidate?
    private let detailsCoordinator: DetailsCoordinator

    init(viewModel: SearchViewModel, detailsCoordinator: DetailsCoordinator) {
        _viewModel = State(initialValue: viewModel)
        self.detailsCoordinator = detailsCoordinator
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView.search

                case .loading:
                    ProgressView("Searching…")

                case let .loaded(catalog):
                    if catalog.isEmpty {
                        if catalog.unavailableProviders.isEmpty {
                            ContentUnavailableView.search(text: viewModel.query)
                        } else {
                            ContentUnavailableView(
                                "Search unavailable",
                                systemImage: "exclamationmark.triangle",
                                description: Text(unavailableProviderMessage(for: catalog))
                            )
                        }
                    } else {
                        searchResults(catalog)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Search TV shows and anime")
            .task(id: viewModel.query) {
                await viewModel.search()
            }
            .sheet(item: $selectedCandidate) { candidate in
                detailsCoordinator.makeDetailsSheet(for: candidate)
            }
        }
    }

    private func searchResults(_ catalog: SearchCatalog) -> some View {
        List {
            if !catalog.tvShows.isEmpty {
                Section("TV Shows") {
                    ForEach(catalog.tvShows) { candidate in
                        SearchCandidateRow(candidate: candidate) {
                            selectedCandidate = candidate
                        } onToggleLibrary: {
                            viewModel.toggleFollowed(candidate)
                        } isFollowed: {
                            viewModel.isFollowed(candidate)
                        }
                    }
                }
            }

            if !catalog.anime.isEmpty {
                Section("Anime") {
                    ForEach(catalog.anime) { candidate in
                        SearchCandidateRow(candidate: candidate) {
                            selectedCandidate = candidate
                        } onToggleLibrary: {
                            viewModel.toggleFollowed(candidate)
                        } isFollowed: {
                            viewModel.isFollowed(candidate)
                        }
                    }
                }
            }

            if !catalog.unavailableProviders.isEmpty {
                Section {
                    Text("Some sources are temporarily unavailable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func unavailableProviderMessage(for catalog: SearchCatalog) -> String {
        let failures = catalog.unavailableProviders
            .sorted { $0.displayName < $1.displayName }
            .map { provider in
                let reason = catalog.providerErrors[provider] ?? "This source could not be reached."
                return "\(provider.displayName): \(reason)"
            }
            .sorted()

        return failures.joined(separator: "\n")
    }
}

private struct SearchCandidateRow: View {
    let candidate: SearchCandidate
    let onSelect: () -> Void
    let onToggleLibrary: () -> Void
    let isFollowed: () -> Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: candidate.posterURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                            .overlay {
                                Image(systemName: candidate.kind == .anime ? "sparkles.tv" : "tv")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 56, height: 84)
                    .clipShape(.rect(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.title)
                            .font(.headline)

                        if let alternateTitle, alternateTitle != candidate.title {
                            Text(alternateTitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(candidate.metadata)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: onToggleLibrary) {
                Image(systemName: isFollowed() ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(
                        isFollowed() ? Color.green : Color.accentColor
                    )
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isFollowed() ? "Remove from library" : "Add to library")
        }
        .accessibilityElement(children: .combine)
    }

    private var alternateTitle: String? {
        candidate.alternateTitle
    }
}
