//
//  SearchSnapshotTests.swift
//  MeteoTests
//

import Testing
@testable import Meteo

@MainActor
@Suite(.enabled(if: SnapshotSuite.isEnabled))
struct SearchSnapshotTests {

    @Test("Подсказка")
    func hint() throws {
        try Snapshot.assert(makeView(state: .hint), named: "search-hint")
    }

    @Test("Идёт поиск")
    func searching() throws {
        try Snapshot.assert(makeView(state: .searching), named: "search-searching")
    }

    @Test("Результаты")
    func results() throws {
        try Snapshot.assert(makeView(state: .results(SnapshotData.cities)), named: "search-results")
    }

    @Test("Ничего не найдено")
    func empty() throws {
        try Snapshot.assert(makeView(state: .empty), named: "search-empty")
    }

    @Test("Ошибка")
    func failed() throws {
        try Snapshot.assert(
            makeView(state: .failed("Нет соединения с интернетом")),
            named: "search-failed"
        )
    }

    private func makeView(state: LocationSearchViewModel.State) -> LocationSearchView {
        LocationSearchView(
            viewModel: LocationSearchViewModel(
                frozenAt: state,
                searchLocations: SearchLocationsUseCase(repository: IdleLocationSearching())
            ),
            onSelect: { _ in }
        )
    }
}
