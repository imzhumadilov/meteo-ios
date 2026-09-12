//
//  GeocodingContractTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Спрашивает живой геокодер Open-Meteo: не изменилась ли форма ответа?
///
/// Значения не проверяются. Список городов на запрос «Алматы» — не наше дело,
/// он может меняться. Проверяется только форма: коды, наличие полей, типы.
///
/// Адреса берутся из `GeocodingEndpoint`, то есть теста бьёт ровно туда,
/// куда ходит приложение. За то, что приложение собирает URL именно так,
/// отвечают интеграционные тесты; здесь — что по этому URL отвечают как прежде.
@Suite(.enabled(if: ContractSuite.isEnabled))
struct GeocodingContractTests {

    @Test("Существующий город: 200, непустой results, поля первого результата на месте")
    func existingCityReturnsUsableResults() async throws {
        let url = try #require(GeocodingEndpoint.search(query: "Алматы"))
        let (status, data) = try await LiveAPI.get(url)

        #expect(status == 200, ContractSuite.note("геокодер ответил \(status) вместо 200"))

        let json = try LiveAPI.object(from: data)
        let results = try #require(
            json["results"] as? [[String: Any]],
            ContractSuite.note("в ответе нет массива results, хотя город существует")
        )
        #expect(!results.isEmpty, ContractSuite.note("results пуст для существующего города"))

        let first = try #require(
            results.first,
            ContractSuite.note("results пуст, читать первый элемент нечего")
        )
        for field in ["id", "name", "latitude", "longitude"] {
            #expect(
                first[field] != nil,
                ContractSuite.note("у первого результата пропало поле \(field)")
            )
        }

        // Типы проверяются декодированием в тот самый DTO, которым пользуется
        // приложение: он и есть записанное ожидание о форме ответа.
        // Сообщение об ошибке декодера само называет поле, которое разъехалось.
        do {
            let decoded = try JSONDecoder().decode(GeocodingResponseDTO.self, from: data)
            #expect(
                decoded.results?.isEmpty == false,
                ContractSuite.note("DTO декодировался, но results оказался пустым или отсутствующим")
            )
        } catch {
            Issue.record(ContractSuite.note("DTO приложения больше не декодирует ответ геокодера — \(error)"))
        }
    }

    @Test("Бессмысленный запрос: 200 и ключа results в ответе НЕТ")
    func nonsenseQueryOmitsResultsKey() async throws {
        let url = try #require(GeocodingEndpoint.search(query: "zzzzzzzzqqqqqqqq"))
        let (status, data) = try await LiveAPI.get(url)

        #expect(status == 200, ContractSuite.note("геокодер ответил \(status) вместо 200"))

        let json = try LiveAPI.object(from: data)

        // Именно отсутствие ключа, а не пустой массив. На этом поведении
        // ломается неопциональный DTO, поэтому знать о его изменении
        // мы хотим раньше пользователей — в обе стороны:
        // если ключ появится с пустым массивом, приложение не сломается,
        // но опциональность в DTO станет враньём, и это стоит заметить.
        #expect(
            json["results"] == nil,
            ContractSuite.note("на пустой выдаче появился ключ results — раньше его не было")
        )
    }
}
