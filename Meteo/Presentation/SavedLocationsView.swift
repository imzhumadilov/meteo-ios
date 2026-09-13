//
//  SavedLocationsView.swift
//  Meteo
//

import SwiftUI

struct SavedLocationsView: View {

    @State private var viewModel: SavedLocationsViewModel
    @State private var selectedLocation: Location?
    @State private var isSearchPresented = false

    private let makeSearchViewModel: () -> LocationSearchViewModel
    private let makeForecastViewModel: (Location) -> ForecastViewModel

    init(
        viewModel: SavedLocationsViewModel,
        makeSearchViewModel: @escaping () -> LocationSearchViewModel,
        makeForecastViewModel: @escaping (Location) -> ForecastViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeSearchViewModel = makeSearchViewModel
        self.makeForecastViewModel = makeForecastViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.background)
                .navigationTitle("Погода")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSearchPresented = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .tint(Palette.accent)
                    }
                }
                .navigationDestination(item: $selectedLocation) { location in
                    ForecastView(viewModel: makeForecastViewModel(location))
                }
                .sheet(isPresented: $isSearchPresented) {
                    LocationSearchView(viewModel: makeSearchViewModel()) { location in
                        viewModel.add(location)
                        isSearchPresented = false
                    }
                }
        }
        .task(id: viewModel.reloadID) {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .empty:
            empty
        case .loading(let rows), .loaded(let rows):
            list(rows)
        }
    }

    private var empty: some View {
        VStack(spacing: Spacing.md) {
            Text("Добавьте город")
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)

            Button("Добавить") {
                isSearchPresented = true
            }
            .font(Typography.headline)
            .tint(Palette.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// `List`, а не `VStack`: свайп для удаления даёт именно он.
    /// Вид отдельных карточек с зазором собран через оформление строк.
    private func list(_ rows: [SavedLocationsViewModel.Row]) -> some View {
        List(rows) { row in
            card(row)
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs,
                    leading: Spacing.md,
                    bottom: Spacing.xs,
                    trailing: Spacing.md
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                // Своё действие, а не `.onDelete`: системная кнопка берёт
                // подпись из локализации приложения, а её у нас нет, и в
                // русском интерфейсе появляется английское «Delete».
                .swipeActions(edge: .trailing) {
                    Button("Удалить", role: .destructive) {
                        viewModel.remove(row.location)
                    }
                }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func card(_ row: SavedLocationsViewModel.Row) -> some View {
        Button {
            selectedLocation = row.location
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(row.location.name)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)

                    if let country = row.location.country {
                        Text(country)
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }

                Spacer(minLength: Spacing.sm)

                temperature(row.temperature)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: .rect(cornerRadius: Radius.lg))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func temperature(_ temperature: SavedLocationsViewModel.Temperature) -> some View {
        switch temperature {
        case .loading:
            ProgressView().tint(Palette.accent)
        case .value(let text):
            Text(text)
                .font(Typography.title)
                .foregroundStyle(Palette.textPrimary)
        case .unavailable:
            Text(TemperatureText.unavailable)
                .font(Typography.title)
                .foregroundStyle(Palette.textSecondary)
        }
    }
}
