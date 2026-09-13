//
//  Error+SearchFailureMessage.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension Error {
    var searchFailureMessage: String {
        (self as? LocalizedError)?.errorDescription ?? "This source could not be reached."
    }
}
