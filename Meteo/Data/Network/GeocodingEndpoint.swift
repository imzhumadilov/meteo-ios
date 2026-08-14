//
//  GeocodingEndpoint.swift
//  Meteo
//

import Foundation

/// Сборка адресов геокодера Open-Meteo. Вынесена из репозитория отдельно,
/// чтобы итоговый URL можно было проверить тестом, не поднимая сеть.
nonisolated enum GeocodingEndpoint {

    private static let resultLimit = 10

    static func search(query: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "geocoding-api.open-meteo.com"
        components.path = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: String(resultLimit)),
            URLQueryItem(name: "language", value: "ru"),
            URLQueryItem(name: "format", value: "json"),
        ]
        return components.url
    }
}
