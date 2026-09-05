//
//  LocationSearchView.swift
//  Meteo
//

import SwiftUI

struct LocationSearchView: View {

    @State private var viewModel: LocationSearchViewModel
    @State private var selectedLocation: Location?
    @FocusState private var isQueryFieldFocused: Bool

    private let makeForecastViewModel: (Location) -> ForecastViewModel

    init(
        viewModel: LocationSearchViewModel,
        makeForecastViewModel: @escaping (Location) -> ForecastViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeForecastViewModel = makeForecastViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                queryField
                content
            }
            .padding(.top, Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Palette.background)
            .navigationTitle("Поиск города")
            .navigationDestination(item: $selectedLocation) { location in
                ForecastView(viewModel: makeForecastViewModel(location))
            }
        }
        .task(id: viewModel.searchID) {
            await viewModel.search()
        }
    }

    private var queryField: some View {
        TextField("Название города", text: $viewModel.query)
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .tint(Palette.accent)
            .focused($isQueryFieldFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .padding(Spacing.md)
            .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(
                        isQueryFieldFocused ? Palette.accent : Palette.separator,
                        lineWidth: isQueryFieldFocused ? BorderWidth.focused : BorderWidth.regular
                    )
            }
            .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .hint:
            message("Введите название города")
        case .searching:
            ProgressView()
                .tint(Palette.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .results(let locations):
            results(locations)
        case .empty:
            message("Ничего не найдено")
        case .failed(let text):
            failure(text)
        }
    }

    private func results(_ locations: [Location]) -> some View {
        List(locations) { location in
            // Кнопка, а не NavigationLink: в макете у строк нет системной
            // галочки перехода, а List рисует её у ссылки автоматически.
            Button {
                selectedLocation = location
            } label: {
                row(location)
            }
            .buttonStyle(.plain)
            // Отступы строки обнулены и заданы вручную, чтобы разделитель шёл
            // во всю ширину карточки, как в макете, а не с отбивкой от текста.
            .listRowInsets(EdgeInsets())
            .listRowBackground(Palette.surface)
            .listRowSeparatorTint(Palette.separator)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
    }

    private func row(_ location: Location) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(location.name)
                .font(Typography.headline)
                .foregroundStyle(Palette.textPrimary)

            if let subtitle = Self.subtitle(for: location) {
                Text(subtitle)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(Typography.body)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failure(_ text: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text(text)
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)

            Button("Повторить") {
                viewModel.retry()
            }
            .font(Typography.headline)
            .tint(Palette.accent)
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// «Страна, Регион» — с пропуском того, чего геокодер не прислал.
    private static func subtitle(for location: Location) -> String? {
        let parts = [location.country, location.region].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
