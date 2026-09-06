//
//  GetSavedLocationsUseCase.swift
//  Meteo
//

import Foundation

nonisolated struct GetSavedLocationsUseCase {

    private let store: SavedLocationsStoring

    init(store: SavedLocationsStoring) {
        self.store = store
    }

    func execute() -> [Location] {
        store.savedLocations()
    }
}
