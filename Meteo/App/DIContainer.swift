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
        let sources = Self.makeSources()

        searchLocations = SearchLocationsUseCase(repository: sources.locations)
        getForecast = GetForecastUseCase(repository: sources.forecasts)
        getSavedLocations = GetSavedLocationsUseCase(store: sources.store)
        getWeatherForSavedLocations = GetWeatherForSavedLocationsUseCase(
            store: sources.store,
            forecasts: sources.forecasts
        )
        addSavedLocation = AddSavedLocationUseCase(store: sources.store)
        removeSavedLocation = RemoveSavedLocationUseCase(store: sources.store)
    }

    private struct Sources {
        let locations: LocationSearching
        let forecasts: ForecastProviding
        let store: SavedLocationsStoring
    }

    /// Единственная развилка, где приложение знает о тестах.
    ///
    /// Вся ветка с заглушками — под `#if DEBUG`: в релизной сборке её нет,
    /// как нет и самих заглушек. Иначе чужой код уезжал бы пользователям
    /// и включался аргументом запуска.
    private static func makeSources() -> Sources {
        #if DEBUG
        if UITestingEnvironment.isEnabled {
            return Sources(
                locations: StubLocationSearching(),
                forecasts: StubForecastProviding(),
                store: InMemorySavedLocationsStore()
            )
        }
        #endif

        let client = HTTPClient()
        return Sources(
            locations: OpenMeteoLocationRepository(client: client),
            forecasts: OpenMeteoForecastRepository(client: client),
            store: UserDefaultsSavedLocationsStore()
        )
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
