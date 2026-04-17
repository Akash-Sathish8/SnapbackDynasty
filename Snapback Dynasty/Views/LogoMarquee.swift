import SwiftUI

/// Horizontal auto-scrolling row of team logos. Pulled from the static
/// `conferenceSeeds` table so it works before any database seed has run.
struct LogoMarquee: View {
    /// Subset of logo URLs to cycle through. Shuffled once at first render.
    private static let allLogoURLs: [String] = conferenceSeeds
        .flatMap { $0.teams.map(\.logoURL) }
        .shuffled()

    var body: some View {
        GeometryReader { geo in
            // Repeat the list twice so scrolling can wrap seamlessly.
            let totalWidth = CGFloat(Self.allLogoURLs.count) * 64

            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                let elapsed = context.date.timeIntervalSinceReferenceDate
                let pxPerSec: CGFloat = 28
                let offset = -CGFloat(elapsed * Double(pxPerSec))
                    .truncatingRemainder(dividingBy: totalWidth)

                HStack(spacing: 16) {
                    ForEach(Array(Self.allLogoURLs.enumerated()), id: \.offset) { _, url in
                        CachedLogoImage(
                            urlString: url,
                            fallbackColor: Color(hex: "#E7E5E4")
                        )
                        .frame(width: 48, height: 48)
                    }
                    ForEach(Array(Self.allLogoURLs.enumerated()), id: \.offset) { _, url in
                        CachedLogoImage(
                            urlString: url,
                            fallbackColor: Color(hex: "#E7E5E4")
                        )
                        .frame(width: 48, height: 48)
                    }
                }
                .offset(x: offset)
                .frame(width: geo.size.width, alignment: .leading)
                .allowsHitTesting(false)
            }

            // Subtle edge mask so logos fade off the sides rather than clipping.
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 1)
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.08),
                    .init(color: .black, location: 0.92),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
    }
}
