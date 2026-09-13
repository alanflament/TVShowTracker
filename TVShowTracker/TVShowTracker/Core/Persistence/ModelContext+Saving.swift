//
//  ModelContext+Saving.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import SwiftData

extension ModelContext {
    /// Repository mutations are synchronous and share a context with no pending UI edits.
    /// Roll back a failed write so a later save cannot persist an operation reported as failed.
    func saveChanges(_ changes: () throws -> Void) throws {
        do {
            try changes()
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
