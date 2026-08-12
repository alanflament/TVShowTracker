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
                    TrackerEmptyState(
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
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }

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
        let isFollowed = isFollowed()

        ZStack(alignment: .bottomTrailing) {
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
                .frame(width: 72, height: 108)
                .clipShape(.rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.title)
                        .font(.headline)
                        .lineLimit(2)

                    if let alternateTitle, alternateTitle != candidate.title {
                        Text(alternateTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if !details.isEmpty {
                        Text(details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)

            Button(action: onToggleLibrary) {
                Label(
                    isFollowed ? "Following" : "Add",
                    systemImage: isFollowed ? "checkmark" : "plus"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(isFollowed ? Color.green : Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.primary.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isFollowed ? "Remove from My Shows" : "Add to My Shows")
            .padding(12)
        }
        .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 16))
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Opens show details")
    }

    private var alternateTitle: String? {
        candidate.alternateTitle
    }

    private var details: String {
        [
            candidate.releaseYear.map(String.init),
            candidate.totalEpisodeCount.map { "\($0) episodes" }
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }
}
