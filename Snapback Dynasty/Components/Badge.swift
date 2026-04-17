import SwiftUI

struct Badge: View {
    let text: String
    let color: Color
    let bg: Color

    var body: some View {
        Text(text)
            .font(.lora(9, weight: .bold))
            .kerning(0.3)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .foregroundStyle(color)
            .background(bg, in: RoundedRectangle(cornerRadius: 4))
    }
}
