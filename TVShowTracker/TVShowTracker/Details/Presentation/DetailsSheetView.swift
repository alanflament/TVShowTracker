//
//  DetailsSheetView.swift
//  TVShowTracker
//

import SwiftUI

struct DetailsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let detailsView: ShowDetailsView

    var body: some View {
        NavigationStack {
            detailsView
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
