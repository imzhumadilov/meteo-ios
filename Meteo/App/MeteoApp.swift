//
//  MeteoApp.swift
//  Meteo
//
//  Created by Ilyas Zhumadilov on 11.08.2026.
//

import SwiftUI

@main
struct MeteoApp: App {

    private let container = DIContainer()

    var body: some Scene {
        WindowGroup {
            SavedLocationsView(
                viewModel: container.makeSavedLocationsViewModel(),
                makeSearchViewModel: container.makeLocationSearchViewModel,
                makeForecastViewModel: container.makeForecastViewModel(for:)
            )
        }
    }
}
