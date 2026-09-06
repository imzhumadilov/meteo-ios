//
//  StubURLProtocol.swift
//  MeteoTests
//

import Foundation
import Synchronization

/// Подставной транспорт: перехватывает запросы `URLSession` и отдаёт
/// заготовленный ответ, не выходя в сеть.
///
/// Отличие от подставного репозитория из юнит-тестов: здесь подменяется
/// **только транспорт**. `URLSession`, `JSONDecoder`, `HTTPClient`, DTO
/// и мапперы работают настоящие.
nonisolated final class StubURLProtocol: URLProtocol {

    nonisolated struct Stub: Sendable {
        var statusCode = 200
        var headers: [String: String] = [:]
        var body = Data()
        /// Транспортный сбой вместо ответа.
        var failure: URLError?

        static func ok(_ body: Data) -> Stub { Stub(body: body) }
        static func status(_ code: Int) -> Stub { Stub(statusCode: code) }
        static func failing(_ code: URLError.Code) -> Stub { Stub(failure: URLError(code)) }
    }

    private nonisolated struct Registry: Sendable {
        var stubs: [String: Stub] = [:]
        var requests: [String: [URLRequest]] = [:]
    }

    /// Заготовки и перехваченные запросы разложены **по идентификатору сессии**,
    /// а не в одну глобальную переменную. Иначе тесты, идущие параллельно,
    /// затирали бы ответы друг друга.
    ///
    /// `Mutex` здесь не украшение: статическое изменяемое состояние в режиме
    /// языка 6 — ошибка компиляции, и это правильный способ её закрыть,
    /// а не `nonisolated(unsafe)`.
    private static let registry = Mutex(Registry())

    private static let sessionHeader = "X-Meteo-Stub"

    /// Сессия, все запросы которой перехватывает этот протокол.
    static func makeSession(returning stub: Stub) -> StubbedSession {
        let id = UUID().uuidString
        registry.withLock { $0.stubs[id] = stub }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [sessionHeader: id]

        return StubbedSession(session: URLSession(configuration: configuration), id: id)
    }

    static func requests(for id: String) -> [URLRequest] {
        registry.withLock { $0.requests[id] ?? [] }
    }

    static func forget(_ id: String) {
        registry.withLock {
            $0.stubs[id] = nil
            $0.requests[id] = nil
        }
    }

    // MARK: - URLProtocol

    /// Принимает **любой** запрос: сессия создана только с этим протоколом,
    /// поэтому мимо него уйти нечему.
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let id = request.value(forHTTPHeaderField: Self.sessionHeader) ?? ""

        let stub = Self.registry.withLock { registry -> Stub? in
            registry.requests[id, default: []].append(self.request)
            return registry.stubs[id]
        }

        guard let stub else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        if let failure = stub.failure {
            client?.urlProtocol(self, didFailWithError: failure)
            return
        }

        guard
            let url = request.url,
            let response = HTTPURLResponse(
                url: url,
                statusCode: stub.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: stub.headers
            )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if !stub.body.isEmpty {
            client?.urlProtocol(self, didLoad: stub.body)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Сессия вместе со своим идентификатором: через него тест забирает
/// перехваченные запросы.
nonisolated struct StubbedSession {

    let session: URLSession
    let id: String

    var requests: [URLRequest] { StubURLProtocol.requests(for: id) }

    func forget() { StubURLProtocol.forget(id) }
}
