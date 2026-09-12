//
//  SnapshotFixtures.swift
//  MeteoTests
//

import Foundation
@testable import Meteo

// Подставные зависимости для снапшотов: экран рендерится в заданном состоянии
// и до сети дело не доходит, поэтому реализации пустые.

nonisolated struct IdleLocationSearching: LocationSearching {
    func searchLocations(matching query: String) async throws -> [Location] { [] }
}

nonisolated struct IdleForecastProviding: ForecastProviding {
    func forecast(for coordinate: Coordinate) async throws -> Forecast { throw CancellationError() }
}

nonisolated struct IdleSavedLocationsStoring: SavedLocationsStoring {
    func savedLocations() -> [Location] { [] }
    func add(_ location: Location) {}
    func remove(_ location: Location) {}
}

nonisolated enum SnapshotData {

    static let almaty = Location(
        id: 1,
        name: "Алматы",
        country: "Казахстан",
        region: "Алматы",
        coordinate: Coordinate(latitude: 43.25, longitude: 76.91)
    )

    static let astana = Location(
        id: 2,
        name: "Астана",
        country: "Казахстан",
        region: nil,
        coordinate: Coordinate(latitude: 51.16, longitude: 71.44)
    )

    static let tashkent = Location(
        id: 3,
        name: "Ташкент",
        country: "Узбекистан",
        region: "Ташкент",
        coordinate: Coordinate(latitude: 41.31, longitude: 69.24)
    )

    static let cities = [almaty, astana, tashkent]

    /// Даты заданы явно, чтобы подписи дней не зависели от дня прогона.
    static let forecast = Forecast(
        current: CurrentWeather(
            temperature: 23.8,
            relativeHumidity: 52,
            windSpeed: 5.6,
            condition: .clear
        ),
        daily: days,
        timeZone: TimeZone(identifier: "Asia/Almaty") ?? .gmt
    )

    static let referenceDate = day("2026-09-07")

    private static let days: [DailyForecast] = [
        DailyForecast(date: day("2026-09-07"), condition: .clear, minTemperature: 13, maxTemperature: 27),
        DailyForecast(date: day("2026-09-08"), condition: .partlyCloudy, minTemperature: 15, maxTemperature: 28),
        DailyForecast(date: day("2026-09-09"), condition: .drizzle, minTemperature: 19, maxTemperature: 30),
        DailyForecast(date: day("2026-09-10"), condition: .rain, minTemperature: 16, maxTemperature: 30),
        DailyForecast(date: day("2026-09-11"), condition: .clear, minTemperature: 18, maxTemperature: 32),
        DailyForecast(date: day("2026-09-12"), condition: .snow, minTemperature: 18, maxTemperature: 33),
        DailyForecast(date: day("2026-09-13"), condition: .thunderstorm, minTemperature: 19, maxTemperature: 33),
    ]

    private static func day(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Almaty") ?? .gmt
        return formatter.date(from: string) ?? Date(timeIntervalSince1970: 0)
    }
}
