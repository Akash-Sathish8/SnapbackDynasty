import SwiftUI

/// Quick ~1 second overlay showing the play result.
struct ResultFlashView: View {
    let text: String     // e.g., "COMPLETE! +14 yds"
    let detail: String   // e.g., "1st & 10 at OPP 42"
    let isPositive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(text)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(isPositive ? .green : .red)
            Text(detail)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
    }
}
