//
//  UserDefaultsSavedLocationsStoreTests.swift
//  MeteoTests
//

import Foundation
import Testing
@testable import Meteo

struct UserDefaultsSavedLocationsStoreTests {

    @Test("Город сохраняется и читается обратно")
    func savesAndReadsBack() {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let store = UserDefaultsSavedLocationsStore(suiteName: suite)

        store.add(Self.almaty)

        #expect(store.savedLocations().map(\.name) == ["Алматы"])
    }

    @Test("Города хранятся в порядке добавления")
    func keepsInsertionOrder() {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let store = UserDefaultsSavedLocationsStore(suiteName: suite)

        store.add(Self.almaty)
        store.add(Self.astana)

        #expect(store.savedLocations().map(\.name) == ["Алматы", "Астана"])
    }

    @Test("Повторное добавление того же города игнорируется")
    func ignoresDuplicates() {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let store = UserDefaultsSavedLocationsStore(suiteName: suite)

        store.add(Self.almaty)
        store.add(Self.almaty)

        #expect(store.savedLocations().count == 1)
    }

    @Test("Удаление убирает город из хранилища")
    func removesLocation() {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let store = UserDefaultsSavedLocationsStore(suiteName: suite)
        store.add(Self.almaty)
        store.add(Self.astana)

        store.remove(Self.almaty)

        #expect(store.savedLocations().map(\.name) == ["Астана"])
    }

    @Test("Список переживает пересоздание хранилища")
    func survivesNewStoreInstance() {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        UserDefaultsSavedLocationsStore(suiteName: suite).add(Self.almaty)

        let another = UserDefaultsSavedLocationsStore(suiteName: suite)

        #expect(another.savedLocations().map(\.name) == ["Алматы"])
    }

    @Test("Координаты и страна переживают запись и чтение")
    func keepsAllFields() throws {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let store = UserDefaultsSavedLocationsStore(suiteName: suite)

        store.add(Self.almaty)

        let restored = try #require(store.savedLocations().first)
        #expect(restored == Self.almaty)
    }

    @Test("Испорченное содержимое даёт пустой список, а не сбой")
    func returnsEmptyListForCorruptedStorage() throws {
        let suite = Self.makeSuiteName()
        defer { Self.clean(suite) }
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(Data("не json".utf8), forKey: "saved-locations")

        #expect(UserDefaultsSavedLocationsStore(suiteName: suite).savedLocations().isEmpty)
    }

    // MARK: - Фикстуры

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
        region: "Алматы",
        coordinate: Coordinate(latitude: 43.25, longitude: 76.91)
    )

    private static let astana = Location(
        id: 2,
        name: "Астана",
        country: "Казахстан",
        region: nil,
        coordinate: Coordinate(latitude: 51.16, longitude: 71.44)
    )
}
