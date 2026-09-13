//
//  ForecastSnapshotTests.swift
//  MeteoTests
//

import SwiftUI
import Testing
@testable import Meteo

@MainActor
@Suite(.enabled(if: SnapshotSuite.isEnabled))
struct ForecastSnapshotTests {

    @Test("Загрузка")
    func loading() throws {
        try Snapshot.assert(makeView(state: .loading), screen: "forecast", state: "loading")
    }

    @Test("Показ прогноза")
    func loaded() throws {
        try Snapshot.assert(makeView(state: .loaded(SnapshotData.forecast)), screen: "forecast", state: "loaded")
    }

    @Test("Ошибка")
    func failed() throws {
        try Snapshot.assert(
            makeView(state: .failed("Сервер не отвечает")),
            screen: "forecast", state: "failed"
        )
    }

    /// Экран прогноза открывается пушем, поэтому снимается внутри
    /// `NavigationStack` — иначе не будет заголовка.
    private func makeView(state: ForecastViewModel.State) -> some View {
        NavigationStack {
            ForecastView(
                viewModel: ForecastViewModel(
                    frozenAt: state,
                    location: SnapshotData.almaty,
                    getForecast: GetForecastUseCase(repository: IdleForecastProviding()),
                    now: { SnapshotData.referenceDate }
                )
            )
        }
    }
}
