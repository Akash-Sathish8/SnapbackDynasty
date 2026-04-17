import SwiftUI

/// Small procedural cartoon avatar — helmet + face peek, team-colored.
/// Deterministic variation from player name hash (skin tone, stripe pattern).
struct PlayerAvatar: View {
    let player: Player
    var size: CGFloat = 32

    private var teamColor: Color {
        Color(hex: player.team?.primaryColor ?? "#78716C")
    }

    private var stripeColor: Color {
        // Use a lightened or darkened version for the stripe
        let hex = player.team?.primaryColor ?? "#78716C"
        return isLightHex(hex)
            ? Color(hex: darkenHex(hex, by: 0.3))
            : .white
    }

    /// Deterministic hash-based variation seed from player name.
    private var seed: Int {
        player.firstName.hashValue ^ player.lastName.hashValue
    }

    private var skinTone: Color {
        let tones: [Color] = [
            Color(red: 0.95, green: 0.83, blue: 0.71),  // light
            Color(red: 0.87, green: 0.71, blue: 0.57),  // medium-light
            Color(red: 0.75, green: 0.58, blue: 0.42),  // medium
            Color(red: 0.58, green: 0.42, blue: 0.30),  // medium-dark
            Color(red: 0.42, green: 0.30, blue: 0.22),  // dark
            Color(red: 0.32, green: 0.22, blue: 0.16),  // deeper
        ]
        return tones[abs(seed) % tones.count]
    }

    /// 0 = plain helmet, 1 = horizontal stripe, 2 = star dot
    private var helmetDecoration: Int {
        abs(seed &>> 4) % 3
    }

    private var hasGoatee: Bool { abs(seed &>> 8) % 5 == 0 }

    var body: some View {
        ZStack {
            // Background circle (helmet silhouette)
            Circle()
                .fill(teamColor)
                .frame(width: size, height: size)

            // Helmet top (upper 2/3)
            helmetShape
                .fill(teamColor)
                .frame(width: size, height: size)

            // Helmet decoration
            decorationOverlay

            // Face peek (bottom portion with face mask)
            facePeek
        }
        .overlay(
            Circle().stroke(.white.opacity(0.6), lineWidth: 1)
        )
        .frame(width: size, height: size)
    }

    /// Helmet — actually just fills the top 2/3 of the circle.
    private var helmetShape: some Shape {
        Rectangle()
    }

    @ViewBuilder
    private var decorationOverlay: some View {
        switch helmetDecoration {
        case 1:
            // Horizontal stripe across the helmet
            Rectangle()
                .fill(stripeColor)
                .frame(width: size, height: size * 0.1)
                .offset(y: -size * 0.1)
        case 2:
            // Small star/dot on side
            Circle()
                .fill(stripeColor)
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(x: size * 0.25, y: -size * 0.1)
        default:
            EmptyView()
        }
    }

    private var facePeek: some View {
        ZStack {
            // Face (skin-tone crescent at bottom)
            Circle()
                .fill(skinTone)
                .frame(width: size * 0.68, height: size * 0.68)
                .offset(y: size * 0.22)
                .mask(
                    Rectangle()
                        .frame(width: size, height: size * 0.4)
                        .offset(y: size * 0.3)
                )

            // Eyes (two tiny dots)
            HStack(spacing: size * 0.16) {
                Circle().fill(Color.black).frame(width: size * 0.06, height: size * 0.06)
                Circle().fill(Color.black).frame(width: size * 0.06, height: size * 0.06)
            }
            .offset(y: size * 0.22)

            // Face mask (grey bars across chin)
            Rectangle()
                .fill(Color.gray.opacity(0.7))
                .frame(width: size * 0.5, height: size * 0.05)
                .offset(y: size * 0.36)
            Rectangle()
                .fill(Color.gray.opacity(0.7))
                .frame(width: size * 0.05, height: size * 0.18)
                .offset(y: size * 0.32)

            // Optional goatee
            if hasGoatee {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: size * 0.14, height: size * 0.08)
                    .offset(y: size * 0.38)
            }
        }
    }
}
