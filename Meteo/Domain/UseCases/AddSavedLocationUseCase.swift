//
//  AddSavedLocationUseCase.swift
//  Meteo
//

import Foundation

nonisolated struct AddSavedLocationUseCase {

    private let store: SavedLocationsStoring

    init(store: SavedLocationsStoring) {
        self.store = store
    }

    func execute(_ location: Location) {
        store.add(location)
    }
}
