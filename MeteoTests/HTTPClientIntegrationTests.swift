//
//  HTTPClientIntegrationTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Настоящие `URLSession`, `JSONDecoder` и `HTTPClient`. Подменён только
/// транспорт, поэтому проверяется всё, что лежит выше него.
struct HTTPClientIntegrationTests {

    @Test("Ответ 200 декодируется в ожидаемый тип")
    func decodesSuccessfulResponse() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("geocoding_almaty")))
        defer { stubbed.forget() }

        let response: GeocodingResponseDTO = try await HTTPClient(session: stubbed.session).get(Self.url)

        #expect(response.results?.count == 1)
        #expect(response.results?.first?.name == "Алматы")
    }

    @Test("Коды ответа вне 2xx превращаются в HTTPError.status", arguments: [404, 500, 503])
    func mapsErrorStatusCodes(code: Int) async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .status(code))
        defer { stubbed.forget() }

        await #expect(throws: HTTPError.status(code)) {
            let _: GeocodingResponseDTO = try await HTTPClient(session: stubbed.session).get(Self.url)
        }
    }

    @Test("Невалидный JSON превращается в HTTPError.decoding")
    func mapsInvalidJSONToDecodingError() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(Data("не json".utf8)))
        defer { stubbed.forget() }

        await #expect(throws: HTTPError.decoding) {
            let _: GeocodingResponseDTO = try await HTTPClient(session: stubbed.session).get(Self.url)
        }
    }

    @Test("Пустое тело ответа превращается в HTTPError.decoding")
    func mapsEmptyBodyToDecodingError() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(Data()))
        defer { stubbed.forget() }

        await #expect(throws: HTTPError.decoding) {
            let _: GeocodingResponseDTO = try await HTTPClient(session: stubbed.session).get(Self.url)
        }
    }

    @Test("Транспортный сбой доходит как URLError, а не как ошибка разбора")
    func propagatesTransportFailure() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .failing(.notConnectedToInternet))
        defer { stubbed.forget() }

        await #expect(throws: URLError.self) {
            let _: GeocodingResponseDTO = try await HTTPClient(session: stubbed.session).get(Self.url)
        }
    }

    @Test("Запрос уходит по тому адресу, который дали клиенту")
    func sendsRequestToGivenURL() async throws {
        let stubbed = StubURLProtocol.makeSession(returning: .ok(try Fixture.data("geocoding_empty")))
        defer { stubbed.forget() }

        let _: GeocodingResponseDTO = try await HTTPClient(session: stubbed.session).get(Self.url)

        #expect(stubbed.requests.count == 1)
        #expect(stubbed.requests.first?.url == Self.url)
    }

    private static let url = URL(string: "https://example.test/v1/search?name=alma")!
}
