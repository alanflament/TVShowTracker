//
//  TVTimeImportViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class TVTimeImportViewModel {
    enum State {
        case idle
        case importing(TVTimeImportProgress)
        case completed(TVTimeImportReport)
        case failed(String)
    }

    private let useCase: any TVTimeImportUseCase
    private var importTask: Task<Void, Never>?

    private(set) var state: State = .idle

    init(useCase: any TVTimeImportUseCase) {
        self.useCase = useCase
    }

    func importFolder(at folderURL: URL) {
        guard importTask == nil else {
            return
        }

        importTask = Task { [weak self] in
            await self?.runImport(at: folderURL)
        }
    }

    func cancelImport() {
        importTask?.cancel()
    }

    func reset() {
        guard importTask == nil else {
            return
        }
        state = .idle
    }

    private func runImport(at folderURL: URL) async {
        let isAccessingSecurityScopedResource = folderURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessingSecurityScopedResource {
                folderURL.stopAccessingSecurityScopedResource()
            }
            importTask = nil
        }

        do {
            let report = try await useCase.importExport(at: folderURL) { [weak self] progress in
                self?.state = .importing(progress)
            }
            state = .completed(report)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? "The import could not be completed.")
        }
    }
}
