//
//  WeatherCodeMapperTests.swift
//  MeteoTests
//

import Testing
@testable import Meteo

struct WeatherCodeMapperTests {

    @Test("Коды WMO переводятся в условия по группировке из CLAUDE.md", arguments: [
        (0, WeatherCondition.clear),
        (1, .partlyCloudy), (2, .partlyCloudy), (3, .partlyCloudy),
        (45, .fog), (48, .fog),
        (51, .drizzle), (57, .drizzle),
        (61, .rain), (67, .rain),
        (71, .snow), (77, .snow),
        (80, .showers), (82, .showers),
        (95, .thunderstorm), (99, .thunderstorm),
    ])
    func mapsKnownCodes(code: Int, expected: WeatherCondition) {
        #expect(WeatherCodeMapper.condition(for: code) == expected)
    }

    @Test("Неизвестный код не роняет разбор", arguments: [4, 44, 49, 60, 79, 83, 94, 100, -1])
    func mapsUnknownCodeToUnknown(code: Int) {
        #expect(WeatherCodeMapper.condition(for: code) == .unknown)
    }
}
