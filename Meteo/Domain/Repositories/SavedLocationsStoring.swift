//
//  SavedLocationsStoring.swift
//  Meteo
//

import Foundation

/// Хранилище сохранённых городов. Домен не знает, что за ним `UserDefaults`.
nonisolated protocol SavedLocationsStoring: Sendable {
    func savedLocations() -> [Location]
    func add(_ location: Location)
    func remove(_ location: Location)
}
