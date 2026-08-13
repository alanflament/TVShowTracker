//
//  DataBackupViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

@MainActor @Observable
final class DataBackupViewModel {
    private let exportUseCase: any DataExportUseCase
    private let importUseCase: any DataImportUseCase

    private(set) var document: TVShowTrackerBackupDocument?
    private(set) var errorMessage: String?
    private(set) var successMessage: String?
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
        do {
            let url = try result.get()
            let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let report = try importUseCase.importBackup(Data(contentsOf: url))
            successMessage = "Imported \(report.mediaCount) \(report.mediaCount == 1 ? "show" : "shows") and \(report.watchedEpisodeCount) watched \(report.watchedEpisodeCount == 1 ? "episode" : "episodes")."
            isSuccessPresented = true
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        isErrorPresented = true
    }
}
