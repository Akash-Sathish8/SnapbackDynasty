import SwiftUI

struct InterestBar: View {
    @Environment(\.theme) private var theme
    let value: Double

    private var fillColor: Color {
        if value > 0.75 { return theme.success }
        if value > 0.5 { return theme.gold }
        return theme.muted
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(theme.borderSubtle)
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(fillColor)
                    .frame(width: geo.size.width * max(0, min(1, value)))
            }
        }
        .frame(height: 5)
    }
}
