//
//  SettingsView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage(AppAppearance.storageKey) private var appAppearance = AppAppearance.automatic
    @Bindable var viewModel: DataBackupViewModel
    let makeTVTimeImportView: () -> TVTimeImportView

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Appearance")
                        .font(.title2.bold())
                    Text("Choose how Showlogue looks on this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TrackerCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 42, height: 42)
                                .background(Color.accentColor.opacity(0.14), in: .rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("App appearance")
                                    .font(.headline)
                                Text("Light, dark, or match your device")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }

                        Divider()

                        HStack {
                            Text("Style")
                                .font(.subheadline.weight(.medium))

                            Spacer(minLength: 8)

                            Picker("App appearance", selection: $appAppearance) {
                                ForEach(AppAppearance.allCases) { appearance in
                                    Text(appearance.title)
                                        .tag(appearance)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("App appearance")
                            .accessibilityValue(appAppearance.title)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Your data")
                        .font(.title2.bold())
                    Text("Manage the media and progress you bring into TVShowTracker.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    makeTVTimeImportView()
                } label: {
                    SettingsActionCard(
                        title: "Import TV Time data",
                        subtitle: "Bring in followed shows and watched episodes",
                        systemImage: "square.and.arrow.down"
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isImporting)

                Button(action: viewModel.prepareExport) {
                    SettingsActionCard(
                        title: "Export a backup",
                        subtitle: "Save your shows and watched history as JSON",
                        systemImage: "square.and.arrow.up",
                        showsDisclosureIndicator: false
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isImporting)

                Button {
                    viewModel.isImporterPresented = true
                } label: {
                    SettingsActionCard(
                        title: "Import a backup",
                        subtitle: "Merge shows and watched history from JSON",
                        systemImage: "arrow.down.doc",
                        showsDisclosureIndicator: false
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isImporting)

                if viewModel.isImporting {
                    TrackerCard {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(viewModel.importProgressMessage)
                                .font(.subheadline.weight(.medium))
                            Spacer(minLength: 0)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(viewModel.importProgressMessage)
                }

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
            isPresented: $viewModel.isExporterPresented,
            document: viewModel.document,
            contentType: .json,
            defaultFilename: viewModel.defaultFilename,
            onCompletion: viewModel.finishExport
        )
        .fileImporter(
            isPresented: $viewModel.isImporterPresented,
            allowedContentTypes: [.json],
            onCompletion: viewModel.importBackup
        )
        .alert("Backup failed", isPresented: $viewModel.isErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "The backup could not be processed.")
        }
        .alert("Backup imported", isPresented: $viewModel.isSuccessPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "Your data was imported.")
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
