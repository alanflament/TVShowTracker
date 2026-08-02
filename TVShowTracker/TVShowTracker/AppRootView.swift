//
//  AppRootView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct AppRootView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        switch coordinator.root {
        case .onboarding:
            OnboardingView(
                onFinished: coordinator.finishOnboarding
            )
        case .main:
            MainCoordinatorView(
                coordinator: coordinator.mainCoordinator
            )
        }
    }
}
