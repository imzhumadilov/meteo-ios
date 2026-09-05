//
//  ForecastViewModel.swift
//  Meteo
//

import Foundation

@MainActor
@Observable
final class ForecastViewModel {

    enum State: Equatable {
        case loading
        case loaded(Forecast)
        case failed(String)
    }

    /// Готовая строка таблицы прогноза. Подписи считает вьюмодель, а не вьюха:
    /// логику внутри `body` не достать юнит-тестом.
    struct DayRow: Identifiable, Equatable {
        let id: Date
        let title: String
        let condition: String
        let temperatures: String
    }

    let location: Location
    private(set) var state: State = .loading
    private(set) var attempt = 0

    private let getForecast: GetForecastUseCase
    private let now: @Sendable () -> Date

    init(
        location: Location,
        getForecast: GetForecastUseCase,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.location = location
        self.getForecast = getForecast
        self.now = now
    }

    func load() async {
        state = .loading

        do {
            let forecast = try await getForecast.execute(for: location.coordinate)
            state = .loaded(forecast)
        } catch is CancellationError {
            // Экран закрыт до ответа — состояние никого не интересует.
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func retry() {
        attempt += 1
    }

    // MARK: - Форматирование

    func temperature(_ value: Double) -> String {
        "\(Int(value.rounded()))°"
    }

    func humidity(_ weather: CurrentWeather) -> String {
        "Влажность \(weather.relativeHumidity)%"
    }

    func wind(_ weather: CurrentWeather) -> String {
        "Ветер \(Int(weather.windSpeed.rounded())) км/ч"
    }

    /// Первый день подписан «Сегодня» — но не по индексу, а сравнением дат
    /// в календаре **города**. Для города в далёкой таймзоне календарь
    /// устройства дал бы другой день.
    func dayRows(for forecast: Forecast) -> [DayRow] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = forecast.timeZone

        let weekday = DateFormatter()
        weekday.locale = Locale(identifier: "ru_RU")
        weekday.timeZone = forecast.timeZone
        weekday.dateFormat = "EEEE"

        let today = now()

        return forecast.daily.map { day in
            DayRow(
                id: day.date,
                title: calendar.isDate(day.date, inSameDayAs: today)
                    ? "Сегодня"
                    : weekday.string(from: day.date).capitalizedFirstLetter,
                condition: day.condition.text,
                temperatures: "\(temperature(day.minTemperature)) / \(temperature(day.maxTemperature))"
            )
        }
    }

    private static func message(for error: any Error) -> String {
        switch error as? WeatherServiceError {
        case .offline: "Нет соединения с интернетом"
        case .server: "Сервер не отвечает"
        case .invalidData: "Не удалось прочитать ответ сервера"
        case .unknown, .none: "Не удалось загрузить прогноз"
        }
    }
}

private extension String {

    /// `DateFormatter` отдаёт день недели в русской локали со строчной буквы.
    var capitalizedFirstLetter: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
