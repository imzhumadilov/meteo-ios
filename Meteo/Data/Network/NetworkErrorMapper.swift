//
//  NetworkErrorMapper.swift
//  Meteo
//

import Foundation

/// Переводит транспортные ошибки в случаи, понятные домену.
nonisolated enum NetworkErrorMapper {

    /// Отмена проходит насквозь отменой, а не превращается в ошибку сервиса:
    /// иначе снятая задача покажет пользователю экран ошибки.
    static func domainError(for error: any Error) -> any Error {
        if let error = error as? URLError {
            return error.code == .cancelled ? CancellationError() : serviceError(for: error)
        }
        if error is CancellationError {
            return CancellationError()
        }
        if let error = error as? HTTPError {
            return serviceError(for: error)
        }
        return WeatherServiceError.unknown
    }

    private static func serviceError(for error: URLError) -> WeatherServiceError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            .offline
        case .timedOut, .cannotConnectToHost, .cannotFindHost, .badServerResponse:
            .server
        default:
            .unknown
        }
    }

    private static func serviceError(for error: HTTPError) -> WeatherServiceError {
        switch error {
        case .decoding, .invalidResponse: .invalidData
        case .status: .server
        }
    }
}
