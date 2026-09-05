//
//  ForecastMapper.swift
//  Meteo
//

import Foundation

nonisolated enum ForecastMapper {

    static func map(_ dto: ForecastResponseDTO) -> Forecast {
        let timeZone = TimeZone(identifier: dto.timezone)
            ?? TimeZone(secondsFromGMT: dto.utc_offset_seconds)
            ?? .gmt

        return Forecast(
            current: current(from: dto.current),
            daily: daily(from: dto.daily, timeZone: timeZone),
            timeZone: timeZone
        )
    }

    private static func current(from dto: ForecastResponseDTO.Current) -> CurrentWeather {
        CurrentWeather(
            temperature: dto.temperature_2m,
            relativeHumidity: dto.relative_humidity_2m,
            windSpeed: dto.wind_speed_10m,
            condition: WeatherCodeMapper.condition(for: dto.weather_code)
        )
    }

    /// Транспонирование колонок в массив дней.
    private static func daily(from dto: ForecastResponseDTO.Daily, timeZone: TimeZone) -> [DailyForecast] {
        // В норме длины совпадают, но полагаться на это нельзя: расхождение
        // не должно ронять экран, поэтому берётся минимальная общая длина.
        let count = min(
            min(dto.time.count, dto.weather_code.count),
            min(dto.temperature_2m_max.count, dto.temperature_2m_min.count)
        )

        let formatter = dayFormatter(for: timeZone)

        return (0..<count).compactMap { index in
            guard let date = formatter.date(from: dto.time[index]) else { return nil }

            return DailyForecast(
                date: date,
                condition: WeatherCodeMapper.condition(for: dto.weather_code[index]),
                minTemperature: dto.temperature_2m_min[index],
                maxTemperature: dto.temperature_2m_max[index]
            )
        }
    }

    private static func dayFormatter(for timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        // Open-Meteo присылает "2026-08-12" — это не полный ISO 8601,
        // и ISO8601DateFormatter со стандартными настройками вернёт nil.
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
    }
}
