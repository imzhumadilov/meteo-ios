//
//  ForecastIntegrationTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

struct ForecastIntegrationTests {

    @Test("URL запроса собирается с нужным хостом, путём и параметрами")
    func buildsForecastRequestURL() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("forecast_almaty")))
        defer { stubbed.forget() }

        _ = try await makeRepository(stubbed).forecast(for: Self.almaty)

        let request = try #require(stubbed.requests.first)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "api.open-meteo.com")
        #expect(components.path == "/v1/forecast")

        #expect(queryItems(components) == [
            "latitude": "43.25",
            "longitude": "76.95",
            "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
            "daily": "weather_code,temperature_2m_max,temperature_2m_min",
            "timezone": "auto",
            "forecast_days": "7",
        ])
    }

    @Test("Колоночные массивы из реального ответа становятся массивом дней")
    func transposesRealResponseIntoDays() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("forecast_almaty")))
        defer { stubbed.forget() }

        let forecast = try await makeRepository(stubbed).forecast(for: Self.almaty)

        #expect(forecast.daily.count == 7)

        let first = try #require(forecast.daily.first)
        #expect(first.condition == .partlyCloudy)
        #expect(first.minTemperature == 14.2)
        #expect(first.maxTemperature == 28.1)

        let second = forecast.daily[1]
        #expect(second.minTemperature == 17.7)
        #expect(second.maxTemperature == 29.0)
    }

    @Test("Текущая погода из реального ответа переносится целиком")
    func mapsCurrentWeather() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("forecast_almaty")))
        defer { stubbed.forget() }

        let forecast = try await makeRepository(stubbed).forecast(for: Self.almaty)

        #expect(forecast.current.temperature == 17.9)
        #expect(forecast.current.relativeHumidity == 40)
        #expect(forecast.current.windSpeed == 1.8)
        #expect(forecast.current.condition == .clear)
    }

    @Test("Таймзона берётся из ответа, а не из устройства")
    func usesTimeZoneFromResponse() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("forecast_almaty")))
        defer { stubbed.forget() }

        let forecast = try await makeRepository(stubbed).forecast(for: Self.almaty)

        #expect(forecast.timeZone.identifier == "Asia/Almaty")
    }

    @Test("Битый JSON превращается в ошибку домена о нечитаемом ответе")
    func mapsBrokenJSONToDomainError() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(Data("{".utf8)))
        defer { stubbed.forget() }

        await #expect(throws: WeatherServiceError.invalidData) {
            _ = try await makeRepository(stubbed).forecast(for: Self.almaty)
        }
    }

    private func makeRepository(_ stubbed: StubbedSession) -> OpenMeteoForecastRepository {
        OpenMeteoForecastRepository(client: HTTPClient(session: stubbed.session))
    }

    private func queryItems(_ components: URLComponents) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
    }

    private static let almaty = Coordinate(latitude: 43.25, longitude: 76.95)
}
