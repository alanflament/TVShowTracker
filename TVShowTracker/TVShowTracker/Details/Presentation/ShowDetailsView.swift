//
//  ShowDetailsView.swift
//  TVShowTracker
//

import SwiftUI

struct ShowDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShowDetailsViewModel
    private let makeEpisodesViewModel: () -> EpisodesViewModel

    init(
        viewModel: ShowDetailsViewModel,
        makeEpisodesViewModel: @escaping () -> EpisodesViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeEpisodesViewModel = makeEpisodesViewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading details…")
                case let .loaded(details):
                    detailsContent(details)
                case let .failed(message):
                    ContentUnavailableView(
                        "Details unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle(viewModel.candidate.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private func detailsContent(_ details: ShowDetails) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(details)

                if let overview = details.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.title3.bold())
                        Text(overview)
                            .foregroundStyle(.secondary)
                    }
                }

                if !details.genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(details.genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }

                NavigationLink {
                    EpisodesView(viewModel: makeEpisodesViewModel())
                } label: {
                    Label("Episodes", systemImage: "list.number")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func header(_ details: ShowDetails) -> some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: details.posterURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(.quaternary)
                    .overlay { Image(systemName: "tv") }
            }
            .frame(width: 120, height: 180)
            .clipShape(.rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(details.title)
                    .font(.title2.bold())
                if let alternateTitle = details.alternateTitle, alternateTitle != details.title {
                    Text(alternateTitle)
                        .foregroundStyle(.secondary)
                }
                Text(details.metadata)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let status = details.status {
                    Text(status.rawValue.capitalized)
                        .font(.subheadline.weight(.medium))
                }
            }
        }
    }
}
