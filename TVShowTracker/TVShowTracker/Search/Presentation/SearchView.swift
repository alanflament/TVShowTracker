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
                    SearchCandidateRow(candidate: candidate) {
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

private extension View {
    func searchResultsLoadingIndicator(isVisible: Bool) -> some View {
        modifier(SearchResultsLoadingIndicatorModifier(isVisible: isVisible))
    }
}

private struct SearchResultsLoadingIndicatorModifier: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isVisible {
                    SearchResultsLoadingIndicator()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}

private struct SearchResultsLoadingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)

            Text("Updating results…")
                .font(.footnote.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Updating search results")
        .allowsHitTesting(false)
    }
}

private struct SearchCandidateRow: View {
    let candidate: MediaCandidate
    let onSelect: () -> Void
    let onAddToPlan: () -> Void
    let onSetTrackingStatus: (TrackingStatus) -> Void
    let onRemoveFromLibrary: () -> Void
    let trackingStatus: () -> TrackingStatus?

    var body: some View {
        let trackingStatus = trackingStatus()

        HStack(alignment: .top, spacing: 12) {
            MediaPoster(url: candidate.posterURL, kind: candidate.kind, width: 72, height: 108)

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

                Spacer(minLength: 8)

                trackingControl(for: trackingStatus)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 16))
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Opens show details")
    }

    @ViewBuilder
    private func trackingControl(for trackingStatus: TrackingStatus?) -> some View {
        if let trackingStatus {
            Menu {
                Picker("Tracking status", selection: trackingStatusBinding) {
                    ForEach(TrackingStatus.allCases) { status in
                        Label(status.title, systemImage: status.systemImage)
                            .tag(Optional(status))
                    }
                }

                Divider()
                Button(role: .destructive, action: onRemoveFromLibrary) {
                    Label("Remove from My Shows", systemImage: "trash")
                }
            } label: {
                trackingControlLabel(
                    title: trackingStatus.title,
                    systemImage: trackingStatus.systemImage,
                    color: .green
                )
            }
            .accessibilityLabel("Change tracking status")
            .buttonStyle(.borderless)
        } else {
            Button(action: onAddToPlan) {
                trackingControlLabel(
                    title: "Add",
                    systemImage: "plus",
                    color: .accentColor
                )
            }
            .accessibilityLabel("Add to Plan to Watch")
            .buttonStyle(.borderless)
        }
    }

    private func trackingControlLabel(
        title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(minWidth: 132)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }

    private var trackingStatusBinding: Binding<TrackingStatus?> {
        Binding(
            get: { trackingStatus() },
            set: { status in
                guard let status else {
                    return
                }
                onSetTrackingStatus(status)
            }
        )
    }

    private var alternateTitle: String? {
        candidate.alternateTitle
    }

    private var details: String {
        MediaMetadata.text(
            releaseYear: candidate.releaseYear,
            totalEpisodeCount: candidate.totalEpisodeCount
        )
    }
}
