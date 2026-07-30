//
//  AppCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class AppCoordinator {
    enum Root {
        case onboarding
        case main
    }
    
    var root: Root = .main
    
    let mainCoordinator: MainCoordinator
    
    init(container: AppContainer) {
        self.mainCoordinator = MainCoordinator(container: container)
    }
    
    func finishOnboarding() {
        root = .main
    }
}
