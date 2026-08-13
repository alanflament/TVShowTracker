//
//  SettingsView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var dataBackupViewModel: DataBackupViewModel
    private let makeTVTimeImportViewModel: () -> TVTimeImportViewModel

    init(
        makeTVTimeImportViewModel: @escaping () -> TVTimeImportViewModel,
        dataBackupViewModel: DataBackupViewModel
    ) {
        self.makeTVTimeImportViewModel = makeTVTimeImportViewModel
        _dataBackupViewModel = State(initialValue: dataBackupViewModel)
    }

    var body: some View {
        @Bindable var dataBackupViewModel = dataBackupViewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your data")
                            .font(.title2.bold())
                        Text("Manage the media and progress you bring into TVShowTracker.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        TVTimeImportView(viewModel: makeTVTimeImportViewModel())
                    } label: {
                        SettingsActionCard(
                            title: "Import TV Time data",
                            subtitle: "Bring in followed shows and watched episodes",
                            systemImage: "square.and.arrow.down"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: dataBackupViewModel.prepareExport) {
                        SettingsActionCard(
                            title: "Export a backup",
                            subtitle: "Save your shows and watched history as JSON",
                            systemImage: "square.and.arrow.up",
                            showsDisclosureIndicator: false
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        dataBackupViewModel.isImporterPresented = true
                    } label: {
                        SettingsActionCard(
                            title: "Import a backup",
                            subtitle: "Merge shows and watched history from JSON",
                            systemImage: "arrow.down.doc",
                            showsDisclosureIndicator: false
                        )
                    }
                    .buttonStyle(.plain)

                    SettingsInfoCard(
                        title: "Kept on this device",
                        description: "Your followed shows, saved schedules, and watched progress are stored locally so your library remains available offline.",
                        systemImage: "lock.fill"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $dataBackupViewModel.isExporterPresented,
                document: dataBackupViewModel.document,
                contentType: .json,
                defaultFilename: dataBackupViewModel.defaultFilename,
                onCompletion: dataBackupViewModel.finishExport
            )
            .fileImporter(
                isPresented: $dataBackupViewModel.isImporterPresented,
                allowedContentTypes: [.json],
                onCompletion: dataBackupViewModel.importBackup
            )
            .alert("Backup failed", isPresented: $dataBackupViewModel.isErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dataBackupViewModel.errorMessage ?? "The backup could not be processed.")
            }
            .alert("Backup imported", isPresented: $dataBackupViewModel.isSuccessPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(dataBackupViewModel.successMessage ?? "Your data was imported.")
            }
        }
    }
}

private struct SettingsInfoCard: View {
    let title: String
    let description: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.07), in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.04), in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var showsDisclosureIndicator = true

    var body: some View {
        TrackerCard {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 42, height: 42)
                    .background(Color.accentColor.opacity(0.14), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                if showsDisclosureIndicator {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
