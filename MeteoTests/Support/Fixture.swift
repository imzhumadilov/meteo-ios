//
//  Fixture.swift
//  MeteoTests
//

import Foundation

/// Якорь для поиска бандла тестов: `Bundle(for:)` принимает класс,
/// а в Swift Testing нет `XCTestCase`, к которому это обычно цепляют.
private nonisolated final class FixtureBundleToken {}

/// Реальные ответы API, сохранённые файлами и закоммиченные в репозиторий.
///
/// Именно файлами, а не строками в коде: тест должен давать одинаковый
/// результат через год, а погода за это время изменится.
nonisolated enum Fixture {

    struct NotFound: Error {
        let name: String
    }

    static func data(_ name: String) throws -> Data {
        // Синхронизированные папки кладут ресурсы в корень бандла,
        // вложенность `Fixtures/` при этом не сохраняется.
        guard let url = Bundle(for: FixtureBundleToken.self).url(forResource: name, withExtension: "json") else {
            throw NotFound(name: name)
        }

        return try Data(contentsOf: url)
    }
}
