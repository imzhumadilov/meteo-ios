//
//  WeatherCondition.swift
//  Meteo
//

import Foundation

/// Погодное условие в терминах домена. Группировка кодов WMO зафиксирована
/// в `CLAUDE.md`; перевод кода в этот тип — работа маппера в `Data`.
nonisolated enum WeatherCondition: Hashable, Sendable, CaseIterable {
    case clear
    case partlyCloudy
    case fog
    case drizzle
    case rain
    case snow
    case showers
    case thunderstorm

    /// Код, которого нет в известных группах. Не сбой: API может добавить
    /// новые коды, и это не повод ронять экран.
    case unknown
}
