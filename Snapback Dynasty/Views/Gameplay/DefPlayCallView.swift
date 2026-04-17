import SwiftUI

/// Defensive play calling overlay: 2×2 grid of coverage cards.
struct DefPlayCallView: View {
    let onSelect: (DefensivePlay) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Text("PICK YOUR DEFENSE")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.6))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(DefensivePlaybook.all, id: \.name) { play in
                        Button {
                            onSelect(play)
                        } label: {
                            VStack(spacing: 6) {
                                Text(play.name)
                                    .font(.system(size: 16, weight: .black))
                                Text(play.description)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background(.ultraThinMaterial.opacity(0.95))
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
    }
}
