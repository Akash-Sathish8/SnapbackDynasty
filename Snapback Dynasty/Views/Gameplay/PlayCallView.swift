import SwiftUI

/// Offensive play calling overlay: category tabs (Run / Short / Medium / Long Pass)
/// with the plays in each category below.
struct PlayCallView: View {
    let teamColor: String
    let onSelect: (PlayDefinition) -> Void

    @State private var selectedCategory: PlayDefinition.Category = .run

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PlayDefinition.Category.allCases, id: \.rawValue) { c in
                            Button {
                                selectedCategory = c
                            } label: {
                                Text(c.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        c == selectedCategory ?
                                            Color(hex: teamColor) :
                                            Color.white.opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                                    .foregroundStyle(
                                        c == selectedCategory ? .white : .white.opacity(0.8)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Play cards grid
                let plays = Playbook.plays(for: selectedCategory)
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 8) {
                    ForEach(plays, id: \.name) { play in
                        Button {
                            onSelect(play)
                        } label: {
                            VStack(spacing: 4) {
                                Text(play.isRunPlay ? "RUN" : "PASS")
                                    .font(.system(size: 8, weight: .black))
                                    .kerning(0.8)
                                    .foregroundStyle(
                                        play.isRunPlay
                                            ? Color.orange.opacity(0.9)
                                            : Color.cyan.opacity(0.9)
                                    )
                                Text(play.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Color.white.opacity(play.isRunPlay ? 0.14 : 0.08),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8).stroke(
                                    play.isRunPlay
                                        ? Color.orange.opacity(0.4)
                                        : Color.cyan.opacity(0.35),
                                    lineWidth: 1
                                )
                            )
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
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}
