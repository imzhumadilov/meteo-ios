//
//  HTTPClient.swift
//  Meteo
//

import Foundation

nonisolated enum HTTPError: Error, Equatable {
    case invalidResponse
    case status(Int)
    case decoding
}

nonisolated struct HTTPClient: Sendable {

    private let session: URLSession

    /// Сессия внедряется, чтобы интеграционные тесты могли подменить транспорт
    /// через `URLProtocol`, не подменяя всё остальное.
    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<Response: Decodable>(_ url: URL) async throws -> Response {
        let (data, response) = try await session.data(for: URLRequest(url: url))

        guard let response = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw HTTPError.status(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw HTTPError.decoding
        }
    }
}
