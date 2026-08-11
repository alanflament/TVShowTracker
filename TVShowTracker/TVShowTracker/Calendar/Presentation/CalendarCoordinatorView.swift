//
//  CalendarCoordinatorView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

struct CalendarCoordinatorView: View {
    @State private var viewModel: CalendarViewModel

    init(coordinator: CalendarCoordinator) {
        _viewModel = State(initialValue: coordinator.makeCalendarViewModel())
    }

    var body: some View {
        NavigationStack {
            CalendarView(viewModel: viewModel)
        }
    }
}
