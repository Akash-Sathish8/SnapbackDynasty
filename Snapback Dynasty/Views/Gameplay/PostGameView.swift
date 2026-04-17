import SwiftUI

struct PostGameView: View {
    let homeName: String
    let awayName: String
    let homeScore: Int
    let awayScore: Int
    let homeColor: String
    let onSave: () -> Void

    private var winner: String {
        if homeScore > awayScore { return homeName }
        if awayScore > homeScore { return awayName }
        return "TIE"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("FINAL")
                .font(.system(size: 10, weight: .black))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(homeName)
                        .font(.system(size: 16, weight: .black))
                    Text("\(homeScore)")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(homeScore >= awayScore ? .white : .white.opacity(0.5))
                }
                Text("—").foregroundStyle(.white.opacity(0.3))
                    .font(.system(size: 28, weight: .black))
                VStack(spacing: 4) {
                    Text(awayName)
                        .font(.system(size: 16, weight: .black))
                    Text("\(awayScore)")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(awayScore >= homeScore ? .white : .white.opacity(0.5))
                }
            }
            .foregroundStyle(.white)

            if winner == "TIE" {
                Text("TIE GAME").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.yellow)
            } else {
                Text("\(winner) WINS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: homeColor))
            }

            Button {
                onSave()
            } label: {
                Text("Save & Exit")
                    .font(.system(size: 14, weight: .black))
                    .padding(.horizontal, 32).padding(.vertical, 12)
                    .background(Color(hex: homeColor),
                                in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(36)
        .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 14))
    }
}
