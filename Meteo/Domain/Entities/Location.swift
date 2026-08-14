//
//  Location.swift
//  Meteo
//

import Foundation

/// Населённый пункт в терминах домена.
///
/// `country` и `region` необязательны: геокодер Open-Meteo не присылает ключ,
/// если значения нет, — и делает это не только с `results`.
nonisolated struct Location: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let country: String?
    let region: String?
    let coordinate: Coordinate
}
