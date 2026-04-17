import SwiftUI
import SwiftData

struct RankingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.legacy, order: .reverse) private var allTeams: [Team]
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]
    @AppStorage("playerTeamName") private var playerTeamName: String = ""

    private var rankings: [(Int, Team, Double)] {
        guard let season = seasons.first else { return [] }
        let mgr = SeasonManager(context: context)
        let ranked = mgr.getRankings(season: season, teams: allTeams)
        return ranked.prefix(25).enumerated().map { (i, pair) in (i + 1, pair.0, pair.1) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    SectionLabel("AP Top 25")

                    if rankings.isEmpty {
                        Text("Sim at least one week to see rankings.")
                            .font(.lora(11))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(Array(rankings.enumerated()), id: \.offset) { idx, entry in
                            let (rank, team, power) = entry
                            rankRow(rank: rank, team: team, power: power)
                            if idx < rankings.count - 1 {
                                Rectangle().fill(Color(hex: "#F5F3F0")).frame(height: 1)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationTitle("Rankings")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func rankRow(rank: Int, team: Team, power: Double) -> some View {
        let isPlayer = team.name == playerTeamName
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.playfair(14, weight: .black))
                .foregroundStyle(rank <= 4 ? Color(hex: "#B45309") : Color(hex: "#78716C"))
                .frame(width: 22, alignment: .leading)

            Circle()
                .fill(Color(hex: team.primaryColor))
                .frame(width: 10, height: 10)

            Text(team.name)
                .font(.lora(12, weight: isPlayer ? .bold : .semibold))
                .foregroundStyle(isPlayer ? Color(hex: team.primaryColor) : Color(hex: "#1C1917"))

            Spacer()

            Text(team.record)
                .font(.lora(11, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
