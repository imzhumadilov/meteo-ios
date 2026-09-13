//
//  OpenMeteoForecastRepository.swift
//  Meteo
//

import Foundation

nonisolated struct OpenMeteoForecastRepository: ForecastProviding {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func forecast(for coordinate: Coordinate) async throws -> Forecast {
        guard let url = ForecastEndpoint.forecast(for: coordinate) else {
            throw WeatherServiceError.invalidData
        }

        do {
            let response: ForecastResponseDTO = try await client.get(url)
            return ForecastMapper.map(response)
        } catch {
            throw NetworkErrorMapper.domainError(for: error)
        }
    }
}
