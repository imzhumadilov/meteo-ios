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
    private let getSavedLocations: GetSavedLocationsUseCase
    private let getWeatherForSavedLocations: GetWeatherForSavedLocationsUseCase
    private let addSavedLocation: AddSavedLocationUseCase
    private let removeSavedLocation: RemoveSavedLocationUseCase

    init() {
        let client = HTTPClient()
        let forecasts = OpenMeteoForecastRepository(client: client)
        let store = UserDefaultsSavedLocationsStore()

        searchLocations = SearchLocationsUseCase(
            repository: OpenMeteoLocationRepository(client: client)
        )
        getForecast = GetForecastUseCase(repository: forecasts)
        getSavedLocations = GetSavedLocationsUseCase(store: store)
        getWeatherForSavedLocations = GetWeatherForSavedLocationsUseCase(
            store: store,
            forecasts: forecasts
        )
        addSavedLocation = AddSavedLocationUseCase(store: store)
        removeSavedLocation = RemoveSavedLocationUseCase(store: store)
    }

    func makeSavedLocationsViewModel() -> SavedLocationsViewModel {
        SavedLocationsViewModel(
            getSavedLocations: getSavedLocations,
            getWeather: getWeatherForSavedLocations,
            addLocation: addSavedLocation,
            removeLocation: removeSavedLocation
        )
    }

    func makeLocationSearchViewModel() -> LocationSearchViewModel {
        LocationSearchViewModel(searchLocations: searchLocations)
    }

    func makeForecastViewModel(for location: Location) -> ForecastViewModel {
        ForecastViewModel(location: location, getForecast: getForecast)
    }
}
