//
//  SavedLocationDTO.swift
//  Meteo
//

import Foundation

/// Форма хранения города в `UserDefaults`.
///
/// Отдельный тип нужен потому, что сущности домена по правилам проекта
/// не знают про `Codable`: формат хранения — забота слоя `Data`, и меняться
/// он должен, не задевая домен.
nonisolated struct SavedLocationDTO: Codable {
    let id: Int
    let name: String
    let country: String?
    let region: String?
    let latitude: Double
    let longitude: Double
}
