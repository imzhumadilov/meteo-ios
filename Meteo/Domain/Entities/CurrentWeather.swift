//
//  CurrentWeather.swift
//  Meteo
//

import Foundation

nonisolated struct CurrentWeather: Hashable, Sendable {
    let temperature: Double
    let relativeHumidity: Int
    let windSpeed: Double
    let condition: WeatherCondition
}
