//
//  ContractTesting.swift
//  MeteoTests
//

import Foundation
import Testing

/// Контрактные тесты ходят в живой Open-Meteo, поэтому включаются только
/// в своём прогоне: план `Contract` задаёт переменную `CONTRACT`, планы
/// `Fast` и `Full` — нет.
///
/// За разделением стоит правило: тесты, зависящие от внешних систем, отделены
/// от тестов, зависящих только от нашего кода. Иначе первые расшатывают
/// доверие ко вторым, и в итоге не запускают никакие.
nonisolated enum ContractSuite {

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["CONTRACT"] == "1"
    }

    /// Начало каждого сообщения о падении.
    ///
    /// Человек, увидевший красный контрактный тест через полгода, должен
    /// понять с первой строки: чинить надо не наш код.
    private static let preamble = """
        КОНТРАКТ ИЗМЕНИЛСЯ. Open-Meteo вернул не то, что ожидает приложение.

        Это НЕ баг в коде и НЕ поломка теста — изменился чужой API. \
        Чинится правкой DTO и маппера в слое Data, а не подгонкой этой проверки. \
        Если сеть недоступна, тест падает иначе — на самом запросе.
        """

    static func note(_ detail: String) -> Comment {
        Comment(rawValue: "\(preamble)\n\nЧто именно разошлось: \(detail)")
    }
}

/// Настоящая сеть, без подмены `URLProtocol`: в контрактном тесте она нужна
/// по существу — весь смысл в том, чтобы спросить живой сервер.
nonisolated enum LiveAPI {

    static func get(_ url: URL) async throws -> (status: Int, data: Data) {
        let configuration = URLSessionConfiguration.ephemeral
        // Закэшированный ответ сделал бы контрактный тест лжецом: он бы
        // подтверждал форму, которой на сервере уже нет.
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20

        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }

        let (data, response) = try await session.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        return (status, data)
    }

    static func object(from data: Data) throws -> [String: Any] {
        let parsed = try JSONSerialization.jsonObject(with: data)
        guard let object = parsed as? [String: Any] else {
            throw ContractFailure.notAnObject
        }
        return object
    }

    /// Длины колоночных массивов `daily` по именам полей.
    ///
    /// Приложение складывает их в массив дней поэлементно, поэтому
    /// разъехавшиеся длины — это не косметика, а падение маппера.
    static func columnLengths(
        of daily: [String: Any],
        fields: [String]
    ) -> [String: Int?] {
        var lengths: [String: Int?] = [:]
        for field in fields {
            lengths[field] = (daily[field] as? [Any])?.count
        }
        return lengths
    }
}

nonisolated enum ContractFailure: Error {
    case notAnObject
}
