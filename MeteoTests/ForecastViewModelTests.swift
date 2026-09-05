//
//  ForecastViewModelTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Stub: отдаёт заготовленный прогноз, вызовы не считает.
private struct ForecastStub: ForecastProviding {

    let result: Result<Forecast, any Error>

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        try result.get()
    }
}

@MainActor
struct ForecastViewModelTests {

    @Test("Успешный запрос переводит экран в состояние показа")
    func showsForecastWhenLoaded() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let forecast = try makeForecast(timeZone: timeZone)
        let viewModel = makeViewModel(returning: .success(forecast), now: try day("2026-08-12", in: timeZone))

        await viewModel.load()

        #expect(viewModel.state == .loaded(forecast))
    }

    @Test("Сетевая ошибка переводит экран в состояние ошибки с текстом")
    func showsFailureWhenRequestFails() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let viewModel = makeViewModel(
            returning: .failure(WeatherServiceError.offline),
            now: try day("2026-08-12", in: timeZone)
        )

        await viewModel.load()

        #expect(viewModel.state == .failed("Нет соединения с интернетом"))
    }

    @Test("Первый день подписан «Сегодня», остальные — днём недели с заглавной")
    func labelsFirstDayAsToday() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let forecast = try makeForecast(timeZone: timeZone)
        let viewModel = makeViewModel(returning: .success(forecast), now: try day("2026-08-12", in: timeZone))

        let rows = viewModel.dayRows(for: forecast)

        #expect(rows.map(\.title) == ["Сегодня", "Четверг"])
    }

    @Test("«Сегодня» считается по календарю города, а не устройства")
    func usesCityCalendarForToday() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let forecast = try makeForecast(timeZone: timeZone)

        // Полдень 13 августа в Алматы: сегодня — второй день прогноза,
        // хотя в UTC в этот момент ещё 13-е раннее утро.
        let noonOfSecondDay = try day("2026-08-13", in: timeZone).addingTimeInterval(12 * 60 * 60)
        let viewModel = makeViewModel(returning: .success(forecast), now: noonOfSecondDay)

        let rows = viewModel.dayRows(for: forecast)

        #expect(rows.map(\.title) == ["Среда", "Сегодня"])
    }

    @Test("Температуры округляются и показываются как минимум и максимум")
    func formatsTemperatures() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let forecast = try makeForecast(timeZone: timeZone)
        let viewModel = makeViewModel(returning: .success(forecast), now: try day("2026-08-12", in: timeZone))

        let rows = viewModel.dayRows(for: forecast)

        #expect(rows.first?.temperatures == "21° / 37°")
        #expect(viewModel.temperature(forecast.current.temperature) == "24°")
    }

    @Test("Влажность и ветер показываются с единицами")
    func formatsCurrentMetrics() async throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let forecast = try makeForecast(timeZone: timeZone)
        let viewModel = makeViewModel(returning: .success(forecast), now: try day("2026-08-12", in: timeZone))

        #expect(viewModel.humidity(forecast.current) == "Влажность 54%")
        #expect(viewModel.wind(forecast.current) == "Ветер 6 км/ч")
    }

    @Test("Повтор меняет идентификатор задачи")
    func retryChangesTaskID() throws {
        let timeZone = try #require(TimeZone(identifier: "Asia/Almaty"))
        let viewModel = makeViewModel(
            returning: .failure(WeatherServiceError.offline),
            now: try day("2026-08-12", in: timeZone)
        )
        let before = viewModel.attempt

        viewModel.retry()

        #expect(viewModel.attempt != before)
    }

    // MARK: - Фикстуры

    private func makeViewModel(
        returning result: Result<Forecast, any Error>,
        now: Date
    ) -> ForecastViewModel {
        ForecastViewModel(
            location: .almaty,
            getForecast: GetForecastUseCase(repository: ForecastStub(result: result)),
            now: { now }
        )
    }

    private func makeForecast(timeZone: TimeZone) throws -> Forecast {
        Forecast(
            current: CurrentWeather(
                temperature: 23.8,
                relativeHumidity: 54,
                windSpeed: 5.6,
                condition: .clear
            ),
            daily: [
                DailyForecast(
                    date: try day("2026-08-12", in: timeZone),
                    condition: .clear,
                    minTemperature: 20.5,
                    maxTemperature: 36.7
                ),
                DailyForecast(
                    date: try day("2026-08-13", in: timeZone),
                    condition: .partlyCloudy,
                    minTemperature: 21.0,
                    maxTemperature: 37.1
                ),
            ],
            timeZone: timeZone
        )
    }

    private func day(_ string: String, in timeZone: TimeZone) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return try #require(formatter.date(from: string))
    }
}
