import SwiftUI

struct SectionLabel: View {
    @Environment(\.theme) private var theme
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.lora(9, weight: .semibold))
            .kerning(1.2)
            .foregroundStyle(theme.muted)
            .padding(.bottom, 8)
    }
}
