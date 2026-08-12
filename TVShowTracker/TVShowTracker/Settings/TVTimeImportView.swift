//
//  TVTimeImportView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct TVTimeImportView: View {
    @State private var viewModel: TVTimeImportViewModel
    @State private var isFolderPickerPresented = false

    init(viewModel: TVTimeImportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Text("Choose the unmodified gdpr-data folder exported by TV Time. The folder stays on your device and is read only during this import.")
                    .foregroundStyle(.secondary)

                Button("Choose gdpr-data folder") {
                    isFolderPickerPresented = true
                }
                .disabled(isImporting)
            }

            stateContent
        }
        .navigationTitle("TV Time import")
        .fileImporter(
            isPresented: $isFolderPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            guard case let .success(folderURL) = result else {
                return
            }
            viewModel.importFolder(at: folderURL)
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let folderURL = urls.first(where: \.hasDirectoryPath), !isImporting else {
                return false
            }
            viewModel.importFolder(at: folderURL)
            return true
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case let .importing(progress):
            Section("Importing") {
                ProgressView(value: progressFraction(progress)) {
                    Text(progressTitle(progress))
                } currentValueLabel: {
                    Text(progress.currentTitle ?? "Preparing…")
                }

                Button("Cancel", role: .cancel) {
                    viewModel.cancelImport()
                }
            }
        case let .completed(report):
            reportContent(report)
        case let .failed(message):
            Section("Import failed") {
                Text(message)
                    .foregroundStyle(.red)
                Button("Try again") {
                    viewModel.reset()
                }
            }
        }
    }

    private func reportContent(_ report: TVTimeImportReport) -> some View {
        Section("Import complete") {
            LabeledContent("Shows added", value: "\(report.addedShowCount)")
            LabeledContent("Already in Library", value: "\(report.existingShowCount)")
            LabeledContent("Watched episodes restored", value: "\(report.restoredEpisodeCount)")
            LabeledContent("Episodes not restored", value: "\(report.unresolvedEpisodeCount)")

            if !report.unresolvedShowTitles.isEmpty {
                NavigationLink("Shows needing review") {
                    List(report.unresolvedShowTitles, id: \.self) { title in
                        Text(title)
                    }
                    .navigationTitle("Needs review")
                }
            }

            Button("Import another folder") {
                viewModel.reset()
            }
        }
    }

    private var isImporting: Bool {
        if case .importing = viewModel.state {
            return true
        }
        return false
    }

    private func progressTitle(_ progress: TVTimeImportProgress) -> String {
        switch progress.phase {
        case .readingExport:
            "Reading export"
        case .resolvingShows:
            "Finding shows"
        case .loadingEpisodeSchedules:
            "Loading episode schedules"
        }
    }

    private func progressFraction(_ progress: TVTimeImportProgress) -> Double {
        guard progress.totalUnitCount > 0 else {
            return 0
        }
        return Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
    }
}
