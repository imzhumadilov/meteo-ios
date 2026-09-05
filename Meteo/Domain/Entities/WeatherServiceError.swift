//
//  WeatherServiceError.swift
//  Meteo
//

import Foundation

/// Причины неудачного обращения к сервису погоды в терминах домена.
///
/// Сетевые подробности сюда не протекают: `URLError` и коды ответа переводит
/// в эти случаи слой `Data`, а текст для человека подбирает вьюмодель.
nonisolated enum WeatherServiceError: Error, Equatable {
    case offline
    case server
    case invalidData
    case unknown
}
