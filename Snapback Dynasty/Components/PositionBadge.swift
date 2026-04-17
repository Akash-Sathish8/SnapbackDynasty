import SwiftUI

struct PositionBadge: View {
    @Environment(\.theme) private var theme
    let position: String
    var size: CGFloat = 28

    var body: some View {
        Text(position)
            .font(.lora(9, weight: .bold))
            .foregroundStyle(theme.primary)
            .frame(width: size, height: size)
            .background(theme.primaryFaint, in: RoundedRectangle(cornerRadius: 6))
    }
}
