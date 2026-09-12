//
//  ForecastView.swift
//  Meteo
//

import SwiftUI

struct ForecastView: View {

    @State private var viewModel: ForecastViewModel

    init(viewModel: ForecastViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.background)
            .accessibilityIdentifier("forecast.screen.\(viewModel.location.id)")
            .navigationTitle(viewModel.location.name)
            .navigationBarTitleDisplayMode(.large)
            .task(id: viewModel.attempt) {
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .tint(Palette.accent)
        case .loaded(let forecast):
            loaded(forecast)
        case .failed(let text):
            failure(text)
        }
    }

    private func loaded(_ forecast: Forecast) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                currentCard(forecast.current)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Прогноз на неделю")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.textSecondary)

                    dailyCard(viewModel.dayRows(for: forecast))
                }
            }
            .padding(Spacing.md)
        }
    }

    private func currentCard(_ weather: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.temperature(weather.temperature))
                .font(Typography.temperatureDisplay)
                .foregroundStyle(Palette.textPrimary)

            Text(weather.condition.text)
                .font(Typography.title3)
                .foregroundStyle(Palette.textSecondary)

            HStack(spacing: Spacing.lg) {
                Text(viewModel.humidity(weather))
                Text(viewModel.wind(weather))
            }
            .font(Typography.subheadline)
            .foregroundStyle(Palette.textSecondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.lg))
    }

    /// Здесь `VStack`, а не `List`: карточка целиком лежит внутри `ScrollView`
    /// страницы, и вложенный список ломал бы прокрутку.
    private func dailyCard(_ rows: [ForecastViewModel.DayRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider().overlay(Palette.separator)
                }

                HStack(spacing: Spacing.sm) {
                    Text(row.title)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)

                    Spacer(minLength: Spacing.sm)

                    Text(row.condition)
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.textSecondary)

                    Text(row.temperatures)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
        }
        .background(Palette.surface, in: .rect(cornerRadius: Radius.md))
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
    }
}
