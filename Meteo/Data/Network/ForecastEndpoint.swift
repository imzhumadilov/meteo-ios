//
//  ForecastEndpoint.swift
//  Meteo
//

import Foundation

nonisolated enum ForecastEndpoint {

    private static let forecastDays = 7
    private static let currentFields = "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"
    private static let dailyFields = "weather_code,temperature_2m_max,temperature_2m_min"

    static func forecast(for coordinate: Coordinate) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: currentFields),
            URLQueryItem(name: "daily", value: dailyFields),
            // Времена в ответе становятся локальными для города,
            // а смещение приезжает отдельным полем.
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(forecastDays)),
        ]
        return components.url
    }
}
