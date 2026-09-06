//
//  RemoveSavedLocationUseCase.swift
//  Meteo
//

import Foundation

nonisolated struct RemoveSavedLocationUseCase {

    private let store: SavedLocationsStoring

    init(store: SavedLocationsStoring) {
        self.store = store
    }

    func execute(_ location: Location) {
        store.remove(location)
    }
}
