//
//  UserDefaultsSavedLocationsStore.swift
//  Meteo
//

import Foundation

nonisolated struct UserDefaultsSavedLocationsStore: SavedLocationsStoring {

    private static let key = "saved-locations"

    /// Хранится **имя набора**, а не сам `UserDefaults`.
    ///
    /// `UserDefaults` не `Sendable`, и в режиме языка 6 держать его в
    /// `Sendable`-структуре компилятор не даёт. Сам объект потокобезопасен,
    /// поэтому он берётся в момент обращения, а в свойстве лежит только строка.
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        guard let suiteName else { return .standard }
        return UserDefaults(suiteName: suiteName) ?? .standard
    }

    func savedLocations() -> [Location] {
        guard
            let data = defaults.data(forKey: Self.key),
            let stored = try? JSONDecoder().decode([SavedLocationDTO].self, from: data)
        else {
            // Ключа нет или содержимое не разбирается — список пуст.
            // Ронять запуск приложения из-за испорченного хранилища незачем.
            return []
        }

        return stored.map(SavedLocationMapper.map)
    }

    func add(_ location: Location) {
        var locations = savedLocations()

        // Повторное добавление того же города игнорируется: в тикете случай
        // не описан, согласовано считать список множеством по `id`.
        guard !locations.contains(where: { $0.id == location.id }) else { return }

        locations.append(location)
        save(locations)
    }

    func remove(_ location: Location) {
        save(savedLocations().filter { $0.id != location.id })
    }

    private func save(_ locations: [Location]) {
        guard let data = try? JSONEncoder().encode(locations.map(SavedLocationMapper.map)) else {
            return
        }
        defaults.set(data, forKey: Self.key)
    }
}
