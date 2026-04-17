import SwiftUI
import SwiftData

struct ScheduleView: View {
    let team: Team
    let season: Season
    @Environment(\.modelContext) private var context

    private var games: [Game] {
        let mgr = SeasonManager(context: context)
        return mgr.gamesForTeam(team, season: season)
    }

    private var primary: Color { Color(hex: team.primaryColor) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    SectionLabel("\(String(season.year)) Schedule")
                    HStack {
                        Text("\(team.name) \(team.mascot)")
                            .font(.playfair(16, weight: .black))
                        Spacer()
                        Text(team.record)
                            .font(.playfair(18, weight: .black))
                            .foregroundStyle(primary)
                    }
                }

                Card {
                    SectionLabel("Games")
                    ForEach(Array(games.enumerated()), id: \.offset) { idx, game in
                        gameRow(game)
                        if idx < games.count - 1 {
                            Rectangle().fill(Color(hex: "#F5F3F0")).frame(height: 1)
                        }
                    }

                    if games.isEmpty {
                        Text("No schedule yet — generate one from the dashboard.")
                            .font(.lora(11))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func gameRow(_ game: Game) -> some View {
        let isHome = game.homeTeam?.name == team.name
        let opponent = isHome ? game.awayTeam : game.homeTeam
        let venue = isHome ? "vs" : "@"

        HStack(spacing: 12) {
            Text("\(game.week)")
                .font(.playfair(14, weight: .black))
                .foregroundStyle(Color(hex: "#78716C"))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(venue).font(.lora(10)).foregroundStyle(.secondary)
                    Text(opponent?.name ?? "TBD")
                        .font(.lora(12, weight: .bold))
                }
                HStack(spacing: 6) {
                    if game.isConferenceGame {
                        Text("conf").font(.loraItalic(9))
                            .foregroundStyle(Color(hex: "#78716C"))
                    }
                    if game.isPlayoff {
                        Text("PLAYOFF")
                            .font(.lora(8, weight: .bold))
                            .kerning(0.8)
                            .foregroundStyle(Color(hex: "#B45309"))
                    }
                }
            }

            Spacer()

            if game.isPlayed {
                let myScore = isHome ? game.homeScore ?? 0 : game.awayScore ?? 0
                let oppScore = isHome ? game.awayScore ?? 0 : game.homeScore ?? 0
                let won = myScore > oppScore
                HStack(spacing: 6) {
                    Badge(
                        text: won ? "W" : "L",
                        color: .white,
                        bg: won ? Color(hex: "#15803D") : Color(hex: "#B91C1C")
                    )
                    Text("\(myScore)-\(oppScore)")
                        .font(.lora(12, weight: .bold))
                        .monospacedDigit()
                }
            } else {
                Text("Upcoming")
                    .font(.lora(9, weight: .semibold))
                    .kerning(0.8)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
