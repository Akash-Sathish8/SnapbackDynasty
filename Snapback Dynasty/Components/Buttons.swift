import SwiftUI

struct PrimaryButton: View {
    @Environment(\.theme) private var theme
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.lora(11, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(theme.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(theme.primary, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    @Environment(\.theme) private var theme
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.lora(11, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
