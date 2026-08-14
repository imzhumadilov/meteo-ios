//
//  SearchLocationsUseCaseTests.swift
//  MeteoTests
//

import Testing
@testable import Meteo

/// Spy: запоминает, с чем его звали. Актор — чтобы не понадобилось
/// `@unchecked Sendable` ради изменяемого состояния.
private actor LocationSearchSpy: LocationSearching {

    private(set) var receivedQueries: [String] = []
    private var result: Result<[Location], any Error> = .success([])

    init(returning result: Result<[Location], any Error> = .success([])) {
        self.result = result
    }

    func searchLocations(matching query: String) async throws -> [Location] {
        receivedQueries.append(query)
        return try result.get()
    }
}

struct SearchLocationsUseCaseTests {

    @Test("Запрос короче двух символов не доходит до репозитория")
    func doesNotReachRepositoryForShortQuery() async throws {
        let spy = LocationSearchSpy(returning: .success([.almaty]))
        let useCase = SearchLocationsUseCase(repository: spy)

        let locations = try await useCase.execute(query: "а")

        #expect(locations.isEmpty)
        #expect(await spy.receivedQueries.isEmpty)
    }

    @Test("Запрос из одних пробелов тоже не доходит до репозитория")
    func doesNotReachRepositoryForWhitespaceQuery() async throws {
        let spy = LocationSearchSpy()
        let useCase = SearchLocationsUseCase(repository: spy)

        _ = try await useCase.execute(query: "   ")

        #expect(await spy.receivedQueries.isEmpty)
    }

    @Test("Запрос от двух символов уходит в репозиторий без крайних пробелов")
    func passesTrimmedQueryToRepository() async throws {
        let spy = LocationSearchSpy(returning: .success([.almaty]))
        let useCase = SearchLocationsUseCase(repository: spy)

        let locations = try await useCase.execute(query: "  алма  ")

        #expect(await spy.receivedQueries == ["алма"])
        #expect(locations == [.almaty])
    }

    @Test("Ошибка репозитория доходит до вызывающего")
    func propagatesRepositoryError() async {
        let spy = LocationSearchSpy(returning: .failure(SearchError.offline))
        let useCase = SearchLocationsUseCase(repository: spy)

        await #expect(throws: SearchError.offline) {
            try await useCase.execute(query: "алма")
        }
    }
}

extension Location {
    static let almaty = Location(
        id: 1_526_384,
        name: "Алматы",
        country: "Казахстан",
        region: "Алматы",
        coordinate: Coordinate(latitude: 43.25249, longitude: 76.9115)
    )
}
