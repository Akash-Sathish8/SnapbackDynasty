import SwiftUI

extension Font {
    static func lora(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(Theme.fontBody, size: size).weight(weight)
    }

    static func loraItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(Theme.fontBodyItalic, size: size).weight(weight)
    }

    static func playfair(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .custom(Theme.fontDisplay, size: size).weight(weight)
    }
}
