//
//  SearchView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    let onSelectMedia: (MediaCandidate) -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                TrackerEmptyStateView(
                    title: "Find something to watch",
                    systemImage: "magnifyingglass",
                    description: "Search TV shows and anime, then add the ones you love to My Shows."
                )

            case .loading:
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Searching every catalogue…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(catalog):
                if catalog.isEmpty {
                    if catalog.unavailableProviders.isEmpty {
                        ContentUnavailableView.search(text: viewModel.query)
                    } else {
                        ContentUnavailableView(
                            "Discover unavailable",
                            systemImage: "exclamationmark.triangle",
                            description: Text(unavailableProviderMessage(for: catalog))
                        )
                    }
                } else {
                    searchResults(catalog)
                }
            }
        }
        .navigationTitle("Discover")
        .searchable(text: $viewModel.query, prompt: "Search TV shows and anime")
        .task(id: viewModel.searchTaskID) {
            await viewModel.search()
        }
    }

    private func searchResults(_ catalog: SearchCatalog) -> some View {
        List {
            catalogSection("TV Shows", candidates: catalog.tvShows)
            catalogSection("Anime", candidates: catalog.anime)

            if !catalog.unavailableProviders.isEmpty {
                Section {
                    Label("Some catalogues are temporarily unavailable. Results from the others are still shown.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.orange.opacity(0.08))
            }
        }
        .listStyle(.plain)
        .searchResultsLoadingIndicator(isVisible: viewModel.isRefreshingResults)
    }

    @ViewBuilder
    private func catalogSection(_ title: String, candidates: [MediaCandidate]) -> some View {
        if !candidates.isEmpty {
            Section(title) {
                ForEach(candidates) { candidate in
                    SearchCandidateRowView(candidate: candidate) {
                        onSelectMedia(candidate)
                    } onAddToPlan: {
                        viewModel.addToPlan(candidate)
                    } onSetTrackingStatus: { status in
                        viewModel.update(candidate, trackingStatus: status)
                    } onRemoveFromLibrary: {
                        viewModel.remove(candidate)
                    } trackingStatus: {
                        viewModel.trackingStatus(for: candidate)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
