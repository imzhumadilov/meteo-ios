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
        try Snapshot.assert(makeView(state: .hint), screen: "search", state: "hint")
    }

    @Test("Идёт поиск")
    func searching() throws {
        try Snapshot.assert(makeView(state: .searching), screen: "search", state: "searching")
    }

    @Test("Результаты")
    func results() throws {
        try Snapshot.assert(makeView(state: .results(SnapshotData.cities)), screen: "search", state: "results")
    }

    @Test("Ничего не найдено")
    func empty() throws {
        try Snapshot.assert(makeView(state: .empty), screen: "search", state: "empty")
    }

    @Test("Ошибка")
    func failed() throws {
        try Snapshot.assert(
            makeView(state: .failed("Нет соединения с интернетом")),
            screen: "search", state: "failed"
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
