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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                importIntroduction
                stateContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
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
            VStack(alignment: .leading, spacing: 12) {
                Label("Importing", systemImage: "arrow.triangle.2.circlepath")
                    .font(.title3.bold())
                ProgressView(value: progressFraction(progress)) {
                    Text(progressTitle(progress))
                } currentValueLabel: {
                    Text(progress.currentTitle ?? "Preparing…")
                }

                Button("Cancel", role: .cancel) {
                    viewModel.cancelImport()
                }
            }
            .padding(16)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
        case let .completed(report):
            reportContent(report)
        case let .failed(message):
            VStack(alignment: .leading, spacing: 12) {
                Label("Import failed", systemImage: "exclamationmark.triangle.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.red)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try again") {
                    viewModel.reset()
                }
            }
            .padding(16)
            .background(Color.red.opacity(0.08), in: .rect(cornerRadius: 16))
        }
    }

    private func reportContent(_ report: TVTimeImportReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Import complete", systemImage: "checkmark.circle.fill")
                .font(.title3.bold())
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                importMetric("Shows added", value: report.addedShowCount)
                importMetric("Already in My Shows", value: report.existingShowCount)
                importMetric("Watched episodes found", value: report.parsedWatchedEpisodeCount)
                importMetric("Watched episodes restored", value: report.restoredEpisodeCount)
                importMetric("Episodes not restored", value: report.unresolvedEpisodeCount)
            }
            .padding(16)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))

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

    private var importIntroduction: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "square.and.arrow.down")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.14), in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text("Move your TV Time progress")
                    .font(.title2.bold())
                Text("Choose the unmodified gdpr-data folder exported by TV Time. It stays on your device and is read only during this import.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Choose gdpr-data folder") {
                isFolderPickerPresented = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
        }
    }

    private func importMetric(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value, format: .number)
                .fontWeight(.semibold)
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
        case .restoringWatchedEpisodes:
            "Restoring watched episodes"
        }
    }

    private func progressFraction(_ progress: TVTimeImportProgress) -> Double {
        guard progress.totalUnitCount > 0 else {
            return 0
        }
        return Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
    }
}
