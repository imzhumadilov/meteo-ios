//
//  ForecastResponseDTO.swift
//  Meteo
//

import Foundation

/// Повторяет форму ответа Open-Meteo буквально, включая её неудобства:
/// колоночные массивы в `daily` и имена полей вида `temperature_2m`.
///
/// Осмысленного camelCase у таких имён нет, поэтому `CodingKeys` здесь не
/// заводятся: перевод в словарь домена целиком лежит на маппере.
nonisolated struct ForecastResponseDTO: Decodable {

    let timezone: String
    let utc_offset_seconds: Int
    let current: Current
    let daily: Daily

    nonisolated struct Current: Decodable {
        let time: String
        let temperature_2m: Double
        let relative_humidity_2m: Int
        let wind_speed_10m: Double
        let weather_code: Int
    }

    /// Колонки, а не строки: элемент с индексом i во всех массивах описывает
    /// один и тот же день. Превращение в массив структур — работа маппера.
    nonisolated struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
}
