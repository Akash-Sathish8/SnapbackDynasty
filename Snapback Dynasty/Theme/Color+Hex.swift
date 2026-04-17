import SwiftUI

func hexToRgb(_ hex: String) -> (r: Double, g: Double, b: Double) {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    return (
        r: Double((int >> 16) & 0xFF),
        g: Double((int >> 8) & 0xFF),
        b: Double(int & 0xFF)
    )
}

func isLightHex(_ hex: String) -> Bool {
    let rgb = hexToRgb(hex)
    let luminance = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000
    return luminance > 155
}

func darkenHex(_ hex: String, by factor: Double) -> String {
    let rgb = hexToRgb(hex)
    let r = max(0, Int(rgb.r * (1 - factor)))
    let g = max(0, Int(rgb.g * (1 - factor)))
    let b = max(0, Int(rgb.b * (1 - factor)))
    return String(format: "#%02X%02X%02X", r, g, b)
}
