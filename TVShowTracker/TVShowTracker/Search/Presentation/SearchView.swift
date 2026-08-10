//
//  SearchView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
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
        }
    }

    private func searchResults(_ catalog: SearchCatalog) -> some View {
        List {
            if !catalog.tvShows.isEmpty {
                Section("TV Shows") {
                    ForEach(catalog.tvShows) { candidate in
                        SearchCandidateRow(candidate: candidate)
                    }
                }
            }

            if !catalog.anime.isEmpty {
                Section("Anime") {
                    ForEach(catalog.anime) { candidate in
                        SearchCandidateRow(candidate: candidate)
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: candidate.posterURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "tv")
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
        .accessibilityElement(children: .combine)
    }

    private var alternateTitle: String? {
        candidate.alternateTitle
    }
}
