//
//  ForecastProviding.swift
//  Meteo
//

import Foundation

nonisolated protocol ForecastProviding: Sendable {
    func forecast(for coordinate: Coordinate) async throws -> Forecast
}
