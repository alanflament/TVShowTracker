//
//  DataBackupViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class DataBackupViewModel {
    private let exportUseCase: any DataExportUseCase
    private let importUseCase: any DataImportUseCase

    private(set) var document: TVShowTrackerBackupDocument?
    private(set) var errorMessage: String?
    private(set) var successMessage: String?
    private(set) var importProgressMessage = "Restoring your backup…"
    private(set) var isImporting = false
    var isExporterPresented = false
    var isImporterPresented = false
    var isErrorPresented = false
    var isSuccessPresented = false

    init(
        exportUseCase: any DataExportUseCase,
        importUseCase: any DataImportUseCase
    ) {
        self.exportUseCase = exportUseCase
        self.importUseCase = importUseCase
    }

    var defaultFilename: String {
        let date = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return "TVShowTracker-backup-\(date)"
    }

    func prepareExport() {
        do {
            document = try TVShowTrackerBackupDocument(data: exportUseCase.export(at: .now))
            errorMessage = nil
            isExporterPresented = true
        } catch {
            present(error)
        }
    }

    func finishExport(_ result: Result<URL, Error>) {
        isExporterPresented = false
        document = nil
        if case let .failure(error) = result {
            present(error)
        }
    }

    func importBackup(from result: Result<URL, Error>) {
        guard !isImporting else { return }
        do {
            let url = try result.get()
            let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            isImporting = true
            importProgressMessage = "Restoring your backup…"
            Task {
                await importBackup(data)
            }
        } catch {
            present(error)
        }
    }

    private func importBackup(_ data: Data) async {
        defer { isImporting = false }

        do {
            let report = try await importUseCase.importBackup(data) { [weak self] progress in
                self?.updateImportProgress(progress)
            }
            successMessage = successMessage(for: report)
            isSuccessPresented = true
        } catch {
            present(error)
        }
    }

    private func updateImportProgress(_ progress: DataImportProgress) {
        switch progress.phase {
        case .restoringBackup:
            importProgressMessage = "Restoring your backup…"
        case .refreshingMedia:
            guard progress.totalUnitCount > 0 else {
                importProgressMessage = "Finishing your restore…"
                return
            }
            importProgressMessage = "Updating show information \(progress.completedUnitCount) of \(progress.totalUnitCount)…"
        }
    }

    private func successMessage(for report: DataImportReport) -> String {
        let imported = "Imported \(report.mediaCount) \(report.mediaCount == 1 ? "show" : "shows") and \(report.watchedEpisodeCount) watched \(report.watchedEpisodeCount == 1 ? "episode" : "episodes")."
        guard report.mediaCount > 0 else {
            return imported
        }

        let refreshed = "Updated information for \(report.refreshedMediaCount) \(report.refreshedMediaCount == 1 ? "show" : "shows") and saved \(report.refreshedScheduleCount) \(report.refreshedScheduleCount == 1 ? "episode schedule" : "episode schedules")."
        guard report.mediaRefreshFailureCount > 0 else {
            return "\(imported) \(refreshed)"
        }

        let unavailable = "Information for \(report.mediaRefreshFailureCount) \(report.mediaRefreshFailureCount == 1 ? "show" : "shows") could not be updated right now; restored data remains available."
        return "\(imported) \(refreshed) \(unavailable)"
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        isErrorPresented = true
    }
}
