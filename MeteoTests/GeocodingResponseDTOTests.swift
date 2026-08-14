//
//  GeocodingResponseDTOTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

struct GeocodingResponseDTOTests {

    @Test("Ответ без ключа results декодируется, а не падает")
    func decodesResponseWithoutResultsKey() throws {
        let json = Data(#"{"generationtime_ms": 0.12433529}"#.utf8)

        let response = try JSONDecoder().decode(GeocodingResponseDTO.self, from: json)

        #expect(response.results == nil)
    }

    @Test("Обычный ответ декодируется вместе с необязательными полями")
    func decodesResponseWithResults() throws {
        let json = Data(
            #"""
            {
              "results": [
                {
                  "id": 1526384,
                  "name": "Алматы",
                  "latitude": 43.25249,
                  "longitude": 76.9115,
                  "elevation": 783.0,
                  "feature_code": "PPLA",
                  "country_code": "KZ",
                  "timezone": "Asia/Almaty",
                  "population": 1977011,
                  "country": "Казахстан",
                  "admin1": "Алматы"
                }
              ],
              "generationtime_ms": 1.237154
            }
            """#.utf8
        )

        let response = try JSONDecoder().decode(GeocodingResponseDTO.self, from: json)

        let result = try #require(response.results?.first)
        #expect(result.id == 1_526_384)
        #expect(result.name == "Алматы")
        #expect(result.latitude == 43.25249)
        #expect(result.longitude == 76.9115)
        #expect(result.country == "Казахстан")
        #expect(result.admin1 == "Алматы")
    }

    @Test("Результат без страны и региона декодируется")
    func decodesResultWithoutCountryAndRegion() throws {
        let json = Data(
            #"""
            {"results": [{"id": 1, "name": "Алма", "latitude": 1.5, "longitude": 2.5}]}
            """#.utf8
        )

        let response = try JSONDecoder().decode(GeocodingResponseDTO.self, from: json)

        let result = try #require(response.results?.first)
        #expect(result.country == nil)
        #expect(result.admin1 == nil)
    }
}
