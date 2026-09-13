//
//  SavedLocationsViewModel.swift
//  Meteo
//

import Foundation

@MainActor
@Observable
final class SavedLocationsViewModel {

    /// Температура в строке города. Три случая, а не «строка или nil»:
    /// «ещё грузится» и «не удалось» выглядят по-разному.
    enum Temperature: Equatable {
        case loading
        case value(String)
        case unavailable
    }

    struct Row: Identifiable, Equatable {
        let id: Int
        let location: Location
        let temperature: Temperature
    }

    enum State: Equatable {
        case empty
        case loading([Row])
        case loaded([Row])
    }

    private(set) var state: State = .empty
    private(set) var reloadID = 0

    private let getSavedLocations: GetSavedLocationsUseCase
    private let getWeather: GetWeatherForSavedLocationsUseCase
    private let addLocation: AddSavedLocationUseCase
    private let removeLocation: RemoveSavedLocationUseCase

    init(
        getSavedLocations: GetSavedLocationsUseCase,
        getWeather: GetWeatherForSavedLocationsUseCase,
        addLocation: AddSavedLocationUseCase,
        removeLocation: RemoveSavedLocationUseCase
    ) {
        self.getSavedLocations = getSavedLocations
        self.getWeather = getWeather
        self.addLocation = addLocation
        self.removeLocation = removeLocation
    }

    func refresh() async {
        let locations = getSavedLocations.execute()

        guard !locations.isEmpty else {
            state = .empty
            return
        }

        state = .loading(locations.map { Row(id: $0.id, location: $0, temperature: .loading) })

        do {
            let weather = try await getWeather.execute()
            state = .loaded(weather.map(Self.row))
        } catch is CancellationError {
            // Экран закрыт до ответа — состояние никого не интересует.
        } catch {
            // Отказы по отдельным городам use case уже превратил в прочерки,
            // сюда доходит только неожиданное. Показываем города без температур,
            // а не пустой экран: список городов у нас есть и он верен.
            state = .loaded(locations.map { Row(id: $0.id, location: $0, temperature: .unavailable) })
        }
    }

    func add(_ location: Location) {
        addLocation.execute(location)
        reloadID += 1
    }

    func remove(_ location: Location) {
        removeLocation.execute(location)
        reloadID += 1
    }

    private static func row(_ weather: SavedLocationWeather) -> Row {
        Row(
            id: weather.id,
            location: weather.location,
            temperature: weather.temperature.map { .value(TemperatureText.text(for: $0)) } ?? .unavailable
        )
    }
}
