//
//  SettingsView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct SettingsView: View {
    private let makeTVTimeImportViewModel: () -> TVTimeImportViewModel

    init(makeTVTimeImportViewModel: @escaping () -> TVTimeImportViewModel) {
        self.makeTVTimeImportViewModel = makeTVTimeImportViewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    NavigationLink {
                        TVTimeImportView(viewModel: makeTVTimeImportViewModel())
                    } label: {
                        Label("Import TV Time data", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
