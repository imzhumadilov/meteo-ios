//
//  SearchError.swift
//  Meteo
//

import Foundation

/// Причины неудачного поиска в терминах домена.
///
/// Сетевые подробности сюда не протекают: `URLError` и коды ответа переводит
/// в эти случаи репозиторий, а текст для человека подбирает вьюмодель.
nonisolated enum SearchError: Error, Equatable {
    case offline
    case server
    case invalidData
    case unknown
}
