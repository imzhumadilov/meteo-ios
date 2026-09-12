//
//  SnapshotTesting.swift
//  MeteoTests
//

import Foundation
import SwiftUI
import Testing
import UIKit

/// Съёмка экранов и сравнение с эталоном в репозитории.
///
/// Своя реализация вместо `swift-snapshot-testing`: подключение пакета требует
/// правок `project.pbxproj`, которые запрещены правилами проекта. Механизм
/// намеренно маленький — если пакет всё же подключат, этот файл выбрасывается,
/// а сами тесты почти не меняются.
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

    static func assert(
        _ view: some View,
        named name: String,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) throws {
        let location = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)

        try checkEnvironment(at: location)

        let rendered = try #require(pixels(of: try render(view)), "не удалось отрисовать экран", sourceLocation: location)
        let reference = referenceURL(for: name, filePath: filePath)

        guard !isRecording, FileManager.default.fileExists(atPath: reference.path) else {
            try write(try render(view), to: reference)
            Issue.record(
                """
                Эталон записан: \(reference.lastPathComponent)
                Проверьте изображение глазами и запустите прогон ещё раз — \
                тест, который сам создал эталон, ничего не проверил.
                """,
                sourceLocation: location
            )
            return
        }

        let expected = try #require(
            pixels(of: UIImage(data: try Data(contentsOf: reference)) ?? UIImage()),
            "эталон \(reference.lastPathComponent) не читается как изображение",
            sourceLocation: location
        )

        guard rendered != expected else { return }

        let failure = reference
            .deletingLastPathComponent()
            .appendingPathComponent("\(name).failure.png")
        try write(try render(view), to: failure)

        Issue.record(
            """
            Экран разошёлся с эталоном: \(name)
            Отличается пикселей: \(differingPixels(rendered, expected)) из \(rendered.count / 4)
            Снято:  \(failure.path)
            Эталон: \(reference.path)
            Если вёрстка изменена осознанно — перезапишите эталоны прогоном \
            с SNAPSHOT_RECORD=1.
            """,
            sourceLocation: location
        )
    }

    // MARK: - Окружение

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
        // загрузки попадает в снимок под случайным углом, и снапшот
        // расходится с эталоном от прогона к прогону.
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
        // второй рисует экранное содержимое и прокручивает runloop, из-за чего
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

    /// Сравниваются сырые пиксели, а не байты PNG: кодировщик волен
    /// упаковывать одно и то же изображение по-разному.
    private static func pixels(of image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Data(bytes)
    }

    private static func differingPixels(_ lhs: Data, _ rhs: Data) -> Int {
        guard lhs.count == rhs.count else { return max(lhs.count, rhs.count) / 4 }

        return stride(from: 0, to: lhs.count, by: 4).count { offset in
            lhs[offset ..< offset + 4] != rhs[offset ..< offset + 4]
        }
    }

    // MARK: - Файлы

    private static func referenceURL(for name: String, filePath: String) -> URL {
        URL(fileURLWithPath: filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent)
            .appendingPathComponent("\(name).png")
    }

    private static func write(_ image: UIImage, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try #require(image.pngData()).write(to: url)
    }
}
