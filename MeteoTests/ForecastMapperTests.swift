//
//  ForecastMapperTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

struct ForecastMapperTests {

    @Test("Колоночные массивы превращаются в массив дней")
    func transposesColumnsIntoDays() throws {
        let forecast = ForecastMapper.map(try decode(Self.threeDays))

        #expect(forecast.daily.count == 3)

        let first = try #require(forecast.daily.first)
        #expect(first.condition == .clear)
        #expect(first.minTemperature == 20.5)
        #expect(first.maxTemperature == 36.7)

        let second = forecast.daily[1]
        #expect(second.condition == .partlyCloudy)
        #expect(second.minTemperature == 21.0)
        #expect(second.maxTemperature == 37.1)
    }

    @Test("Текущая погода переносится целиком")
    func mapsCurrentWeather() throws {
        let forecast = ForecastMapper.map(try decode(Self.threeDays))

        #expect(forecast.current.temperature == 23.8)
        #expect(forecast.current.relativeHumidity == 54)
        #expect(forecast.current.windSpeed == 5.6)
        #expect(forecast.current.condition == .clear)
    }

    @Test("Разная длина колонок не роняет разбор — берётся минимальная общая")
    func usesShortestColumnWhenLengthsDisagree() throws {
        let forecast = ForecastMapper.map(try decode(Self.raggedColumns))

        // time и weather_code по три элемента, temperature_2m_min — два.
        #expect(forecast.daily.count == 2)
    }

    @Test("Неразобранная дата пропускается, а не роняет экран")
    func skipsUnparsableDate() throws {
        let forecast = ForecastMapper.map(try decode(Self.brokenDate))

        #expect(forecast.daily.count == 1)
    }

    @Test("Таймзона берётся из ответа, а не из устройства")
    func usesTimeZoneFromResponse() throws {
        let forecast = ForecastMapper.map(try decode(Self.threeDays))

        #expect(forecast.timeZone.identifier == "Asia/Almaty")
    }

    @Test("Неизвестный идентификатор таймзоны заменяется смещением из ответа")
    func fallsBackToOffsetWhenIdentifierUnknown() throws {
        let forecast = ForecastMapper.map(try decode(Self.unknownTimeZone))

        #expect(forecast.timeZone.secondsFromGMT() == 18_000)
    }

    // MARK: - Фикстуры

    private func decode(_ json: String) throws -> ForecastResponseDTO {
        try JSONDecoder().decode(ForecastResponseDTO.self, from: Data(json.utf8))
    }

    private static let threeDays = """
    {
      "timezone": "Asia/Almaty",
      "utc_offset_seconds": 18000,
      "current": {
        "time": "2026-08-12T00:15",
        "temperature_2m": 23.8,
        "relative_humidity_2m": 54,
        "wind_speed_10m": 5.6,
        "weather_code": 0
      },
      "daily": {
        "time": ["2026-08-12", "2026-08-13", "2026-08-14"],
        "weather_code": [0, 2, 61],
        "temperature_2m_max": [36.7, 37.1, 36.9],
        "temperature_2m_min": [20.5, 21.0, 21.7]
      }
    }
    """

    private static let raggedColumns = """
    {
      "timezone": "Asia/Almaty",
      "utc_offset_seconds": 18000,
      "current": {
        "time": "2026-08-12T00:15",
        "temperature_2m": 23.8,
        "relative_humidity_2m": 54,
        "wind_speed_10m": 5.6,
        "weather_code": 0
      },
      "daily": {
        "time": ["2026-08-12", "2026-08-13", "2026-08-14"],
        "weather_code": [0, 2, 61],
        "temperature_2m_max": [36.7, 37.1, 36.9],
        "temperature_2m_min": [20.5, 21.0]
      }
    }
    """

    private static let brokenDate = """
    {
      "timezone": "Asia/Almaty",
      "utc_offset_seconds": 18000,
      "current": {
        "time": "2026-08-12T00:15",
        "temperature_2m": 23.8,
        "relative_humidity_2m": 54,
        "wind_speed_10m": 5.6,
        "weather_code": 0
      },
      "daily": {
        "time": ["2026-08-12", "не дата"],
        "weather_code": [0, 2],
        "temperature_2m_max": [36.7, 37.1],
        "temperature_2m_min": [20.5, 21.0]
      }
    }
    """

    private static let unknownTimeZone = """
    {
      "timezone": "Neverland/Somewhere",
      "utc_offset_seconds": 18000,
      "current": {
        "time": "2026-08-12T00:15",
        "temperature_2m": 23.8,
        "relative_humidity_2m": 54,
        "wind_speed_10m": 5.6,
        "weather_code": 0
      },
      "daily": {
        "time": ["2026-08-12"],
        "weather_code": [0],
        "temperature_2m_max": [36.7],
        "temperature_2m_min": [20.5]
      }
    }
    """
}
