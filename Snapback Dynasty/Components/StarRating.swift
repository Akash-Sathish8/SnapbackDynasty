import SwiftUI

struct StarRating: View {
    @Environment(\.theme) private var theme
    let stars: Int
    var size: CGFloat = 10

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(i < stars ? theme.gold : Color(hex: "#D6D3D1"))
            }
        }
    }
}
