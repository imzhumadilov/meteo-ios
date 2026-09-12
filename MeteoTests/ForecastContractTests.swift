//
//  ForecastContractTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Спрашивает живой прогноз Open-Meteo: не изменилась ли форма ответа?
///
/// Температура в Алматы меняется каждый час, поэтому значения не проверяются —
/// тест, ждущий `24.6`, был бы не контрактным, а мусорным. Проверяется форма:
/// код ответа, наличие запрошенных полей и параллельность колоночных массивов.
@Suite(.enabled(if: ContractSuite.isEnabled))
struct ForecastContractTests {

    @Test("Прогноз: 200, все запрошенные поля current на месте, массивы daily параллельны")
    func forecastKeepsRequestedShape() async throws {
        let url = try #require(ForecastEndpoint.forecast(for: Self.almaty))
        let (status, data) = try await LiveAPI.get(url)

        #expect(status == 200, ContractSuite.note("прогноз ответил \(status) вместо 200"))

        let json = try LiveAPI.object(from: data)

        let current = try #require(
            json["current"] as? [String: Any],
            ContractSuite.note("в ответе нет объекта current")
        )
        for field in Self.currentFields {
            #expect(
                current[field] != nil,
                ContractSuite.note("в current пропало запрошенное поле \(field)")
            )
        }

        let daily = try #require(
            json["daily"] as? [String: Any],
            ContractSuite.note("в ответе нет объекта daily")
        )
        let lengths = LiveAPI.columnLengths(of: daily, fields: Self.dailyFields)

        for (field, length) in lengths {
            #expect(
                length != nil,
                ContractSuite.note("в daily пропал массив \(field)")
            )
        }

        let present = lengths.compactMapValues { $0 }
        #expect(
            present.values.allSatisfy { $0 > 0 },
            ContractSuite.note("массивы daily пусты: \(present)")
        )

        // Приложение складывает колонки в массив дней поэлементно.
        // Разъехавшиеся длины — не косметика, а падение маппера.
        #expect(
            Set(present.values).count <= 1,
            ContractSuite.note("массивы daily разной длины: \(present)")
        )

        do {
            _ = try JSONDecoder().decode(ForecastResponseDTO.self, from: data)
        } catch {
            Issue.record(ContractSuite.note("DTO приложения больше не декодирует ответ прогноза — \(error)"))
        }
    }

    private static let almaty = Coordinate(latitude: 43.25667, longitude: 76.92861)

    /// Ровно те поля, которые приложение просит в запросе.
    private static let currentFields = [
        "time",
        "temperature_2m",
        "relative_humidity_2m",
        "wind_speed_10m",
        "weather_code",
    ]

    private static let dailyFields = [
        "time",
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
    ]
}
