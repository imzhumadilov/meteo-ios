//
//  DIContainer.swift
//  Meteo
//

import Foundation

/// Единственное место, где слои сходятся вместе: здесь реализация из `Data`
/// подставляется в протокол, объявленный в `Domain`.
final class DIContainer {

    private let searchLocations: SearchLocationsUseCase

    init() {
        let repository = OpenMeteoLocationRepository(client: HTTPClient())
        searchLocations = SearchLocationsUseCase(repository: repository)
    }

    func makeLocationSearchViewModel() -> LocationSearchViewModel {
        LocationSearchViewModel(searchLocations: searchLocations)
    }
}
