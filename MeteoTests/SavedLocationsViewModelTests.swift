//
//  SavedLocationsViewModelTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

/// Stub: одна температура на все города, либо отказ.
private struct ForecastStubForList: ForecastProviding {

    let temperature: Double?

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        guard let temperature else { throw WeatherServiceError.server }

        return Forecast(
            current: CurrentWeather(
                temperature: temperature,
                relativeHumidity: 0,
                windSpeed: 0,
                condition: .clear
            ),
            daily: [],
            timeZone: .gmt
        )
    }
}

@MainActor
struct SavedLocationsViewModelTests {

    @Test("Пустое хранилище даёт пустое состояние")
    func showsEmptyStateWithoutCities() async {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let viewModel = Self.makeViewModel(suite: suite, temperature: 24)

        await viewModel.refresh()

        #expect(viewModel.state == .empty)
    }

    @Test("Города с погодой показываются с температурой")
    func showsTemperatures() async {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let viewModel = Self.makeViewModel(suite: suite, temperature: 23.8)
        viewModel.add(Self.almaty)

        await viewModel.refresh()

        #expect(viewModel.state == .loaded([
            SavedLocationsViewModel.Row(id: 1, location: Self.almaty, temperature: .value("24°")),
        ]))
    }

    @Test("Город без погоды показывается прочерком, а не ошибкой на весь экран")
    func showsDashWhenCityFails() async {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let viewModel = Self.makeViewModel(suite: suite, temperature: nil)
        viewModel.add(Self.almaty)

        await viewModel.refresh()

        #expect(viewModel.state == .loaded([
            SavedLocationsViewModel.Row(id: 1, location: Self.almaty, temperature: .unavailable),
        ]))
    }

    @Test("Добавление города просит перезагрузку")
    func addRequestsReload() {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let viewModel = Self.makeViewModel(suite: suite, temperature: 24)
        let before = viewModel.reloadID

        viewModel.add(Self.almaty)

        #expect(viewModel.reloadID != before)
    }

    @Test("Удаление убирает город из хранилища")
    func removeDropsCity() async {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let viewModel = Self.makeViewModel(suite: suite, temperature: 24)
        viewModel.add(Self.almaty)

        viewModel.remove(Self.almaty)
        await viewModel.refresh()

        #expect(viewModel.state == .empty)
    }

    // MARK: - Фикстуры

    private static func makeViewModel(suite: String, temperature: Double?) -> SavedLocationsViewModel {
        let store = UserDefaultsSavedLocationsStore(suiteName: suite)

        return SavedLocationsViewModel(
            getSavedLocations: GetSavedLocationsUseCase(store: store),
            getWeather: GetWeatherForSavedLocationsUseCase(
                store: store,
                forecasts: ForecastStubForList(temperature: temperature)
            ),
            addLocation: AddSavedLocationUseCase(store: store),
            removeLocation: RemoveSavedLocationUseCase(store: store)
        )
    }

    private static func makeSuiteName() -> String {
        "meteo.tests.\(UUID().uuidString)"
    }

    private static func clean(_ suite: String) {
        UserDefaults().removePersistentDomain(forName: suite)
    }

    private static let almaty = Location(
        id: 1,
        name: "Алматы",
        country: "Казахстан",
        region: nil,
        coordinate: Coordinate(latitude: 43.25, longitude: 76.91)
    )
}
