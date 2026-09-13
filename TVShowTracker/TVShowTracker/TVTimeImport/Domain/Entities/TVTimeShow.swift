//
//  TVTimeShow.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

nonisolated struct TVTimeShow: Hashable, Sendable {
    let title: String

    var normalizedTitle: String {
        title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }
}
