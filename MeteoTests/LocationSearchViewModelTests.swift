//
//  LocationSearchViewModelTests.swift
//  MeteoTests
//

import Testing
@testable import Meteo

/// Stub: отдаёт заготовленный ответ, вызовы не считает — здесь проверяется
/// состояние экрана, а не обращения к репозиторию.
private struct LocationSearchStub: LocationSearching {

    let result: Result<[Location], any Error>

    func searchLocations(matching query: String) async throws -> [Location] {
        try result.get()
    }
}

@MainActor
struct LocationSearchViewModelTests {

    @Test("Запрос короче двух символов оставляет подсказку")
    func keepsHintForShortQuery() async {
        let viewModel = makeViewModel(returning: .success([.almaty]))
        viewModel.query = "а"

        await viewModel.search()

        #expect(viewModel.state == .hint)
    }

    @Test("Найденные города переводят экран в состояние результатов")
    func showsResultsWhenLocationsFound() async {
        let viewModel = makeViewModel(returning: .success([.almaty]))
        viewModel.query = "алма"

        await viewModel.search()

        #expect(viewModel.state == .results([.almaty]))
    }

    @Test("Пустой ответ — это «ничего не найдено», а не ошибка")
    func showsEmptyStateWhenNothingFound() async {
        let viewModel = makeViewModel(returning: .success([]))
        viewModel.query = "zzzzzz"

        await viewModel.search()

        #expect(viewModel.state == .empty)
    }

    @Test("Сетевая ошибка переводит экран в состояние ошибки с текстом")
    func showsFailureWhenRequestFails() async {
        let viewModel = makeViewModel(returning: .failure(SearchError.offline))
        viewModel.query = "алма"

        await viewModel.search()

        #expect(viewModel.state == .failed("Нет соединения с интернетом"))
    }

    @Test("Повтор меняет идентификатор задачи при том же запросе")
    func retryChangesSearchID() {
        let viewModel = makeViewModel(returning: .success([.almaty]))
        viewModel.query = "алма"
        let before = viewModel.searchID

        viewModel.retry()

        #expect(viewModel.searchID != before)
    }

    private func makeViewModel(
        returning result: Result<[Location], any Error>
    ) -> LocationSearchViewModel {
        LocationSearchViewModel(
            searchLocations: SearchLocationsUseCase(
                repository: LocationSearchStub(result: result)
            ),
            debounce: .zero
        )
    }
}
