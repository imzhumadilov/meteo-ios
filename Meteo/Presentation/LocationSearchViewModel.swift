//
//  LocationSearchViewModel.swift
//  Meteo
//

import Foundation

/// Значение, по смене которого перезапускается поиск.
///
/// Повтор после ошибки увеличивает `attempt`: запрос тот же, а задача — новая,
/// поэтому кнопка «Повторить» обходится без `Task { }` и не ломает отмену.
nonisolated struct SearchID: Equatable {
    let query: String
    let attempt: Int
}

@MainActor
@Observable
final class LocationSearchViewModel {

    /// Состояния экрана — одно перечисление, а не набор флагов: взаимоисключение
    /// обеспечивается типом, а не аккуратностью кода.
    enum State: Equatable {
        case hint
        case searching
        case results([Location])
        case empty
        case failed(String)
    }

    var query = ""
    private(set) var state: State = .hint
    private(set) var attempt = 0

    var searchID: SearchID { SearchID(query: query, attempt: attempt) }

    private let searchLocations: SearchLocationsUseCase
    private let debounce: Duration

    init(searchLocations: SearchLocationsUseCase, debounce: Duration = .milliseconds(300)) {
        self.searchLocations = searchLocations
        self.debounce = debounce
    }

    /// Вызывается из `.task(id: searchID)`. Отменой управляет SwiftUI: смена
    /// идентификатора снимает предыдущую задачу, поэтому здесь её нет.
    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= SearchLocationsUseCase.minimumQueryLength else {
            state = .hint
            return
        }

        do {
            // Пауза раньше показа индикатора: при быстром вводе задача снимается
            // здесь — ни запроса, ни мигания загрузкой не происходит.
            try await Task.sleep(for: debounce)
            state = .searching
            let locations = try await searchLocations.execute(query: trimmed)
            state = locations.isEmpty ? .empty : .results(locations)
        } catch is CancellationError {
            // Задача снята новым вводом. Состояние выставит та, что её сменила.
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func retry() {
        attempt += 1
    }

    private static func message(for error: Error) -> String {
        switch error as? SearchError {
        case .offline: "Нет соединения с интернетом"
        case .server: "Сервер не отвечает"
        case .invalidData: "Не удалось прочитать ответ сервера"
        case .unknown, .none: "Не удалось выполнить поиск"
        }
    }
}
