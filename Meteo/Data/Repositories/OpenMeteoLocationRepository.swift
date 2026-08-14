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
            throw SearchError.invalidData
        }

        do {
            let response: GeocodingResponseDTO = try await client.get(url)
            return LocationMapper.map(response)
        } catch let error as URLError where error.code == .cancelled {
            // Отмена — не отказ поиска. Она должна дойти до вызывающего именно
            // отменой, иначе снятая задача покажет пользователю ошибку.
            throw CancellationError()
        } catch let error as URLError {
            throw Self.searchError(for: error)
        } catch let error as HTTPError {
            throw Self.searchError(for: error)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw SearchError.unknown
        }
    }

    private static func searchError(for error: URLError) -> SearchError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            .offline
        case .timedOut, .cannotConnectToHost, .cannotFindHost, .badServerResponse:
            .server
        default:
            .unknown
        }
    }

    private static func searchError(for error: HTTPError) -> SearchError {
        switch error {
        case .decoding, .invalidResponse: .invalidData
        case .status: .server
        }
    }
}
