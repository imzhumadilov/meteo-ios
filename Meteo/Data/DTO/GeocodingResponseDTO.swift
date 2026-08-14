//
//  GeocodingResponseDTO.swift
//  Meteo
//

import Foundation

/// Повторяет форму ответа геокодера буквально, включая её неудобства.
///
/// `results` опционально не для красоты: при отсутствии совпадений ключа в
/// ответе нет вовсе — приходит `{"generationtime_ms": 0.12}`. Неопциональное
/// поле уронило бы декодирование на пустом результате.
nonisolated struct GeocodingResponseDTO: Decodable {
    let results: [GeocodingResultDTO]?
}

/// Имена полей повторяют API. `admin1` — неудобное имя самого Open-Meteo;
/// перевод его в понятие домена — работа маппера, а не DTO.
///
/// Моделируются только поля, которые нужны приложению. Ответ содержит ещё
/// десяток (`population`, `postcodes`, `feature_code`, …), и часть из них
/// приходит не всегда.
nonisolated struct GeocodingResultDTO: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}
