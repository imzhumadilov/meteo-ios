//
//  SnapshotTesting.swift
//  MeteoTests
//

import Foundation
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

/// Снапшоты входят только в полный прогон: план `Full` задаёт переменную
/// `SNAPSHOTS`, план `Fast` — нет.
///
/// Через `skippedTests` в плане это сделать не вышло: для наборов Swift Testing
/// Xcode их не применяет, проверено тремя формами идентификатора.
nonisolated enum SnapshotSuite {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["SNAPSHOTS"] == "1"
    }
}

/// Сравнение, запись эталонов, артефакты расхождений и сообщения о падении —
/// `swift-snapshot-testing`. Здесь остаётся то, чего в библиотеке нет:
/// проверка окружения и **отрисовка**.
///
/// Отрисовка своя по измеренной причине: библиотечная не замораживает анимации,
/// и состояния `loading` и `searching` расходятся от прогона к прогону —
/// индикатор загрузки попадает в кадр под случайным углом.
@MainActor
enum Snapshot {

    /// Окружение зафиксировано **в коде**, а не берётся из выбранной схемы.
    /// Эталон, снятый на другом устройстве или другой версии системы, невалиден.
    enum Device {
        static let name = "iPhone 17"
        static let systemVersion = "26.5"

        /// Точки, а не пиксели: 402×874 при масштабе 3.
        static let size = CGSize(width: 402, height: 874)
        static let scale: CGFloat = 3
    }

    /// Перезапись эталонов: `SNAPSHOT_RECORD=1` в окружении прогона.
    private static var isRecording: Bool {
        ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }

    /// Имя файла библиотека склеивает как `<экран>.<состояние>.png`, поэтому
    /// части передаются отдельно. Одним куском имя превращалось бы в скрытый
    /// файл с точкой в начале.
    static func assert(
        _ view: some View,
        screen: String,
        state: String,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        try checkEnvironment(
            at: SourceLocation(
                fileID: "\(fileID)",
                filePath: "\(filePath)",
                line: Int(line),
                column: Int(column)
            )
        )

        let image = try render(view)

        withSnapshotTesting(record: isRecording ? .all : .missing) {
            assertSnapshot(
                of: image,
                as: .image,
                named: state,
                fileID: fileID,
                file: filePath,
                testName: screen,
                line: line,
                column: column
            )
        }
    }

    // MARK: - Окружение

    /// Прогон на чужом окружении не должен молчать: без этой проверки он
    /// либо покажет расхождение там, где вёрстку не меняли, либо — в режиме
    /// записи — тихо перезапишет эталоны неверными.
    private static func checkEnvironment(at location: SourceLocation) throws {
        let environment = ProcessInfo.processInfo.environment
        let device = environment["SIMULATOR_DEVICE_NAME"] ?? "неизвестно"
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let systemVersion = "\(version.majorVersion).\(version.minorVersion)"

        try #require(
            device == Device.name && systemVersion == Device.systemVersion,
            """
            Снапшоты сняты для \(Device.name), iOS \(Device.systemVersion), \
            а прогон идёт на \(device), iOS \(systemVersion).
            Эталоны зависят от устройства, версии системы и шрифтов — \
            на другом окружении они невалидны.
            """,
            sourceLocation: location
        )
    }

    // MARK: - Отрисовка

    private static func render(_ view: some View) throws -> UIImage {
        let controller = UIHostingController(rootView: view)

        // Окно обязательно: без появления на экране SwiftUI не рисует ничего.
        // Состояние при этом не затирается, потому что вьюмодели снапшотов
        // заморожены и не загружают.
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = UIWindow(windowScene: try #require(scene, "нет активной сцены для отрисовки"))
        window.frame = CGRect(origin: .zero, size: Device.size)
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        // Анимации останавливаются на нулевом кадре. Без этого индикатор
        // загрузки попадает в снимок под случайным углом.
        UIView.setAnimationsEnabled(false)
        freezeAnimations(in: controller.view.layer)

        let format = UIGraphicsImageRendererFormat()
        format.scale = Device.scale

        // Окно убирается сразу после снимка: иначе окна от прошлых тестов
        // копятся в сцене и влияют на то, что попадёт в кадр.
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // `layer.render(in:)`, а не `drawHierarchy(afterScreenUpdates:)`:
        // второй прокручивает runloop и рисует экранное содержимое, из-за чего
        // снимок зависит от того, что ещё происходит на экране.
        return UIGraphicsImageRenderer(size: Device.size, format: format).image { context in
            controller.view.layer.render(in: context.cgContext)
        }
    }

    /// Тайминг слоя останавливается на начале: `speed = 0` замораживает,
    /// `timeOffset = 0` фиксирует кадр.
    private static func freezeAnimations(in layer: CALayer) {
        layer.speed = 0
        layer.timeOffset = 0
        layer.sublayers?.forEach(freezeAnimations)
    }
}
