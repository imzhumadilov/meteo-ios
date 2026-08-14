//
//  SearchLocationsUseCase.swift
//  Meteo
//

import Foundation

nonisolated struct SearchLocationsUseCase {

    /// Запрос короче этого в сеть не уходит.
    ///
    /// Геокодер и сам не находит совпадений по одной букве, так что отсечка
    /// экономит трафик и убирает мигание списка, а не защищает от ошибки.
    static let minimumQueryLength = 2

    private let repository: LocationSearching

    init(repository: LocationSearching) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [Location] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumQueryLength else { return [] }
        return try await repository.searchLocations(matching: trimmed)
    }
}
