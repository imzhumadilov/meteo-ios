//
//  OpenMeteoLocationRepository.swift
//  Meteo
//

import Foundation

nonisolated struct OpenMeteoLocationRepository: LocationSearching {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func searchLocations(matching query: String) async throws -> [Location] {
        guard let url = GeocodingEndpoint.search(query: query) else {
            throw WeatherServiceError.invalidData
        }

        do {
            let response: GeocodingResponseDTO = try await client.get(url)
            return LocationMapper.map(response)
        } catch {
            throw NetworkErrorMapper.domainError(for: error)
        }
    }
}
