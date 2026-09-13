//
//  WeatherConditionText.swift
//  Meteo
//

import Foundation

/// Текст условия для человека. Живёт в `Presentation`, а не в домене:
/// сам `WeatherCondition` — это понятие предметной области, а его русское
/// название — часть интерфейса.
extension WeatherCondition {

    var text: String {
        switch self {
        case .clear: "Ясно"
        case .partlyCloudy: "Переменная облачность"
        case .fog: "Туман"
        case .drizzle: "Морось"
        case .rain: "Дождь"
        case .snow: "Снег"
        case .showers: "Ливни"
        case .thunderstorm: "Гроза"
        case .unknown: "Нет данных"
        }
    }
}
