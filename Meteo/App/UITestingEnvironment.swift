//
//  UITestingEnvironment.swift
//  Meteo
//

import Foundation
import Synchronization

/// **Единственное место, где продакшн-код знает о тестах.**
///
/// UI-тест запускает приложение с аргументом, и `DIContainer` собирает граф
/// на подставных источниках вместо сетевых. Иначе тест падал бы от плохого
/// интернета, а не от бага.
nonisolated enum UITestingEnvironment {

    static let launchArgument = "-ui-testing"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static let almaty = Location(
        id: 1_526_384,
        name: "Алматы",
        country: "Казахстан",
        region: "Алматы",
        coordinate: Coordinate(latitude: 43.25249, longitude: 76.9115)
    )
}

/// Отдаёт один и тот же город на любой запрос: тест проверяет переходы
/// между экранами, а не качество поиска.
nonisolated struct StubLocationSearching: LocationSearching {

    func searchLocations(matching query: String) async throws -> [Location] {
        [UITestingEnvironment.almaty]
    }
}

nonisolated struct StubForecastProviding: ForecastProviding {

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        Forecast(
            current: CurrentWeather(
                temperature: 23.8,
                relativeHumidity: 52,
                windSpeed: 5.6,
                condition: .clear
            ),
            daily: [],
            timeZone: TimeZone(identifier: "Asia/Almaty") ?? .gmt
        )
    }
}

/// Fake: рабочее хранилище в памяти. Начинается пустым, поэтому тест видит
/// то же пустое состояние, что и пользователь при первом запуске.
nonisolated final class InMemorySavedLocationsStore: SavedLocationsStoring, Sendable {

    private let storage = Mutex<[Location]>([])

    func savedLocations() -> [Location] {
        storage.withLock { $0 }
    }

    func add(_ location: Location) {
        storage.withLock { saved in
            guard !saved.contains(where: { $0.id == location.id }) else { return }
            saved.append(location)
        }
    }

    func remove(_ location: Location) {
        storage.withLock { saved in
            saved.removeAll { $0.id == location.id }
        }
    }
}
