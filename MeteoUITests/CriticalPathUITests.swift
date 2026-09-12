//
//  CriticalPathUITests.swift
//  MeteoUITests
//

import XCTest

/// Один тест на критический путь, а не покрытие.
///
/// UI-тесты дорогие и нестабильные; их ценность в том, что они ловят
/// несвязанность экранов между собой — то, чего не поймает ни один юнит-тест.
final class CriticalPathUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testAddingCityFromSearchOpensItsForecast() {
        let app = XCUIApplication()
        // Приложение стартует на подставных источниках: тест не должен падать
        // от плохого интернета.
        app.launchArguments = [UITestingEnvironmentArgument]
        app.launch()

        // Список пуст — добавляем город.
        let add = app.buttons["saved.add"]
        XCTAssertTrue(add.waitForExistence(timeout: Self.timeout), "кнопка добавления не появилась")
        add.tap()

        let query = app.textFields["search.query"]
        XCTAssertTrue(query.waitForExistence(timeout: Self.timeout), "поле поиска не появилось")

        // Одного тапа мало: пока идёт анимация показа модального окна, он может
        // не дать полю фокус, и ввод падает с «neither element nor any
        // descendant has keyboard focus».
        query.tap()
        if !app.keyboards.element.waitForExistence(timeout: Self.shortTimeout) {
            query.tap()
            XCTAssertTrue(
                app.keyboards.element.waitForExistence(timeout: Self.timeout),
                "клавиатура не появилась, вводить некуда"
            )
        }

        query.typeText("alma")

        let result = app.buttons["search.result.\(Self.almatyID)"]
        XCTAssertTrue(result.waitForExistence(timeout: Self.timeout), "результат поиска не появился")
        result.tap()

        // Выбор закрывает поиск и добавляет город в список, а прогноз
        // открывается уже тапом по строке города.
        let city = app.buttons["saved.city.\(Self.almatyID)"]
        XCTAssertTrue(city.waitForExistence(timeout: Self.timeout), "город не появился в списке")
        city.tap()

        let forecast = app.descendants(matching: .any)["forecast.screen.\(Self.almatyID)"]
        XCTAssertTrue(forecast.waitForExistence(timeout: Self.timeout), "экран прогноза не открылся")
    }

    /// Элементы ищутся только по идентификаторам: поиск по видимому тексту
    /// ломается при смене формулировок и не переживает локализацию.
    private static let almatyID = 1_526_384
    private static let timeout: TimeInterval = 10
    private static let shortTimeout: TimeInterval = 3
}

/// Аргумент дублируется строкой: тестовый таргет не видит код приложения.
private let UITestingEnvironmentArgument = "-ui-testing"
