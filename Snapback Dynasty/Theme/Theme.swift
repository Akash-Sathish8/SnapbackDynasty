import SwiftUI

struct Theme {
    let bg: Color
    let card: Color
    let cardAlt: Color
    let primary: Color
    let secondary: Color
    let textOnPrimary: Color
    let text: Color
    let muted: Color
    let border: Color
    let borderSubtle: Color
    let success: Color
    let danger: Color
    let gold: Color
    let primaryFaint: Color
    let primaryMedium: Color
    let primaryStrong: Color

    static let fontBody = "Lora-Regular"
    static let fontBodyItalic = "Lora-Italic"
    static let fontDisplay = "PlayfairDisplay-Regular"
    static let fontDisplayItalic = "PlayfairDisplay-Italic"

    static func from(primaryHex: String, secondaryHex: String? = nil) -> Theme {
        let rgb = hexToRgb(primaryHex)
        let resolvedSecondary = secondaryHex ?? darkenHex(primaryHex, by: 0.4)
        return Theme(
            bg: Color(hex: "#FAF8F4"),
            card: .white,
            cardAlt: Color(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255).opacity(0.04),
            primary: Color(hex: primaryHex),
            secondary: Color(hex: resolvedSecondary),
            textOnPrimary: isLightHex(primaryHex) ? Color(hex: "#1C1917") : .white,
            text: Color(hex: "#1C1917"),
            muted: Color(hex: "#78716C"),
            border: Color(hex: "#E7E5E4"),
            borderSubtle: Color(hex: "#F5F3F0"),
            success: Color(hex: "#15803D"),
            danger: Color(hex: "#B91C1C"),
            gold: Color(hex: "#B45309"),
            primaryFaint: Color(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255).opacity(0.08),
            primaryMedium: Color(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255).opacity(0.15),
            primaryStrong: Color(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255).opacity(0.25)
        )
    }

    static let fallback = Theme.from(primaryHex: "#7BAFD4")
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .fallback
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
