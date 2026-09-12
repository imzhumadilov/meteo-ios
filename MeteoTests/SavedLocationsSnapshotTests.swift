//
//  SavedLocationsSnapshotTests.swift
//  MeteoTests
//

import Testing
@testable import Meteo

@MainActor
@Suite(.enabled(if: SnapshotSuite.isEnabled))
struct SavedLocationsSnapshotTests {

    @Test("Пусто")
    func empty() throws {
        try Snapshot.assert(makeView(state: .empty), named: "saved-empty")
    }

    @Test("Загрузка")
    func loading() throws {
        try Snapshot.assert(makeView(state: .loading(rows(temperature: .loading))), named: "saved-loading")
    }

    @Test("Показ")
    func loaded() throws {
        try Snapshot.assert(
            makeView(state: .loaded([
                row(SnapshotData.almaty, .value("24°")),
                row(SnapshotData.astana, .value("18°")),
                row(SnapshotData.tashkent, .value("29°")),
            ])),
            named: "saved-loaded"
        )
    }

    @Test("Частичный отказ: у города прочерк вместо температуры")
    func partialFailure() throws {
        try Snapshot.assert(
            makeView(state: .loaded([
                row(SnapshotData.almaty, .value("24°")),
                row(SnapshotData.astana, .unavailable),
                row(SnapshotData.tashkent, .value("29°")),
            ])),
            named: "saved-partial-failure"
        )
    }

    private func rows(temperature: SavedLocationsViewModel.Temperature) -> [SavedLocationsViewModel.Row] {
        SnapshotData.cities.map { row($0, temperature) }
    }

    private func row(
        _ location: Location,
        _ temperature: SavedLocationsViewModel.Temperature
    ) -> SavedLocationsViewModel.Row {
        SavedLocationsViewModel.Row(id: location.id, location: location, temperature: temperature)
    }

    private func makeView(state: SavedLocationsViewModel.State) -> SavedLocationsView {
        let store = IdleSavedLocationsStoring()

        return SavedLocationsView(
            viewModel: SavedLocationsViewModel(
                frozenAt: state,
                getSavedLocations: GetSavedLocationsUseCase(store: store),
                getWeather: GetWeatherForSavedLocationsUseCase(
                    store: store,
                    forecasts: IdleForecastProviding()
                ),
                addLocation: AddSavedLocationUseCase(store: store),
                removeLocation: RemoveSavedLocationUseCase(store: store)
            ),
            makeSearchViewModel: {
                LocationSearchViewModel(
                    searchLocations: SearchLocationsUseCase(repository: IdleLocationSearching())
                )
            },
            makeForecastViewModel: { location in
                ForecastViewModel(
                    location: location,
                    getForecast: GetForecastUseCase(repository: IdleForecastProviding())
                )
            }
        )
    }
}
