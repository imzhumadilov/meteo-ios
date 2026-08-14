//
//  LocationMapperTests.swift
//  MeteoTests
//

import Testing
@testable import Meteo

struct LocationMapperTests {

    @Test("Результат геокодера превращается в сущность домена")
    func mapsResultToDomainEntity() {
        let dto = GeocodingResultDTO(
            id: 1_526_384,
            name: "Алматы",
            latitude: 43.25249,
            longitude: 76.9115,
            country: "Казахстан",
            admin1: "Алматы"
        )

        let location = LocationMapper.map(dto)

        #expect(location.id == 1_526_384)
        #expect(location.name == "Алматы")
        #expect(location.country == "Казахстан")
        #expect(location.region == "Алматы")
        #expect(location.coordinate == Coordinate(latitude: 43.25249, longitude: 76.9115))
    }

    @Test("Отсутствующий ключ results даёт пустой список, а не ошибку")
    func mapsMissingResultsToEmptyList() {
        #expect(LocationMapper.map(GeocodingResponseDTO(results: nil)).isEmpty)
    }

    @Test("Пустой массив results тоже даёт пустой список")
    func mapsEmptyResultsToEmptyList() {
        #expect(LocationMapper.map(GeocodingResponseDTO(results: [])).isEmpty)
    }

    @Test("Отсутствующие страна и регион переносятся как отсутствующие")
    func keepsMissingCountryAndRegionAbsent() {
        let dto = GeocodingResultDTO(
            id: 1,
            name: "Безымянное",
            latitude: 0,
            longitude: 0,
            country: nil,
            admin1: nil
        )

        let location = LocationMapper.map(dto)

        #expect(location.country == nil)
        #expect(location.region == nil)
    }
}
