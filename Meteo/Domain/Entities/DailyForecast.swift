//
//  DailyForecast.swift
//  Meteo
//

import Foundation

nonisolated struct DailyForecast: Hashable, Sendable, Identifiable {
    let date: Date
    let condition: WeatherCondition
    let minTemperature: Double
    let maxTemperature: Double

    var id: Date { date }
}
