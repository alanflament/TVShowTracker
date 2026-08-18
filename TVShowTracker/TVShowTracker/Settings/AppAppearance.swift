//
//  AppAppearance.swift
//  TVShowTracker
//
//  Created by Alan Flament on 18/08/2026.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case light
    case dark

    static let storageKey = "appAppearance"

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .automatic:
            "Automatic"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
