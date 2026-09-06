//
//  GetWeatherForSavedLocationsUseCase.swift
//  Meteo
//

import Foundation

nonisolated struct GetWeatherForSavedLocationsUseCase {

    private let store: SavedLocationsStoring
    private let forecasts: ForecastProviding

    init(store: SavedLocationsStoring, forecasts: ForecastProviding) {
        self.store = store
        self.forecasts = forecasts
    }

    func execute() async throws -> [SavedLocationWeather] {
        let locations = store.savedLocations()
        guard !locations.isEmpty else { return [] }

        let forecasts = self.forecasts

        let temperatures = try await withThrowingTaskGroup(
            of: (index: Int, temperature: Double?).self
        ) { group in
            for (index, location) in locations.enumerated() {
                group.addTask {
                    do {
                        let forecast = try await forecasts.forecast(for: location.coordinate)
                        return (index, forecast.current.temperature)
                    } catch is CancellationError {
                        // Снятие задачи — не отказ города: пробрасываем дальше,
                        // чтобы группа свернулась целиком.
                        throw CancellationError()
                    } catch {
                        // А вот отказ по городу ловится здесь и наружу не выходит.
                        // Бросить — значит снять соседние задачи и потерять
                        // города, которые успешно ответили.
                        return (index, nil)
                    }
                }
            }

            var byIndex: [Int: Double?] = [:]
            for try await result in group {
                byIndex[result.index] = result.temperature
            }
            return byIndex
        }

        // Задачи в группе завершаются в произвольном порядке, поэтому список
        // пересобирается по исходным индексам, а не по порядку ответов.
        return locations.enumerated().map { index, location in
            SavedLocationWeather(location: location, temperature: temperatures[index] ?? nil)
        }
    }
}
