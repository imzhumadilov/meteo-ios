//
//  SavedLocationMapper.swift
//  Meteo
//

import Foundation

nonisolated enum SavedLocationMapper {

    static func map(_ dto: SavedLocationDTO) -> Location {
        Location(
            id: dto.id,
            name: dto.name,
            country: dto.country,
            region: dto.region,
            coordinate: Coordinate(latitude: dto.latitude, longitude: dto.longitude)
        )
    }

    static func map(_ location: Location) -> SavedLocationDTO {
        SavedLocationDTO(
            id: location.id,
            name: location.name,
            country: location.country,
            region: location.region,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}
