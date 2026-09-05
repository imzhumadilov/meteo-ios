//
//  GetForecastUseCase.swift
//  Meteo
//

import Foundation

nonisolated struct GetForecastUseCase {

    private let repository: ForecastProviding

    init(repository: ForecastProviding) {
        self.repository = repository
    }

    func execute(for coordinate: Coordinate) async throws -> Forecast {
        try await repository.forecast(for: coordinate)
    }
}
