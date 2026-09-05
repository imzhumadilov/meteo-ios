//
//  DIContainer.swift
//  Meteo
//

import Foundation

/// Единственное место, где слои сходятся вместе: здесь реализации из `Data`
/// подставляются в протоколы, объявленные в `Domain`.
final class DIContainer {

    private let searchLocations: SearchLocationsUseCase
    private let getForecast: GetForecastUseCase

    init() {
        let client = HTTPClient()
        searchLocations = SearchLocationsUseCase(
            repository: OpenMeteoLocationRepository(client: client)
        )
        getForecast = GetForecastUseCase(
            repository: OpenMeteoForecastRepository(client: client)
        )
    }

    func makeLocationSearchViewModel() -> LocationSearchViewModel {
        LocationSearchViewModel(searchLocations: searchLocations)
    }

    func makeForecastViewModel(for location: Location) -> ForecastViewModel {
        ForecastViewModel(location: location, getForecast: getForecast)
    }
}
