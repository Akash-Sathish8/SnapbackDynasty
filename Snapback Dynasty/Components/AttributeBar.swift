import SwiftUI

struct AttributeBar: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: Int
    var potential: Int? = nil
    var maxValue: Int = 99

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.lora(10, weight: .semibold))
                    .kerning(0.8)
                    .foregroundStyle(theme.muted)
                Spacer()
                Text("\(value)")
                    .font(.lora(12, weight: .bold))
                    .foregroundStyle(theme.text)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(theme.borderSubtle)
                    RoundedRectangle(cornerRadius: 3).fill(theme.primary)
                        .frame(width: geo.size.width * Double(value) / Double(maxValue))
                    if let pot = potential {
                        Circle()
                            .fill(theme.success)
                            .frame(width: 6, height: 6)
                            .offset(
                                x: geo.size.width * Double(pot) / Double(maxValue) - 3,
                                y: 0
                            )
                    }
                }
            }
            .frame(height: 6)
        }
    }
}
