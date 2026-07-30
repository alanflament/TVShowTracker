//
//  OnboardingView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct OnboardingView: View {
    private let onFinished: () -> Void

    init(
        onFinished: @escaping () -> Void
    ) {
        self.onFinished = onFinished
    }
    
    var body: some View {
        Button(action: onFinished) {
            Text("Hello World!")
        }
    }
}
