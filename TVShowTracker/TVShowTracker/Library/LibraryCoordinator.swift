//
//  LibraryCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class LibraryCoordinator {
    enum Route: Hashable {
        case detail(itemID: String)
    }
    
    enum Sheet: String, Identifiable {
        case create
        
        var id: String { rawValue }
    }
    
    var path: [Route] = []
    var sheet: Sheet?
    
    init() {}
    
    func showItem(id: String) {
        path.append(.detail(itemID: id))
    }
    
    func createItem() {
        sheet = .create
    }
    
    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel()
    }
}
