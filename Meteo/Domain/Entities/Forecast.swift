//
//  Forecast.swift
//  Meteo
//

import Foundation

nonisolated struct Forecast: Hashable, Sendable {
    let current: CurrentWeather
    let daily: [DailyForecast]

    /// Таймзона города, а не устройства.
    ///
    /// Запрос уходит с `timezone=auto`, то есть все времена в ответе локальные
    /// для города. Без этого поля подпись дня недели считалась бы календарём
    /// устройства и для далёких городов уезжала бы на сутки.
    let timeZone: TimeZone
}
