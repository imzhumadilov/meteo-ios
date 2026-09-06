//
//  GeocodingIntegrationTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Весь путь поиска города, кроме сети: сборка URL, настоящий `URLSession`,
/// настоящий декодер, DTO и маппер.
struct GeocodingIntegrationTests {

    @Test("URL запроса собирается с нужным хостом, путём и параметрами")
    func buildsSearchRequestURL() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("geocoding_empty")))
        defer { stubbed.forget() }

        _ = try await makeRepository(stubbed).searchLocations(matching: "алма")

        let request = try #require(stubbed.requests.first)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "geocoding-api.open-meteo.com")
        #expect(components.path == "/v1/search")

        // Порядок параметров не важен, наличие и значения — важны.
        #expect(queryItems(components) == [
            "name": "алма",
            "count": "10",
            "language": "ru",
            "format": "json",
        ])
    }

    @Test("Фикстура реального ответа превращается в сущности домена")
    func mapsRealResponseToLocations() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("geocoding_almaty")))
        defer { stubbed.forget() }

        let locations = try await makeRepository(stubbed).searchLocations(matching: "Алматы")

        let first = try #require(locations.first)
        #expect(first.id == 1_526_384)
        #expect(first.name == "Алматы")
        #expect(first.country == "Казахстан")
        #expect(first.region == "Алматы")
        #expect(first.coordinate == Coordinate(latitude: 43.25249, longitude: 76.9115))
    }

    @Test("Ответ без ключа results даёт пустой список, а не ошибку разбора")
    func returnsEmptyListWhenResultsKeyIsMissing() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("geocoding_empty")))
        defer { stubbed.forget() }

        let locations = try await makeRepository(stubbed).searchLocations(matching: "zzzzzz")

        #expect(locations.isEmpty)
    }

    @Test("Код 500 превращается в ошибку домена, а не протекает наружу как есть")
    func mapsServerErrorToDomainError() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .status(500))
        defer { stubbed.forget() }

        await #expect(throws: WeatherServiceError.server) {
            _ = try await makeRepository(stubbed).searchLocations(matching: "алма")
        }
    }

    private func makeRepository(_ stubbed: StubbedSession) -> OpenMeteoLocationRepository {
        OpenMeteoLocationRepository(client: HTTPClient(session: stubbed.session))
    }

    private func queryItems(_ components: URLComponents) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
    }
}
