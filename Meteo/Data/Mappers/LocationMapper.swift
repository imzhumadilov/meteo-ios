//
//  LocationMapper.swift
//  Meteo
//

import Foundation

nonisolated enum LocationMapper {

    /// Отсутствующий `results` — это пустой список, а не ошибка: геокодер так
    /// сообщает «ничего не нашлось».
    static func map(_ response: GeocodingResponseDTO) -> [Location] {
        (response.results ?? []).map(map)
    }

    static func map(_ dto: GeocodingResultDTO) -> Location {
        Location(
            id: dto.id,
            name: dto.name,
            country: dto.country,
            region: dto.admin1,
            coordinate: Coordinate(latitude: dto.latitude, longitude: dto.longitude)
        )
    }
}
