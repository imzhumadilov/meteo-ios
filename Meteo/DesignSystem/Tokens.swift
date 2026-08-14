//
//  Tokens.swift
//  Meteo
//

import SwiftUI

// Токены дизайн-системы. Имена совпадают с именами переменных в Figma.
//
// Это единственное место в проекте, где числовые и цветовые литералы законны:
// здесь они определяются. В вёрстке литерал означает потерянную связь с макетом.

nonisolated enum Palette {
    static let textPrimary = Color(hex: 0x11_18_27)
    static let textSecondary = Color(hex: 0x6B_72_80)
    static let surface = Color(hex: 0xFF_FF_FF)
    static let background = Color(hex: 0xF3_F4_F6)
    static let separator = Color(hex: 0xE5_E7_EB)
    static let accent = Color(hex: 0x25_63_EB)
}

nonisolated enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

nonisolated enum Radius {
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
}

/// Толщина рамки поля ввода. В переменных Figma этого значения нет, значения
/// взяты из описания тикета METEO-1: в фокусе 2, без фокуса 1.
nonisolated enum BorderWidth {
    static let regular: CGFloat = 1
    static let focused: CGFloat = 2
}

/// Обёртка над семантическими стилями текста: они масштабируются вместе с
/// Dynamic Type, а фиксированный размер в пунктах — нет.
nonisolated enum Typography {
    static let largeTitle = Font.largeTitle.weight(.semibold)
    static let title = Font.title.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote

    /// Единственный размер без семантического эквивалента — крупная температура
    /// на экране прогноза.
    static let temperatureDisplay = Font.system(size: 64, weight: .semibold)
}

private nonisolated extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
