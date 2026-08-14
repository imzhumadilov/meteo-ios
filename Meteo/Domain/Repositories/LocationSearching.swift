//
//  LocationSearching.swift
//  Meteo
//

import Foundation

/// Протокол объявлен в домене, а реализован в `Data` — это и есть инверсия
/// зависимости: ядро задаёт форму, внешний слой ей подчиняется.
nonisolated protocol LocationSearching: Sendable {
    func searchLocations(matching query: String) async throws -> [Location]
}
