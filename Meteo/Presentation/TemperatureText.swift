//
//  TemperatureText.swift
//  Meteo
//

import Foundation

/// Температура для показа. Один формат на все экраны.
nonisolated enum TemperatureText {

    static func text(for celsius: Double) -> String {
        "\(Int(celsius.rounded()))°"
    }

    /// Прочерк вместо температуры, когда запрос по городу не удался.
    static let unavailable = "—"
}
