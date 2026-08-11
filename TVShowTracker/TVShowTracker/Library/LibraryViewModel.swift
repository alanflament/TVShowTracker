//
//  LibraryViewModel.swift
//  TVShowTracker
//

import Observation

@MainActor @Observable
final class LibraryViewModel {
    private let followedMediaStore: FollowedMediaStore

    init(followedMediaStore: FollowedMediaStore) {
        self.followedMediaStore = followedMediaStore
    }

    var items: [LibraryItem] {
        followedMediaStore.items
    }

    var errorMessage: String? {
        followedMediaStore.errorMessage
    }

    func remove(_ item: LibraryItem) {
        followedMediaStore.remove(item)
    }
}
