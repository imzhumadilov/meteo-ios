//
//  WeatherCodeMapper.swift
//  Meteo
//

import Foundation

nonisolated enum WeatherCodeMapper {

    /// Группировка кодов WMO зафиксирована в `CLAUDE.md`.
    /// Неизвестный код превращается в `.unknown`, а не роняет разбор.
    static func condition(for code: Int) -> WeatherCondition {
        switch code {
        case 0: .clear
        case 1...3: .partlyCloudy
        case 45, 48: .fog
        case 51...57: .drizzle
        case 61...67: .rain
        case 71...77: .snow
        case 80...82: .showers
        case 95...99: .thunderstorm
        default: .unknown
        }
    }
}
