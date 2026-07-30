//
//  LibraryView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct LibraryView: View {
    
    @State private var viewModel: LibraryViewModel
    
    let onAddTapped: () -> Void
    let onItemTapped: (String) -> Void
    
    init(
        viewModel: LibraryViewModel,
        onAddTapped: @escaping () -> Void,
        onItemTapped: @escaping (String) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onAddTapped = onAddTapped
        self.onItemTapped = onItemTapped
    }
    
    var body: some View {
        Color.orange
            .navigationTitle("Library")
            .toolbar {
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                }
            }
            .task {
                await viewModel.load()
            }
    }
}
