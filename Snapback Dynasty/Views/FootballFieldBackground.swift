import SwiftUI

/// Soft, translucent football-field backdrop for the start screen.
/// Light kelly-green grass + horizontal yard lines + hash marks,
/// all muted so foreground text + marquee read clearly on top.
struct FootballFieldBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base cream so the field reads as translucent
                Color(hex: "#FAF8F4")

                // Field itself, at 55% opacity
                ZStack {
                    // Grass — soft kelly green
                    Color(red: 0.62, green: 0.82, blue: 0.60)

                    // Alternating mow stripes
                    VStack(spacing: 0) {
                        let stripeHeight = geo.size.height / 20
                        ForEach(0..<20, id: \.self) { i in
                            Rectangle()
                                .fill(
                                    i.isMultiple(of: 2)
                                        ? Color.white.opacity(0.05)
                                        : Color.clear
                                )
                                .frame(height: stripeHeight)
                        }
                    }

                    // Yard lines every 10% of height
                    VStack(spacing: 0) {
                        ForEach(0..<11, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.55))
                                .frame(height: 1.5)
                            Spacer()
                        }
                    }

                    // Hash marks mid-screen
                    HStack {
                        Spacer().frame(width: geo.size.width * 0.33)
                        VStack(spacing: 0) {
                            ForEach(0..<40, id: \.self) { i in
                                if i % 4 != 0 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 6, height: 1)
                                } else {
                                    Color.clear.frame(height: 1)
                                }
                                Spacer().frame(height: geo.size.height / 40 - 1)
                            }
                        }
                        Spacer()
                        VStack(spacing: 0) {
                            ForEach(0..<40, id: \.self) { i in
                                if i % 4 != 0 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 6, height: 1)
                                } else {
                                    Color.clear.frame(height: 1)
                                }
                                Spacer().frame(height: geo.size.height / 40 - 1)
                            }
                        }
                        Spacer().frame(width: geo.size.width * 0.33)
                    }

                    // Large yard numbers
                    VStack {
                        yardNumber("40", align: .top, padding: geo.size.height * 0.20)
                        Spacer()
                        yardNumber("50", align: .center, padding: 0)
                        Spacer()
                        yardNumber("40", align: .bottom, padding: geo.size.height * 0.20)
                    }
                }
                .opacity(0.55)

                // Top-down warm wash so the cream still shows through
                LinearGradient(
                    colors: [
                        Color(hex: "#FAF8F4").opacity(0.3),
                        Color(hex: "#FAF8F4").opacity(0.0),
                        Color(hex: "#FAF8F4").opacity(0.3),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
    }

    private func yardNumber(_ text: String, align: Alignment, padding: CGFloat) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.leading, 20)
            Spacer()
            Text(text)
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.trailing, 20)
        }
        .padding(.top, align == .top ? padding : 0)
        .padding(.bottom, align == .bottom ? padding : 0)
    }
}
