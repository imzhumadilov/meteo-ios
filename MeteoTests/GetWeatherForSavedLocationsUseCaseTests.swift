//
//  GetWeatherForSavedLocationsUseCaseTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Stub: список городов задан заранее. Use case только читает хранилище,
/// поэтому изменяемое состояние здесь не нужно.
private struct SavedLocationsStub: SavedLocationsStoring {

    let locations: [Location]

    func savedLocations() -> [Location] { locations }
    func add(_ location: Location) {}
    func remove(_ location: Location) {}
}

private nonisolated struct ForecastResponse: Sendable {
    /// `nil` — ответить ошибкой.
    let temperature: Double?
    let delay: Duration
}

/// Spy: считает, сколько вызовов выполнялось одновременно.
///
/// Замер времени здесь был бы нестабилен, а счётчик — нет: если запросы шли
/// по очереди, максимум одновременных вызовов равен единице.
private actor ForecastSpy: ForecastProviding {

    private let responses: [Double: ForecastResponse]
    private var active = 0
    private(set) var maxConcurrent = 0

    init(responses: [Double: ForecastResponse]) {
        self.responses = responses
    }

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        active += 1
        maxConcurrent = max(maxConcurrent, active)
        defer { active -= 1 }

        let response = responses[coordinate.latitude]
        try await Task.sleep(for: response?.delay ?? .zero)

        guard let temperature = response?.temperature else {
            throw WeatherServiceError.server
        }

        return Forecast(
            current: CurrentWeather(
                temperature: temperature,
                relativeHumidity: 0,
                windSpeed: 0,
                condition: .clear
            ),
            daily: [],
            timeZone: .gmt
        )
    }
}

struct GetWeatherForSavedLocationsUseCaseTests {

    @Test("Погода для городов запрашивается параллельно, а не по очереди")
    func loadsWeatherConcurrently() async throws {
        let spy = ForecastSpy(responses: [
            Self.almaty.coordinate.latitude: ForecastResponse(temperature: 24, delay: .milliseconds(50)),
            Self.astana.coordinate.latitude: ForecastResponse(temperature: 18, delay: .milliseconds(50)),
            Self.tashkent.coordinate.latitude: ForecastResponse(temperature: 29, delay: .milliseconds(50)),
        ])

        _ = try await makeUseCase(cities: Self.cities, forecasts: spy).execute()

        #expect(await spy.maxConcurrent == Self.cities.count)
    }

    @Test("Порядок списка исходный, даже если ответы пришли в обратном")
    func keepsOriginalOrderRegardlessOfCompletionOrder() async throws {
        // Первый город отвечает дольше всех, последний — быстрее всех.
        let spy = ForecastSpy(responses: [
            Self.almaty.coordinate.latitude: ForecastResponse(temperature: 24, delay: .milliseconds(60)),
            Self.astana.coordinate.latitude: ForecastResponse(temperature: 18, delay: .milliseconds(30)),
            Self.tashkent.coordinate.latitude: ForecastResponse(temperature: 29, delay: .milliseconds(1)),
        ])

        let result = try await makeUseCase(cities: Self.cities, forecasts: spy).execute()

        #expect(result.map(\.location.name) == ["Алматы", "Астана", "Ташкент"])
        #expect(result.map(\.temperature) == [24, 18, 29])
    }

    @Test("Отказ по одному городу не прячет остальные")
    func keepsOtherCitiesWhenOneFails() async throws {
        let spy = ForecastSpy(responses: [
            Self.almaty.coordinate.latitude: ForecastResponse(temperature: 24, delay: .zero),
            Self.astana.coordinate.latitude: ForecastResponse(temperature: nil, delay: .zero),
            Self.tashkent.coordinate.latitude: ForecastResponse(temperature: 29, delay: .zero),
        ])

        let result = try await makeUseCase(cities: Self.cities, forecasts: spy).execute()

        #expect(result.count == 3)
        #expect(result.map(\.temperature) == [24, nil, 29])
    }

    @Test("Пустое хранилище не отправляет ни одного запроса")
    func doesNotRequestAnythingForEmptyStore() async throws {
        let spy = ForecastSpy(responses: [:])

        let result = try await makeUseCase(cities: [], forecasts: spy).execute()

        #expect(result.isEmpty)
        #expect(await spy.maxConcurrent == 0)
    }

    // MARK: - Фикстуры

    private func makeUseCase(
        cities: [Location],
        forecasts: some ForecastProviding
    ) -> GetWeatherForSavedLocationsUseCase {
        GetWeatherForSavedLocationsUseCase(
            store: SavedLocationsStub(locations: cities),
            forecasts: forecasts
        )
    }

    fileprivate static let almaty = Location(
        id: 1,
        name: "Алматы",
        country: "Казахстан",
        region: nil,
        coordinate: Coordinate(latitude: 43.25, longitude: 76.91)
    )

    fileprivate static let astana = Location(
        id: 2,
        name: "Астана",
        country: "Казахстан",
        region: nil,
        coordinate: Coordinate(latitude: 51.16, longitude: 71.44)
    )

    fileprivate static let tashkent = Location(
        id: 3,
        name: "Ташкент",
        country: "Узбекистан",
        region: nil,
        coordinate: Coordinate(latitude: 41.31, longitude: 69.24)
    )

    fileprivate static let cities = [almaty, astana, tashkent]
}
