//
//  SavedLocationWeather.swift
//  Meteo
//

import Foundation

/// Сохранённый город вместе с текущей температурой.
nonisolated struct SavedLocationWeather: Identifiable, Hashable, Sendable {

    let location: Location

    /// `nil` — запрос по этому городу не удался.
    ///
    /// Это законное состояние данных, а не ошибка: отказ по одному городу
    /// не должен прятать остальные.
    let temperature: Double?

    var id: Int { location.id }
}
