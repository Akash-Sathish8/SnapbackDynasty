import SwiftUI
import SwiftData

struct PlayerDetailView: View {
    let player: Player
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]
    @Query private var seasonStats: [PlayerSeasonStats]

    private var primary: Color { Color(hex: player.team?.primaryColor ?? "#1C1917") }

    private var currentStats: PlayerSeasonStats? {
        guard let season = seasons.first else { return nil }
        return seasonStats.first { $0.player === player && $0.season === season }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerCard
                attributesCard
                statsCard
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationTitle(player.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.fullName)
                        .font(.playfair(22, weight: .black))
                    Text("\(player.position.rawValue) · \(player.classYear.rawValue) · \(player.homeState)")
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                    StarRating(stars: player.stars, size: 12)
                        .padding(.top, 2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(player.overall)")
                        .font(.playfair(36, weight: .black))
                        .foregroundStyle(primary)
                    Text("OVR")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var attributesCard: some View {
        Card {
            SectionLabel("Attributes")
            VStack(spacing: 10) {
                AttributeBar(label: "Speed", value: player.speed, potential: player.potential)
                AttributeBar(label: "Strength", value: player.strength, potential: player.potential)
                AttributeBar(label: "Awareness", value: player.awareness, potential: player.potential)
            }
            .padding(.top, 4)

            HStack {
                Text("Potential").font(.lora(10, weight: .semibold))
                    .kerning(1).foregroundStyle(.secondary)
                Spacer()
                Text("\(player.potential)")
                    .font(.playfair(14, weight: .black))
                    .foregroundStyle(
                        player.potential > player.overall + 5 ?
                            Color(hex: "#15803D") : Color(hex: "#1C1917")
                    )
            }
            .padding(.top, 8)
        }
    }

    private var statsCard: some View {
        Card {
            SectionLabel("\(seasons.first?.year.formatted(.number.grouping(.never)) ?? "") Season")
            if let stats = currentStats, stats.gamesPlayed > 0 {
                statsRows(stats)
            } else {
                Text("No games played yet.")
                    .font(.lora(11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func statsRows(_ s: PlayerSeasonStats) -> some View {
        switch player.position {
        case .QB:
            statLine("Games", "\(s.gamesPlayed)")
            statLine("Comp/Att",
                     "\(s.passCompletions)/\(s.passAttempts)  (\(Int(Double(s.passCompletions) / max(1, Double(s.passAttempts)) * 100))%)")
            statLine("Pass Yds", "\(s.passYards)")
            statLine("Pass TDs", "\(s.passTDs)")
            statLine("INTs", "\(s.interceptionsThrown)")
            statLine("Rush Yds", "\(s.rushYards)")
            statLine("Rush TDs", "\(s.rushTDs)")
        case .RB:
            statLine("Games", "\(s.gamesPlayed)")
            statLine("Carries", "\(s.rushAttempts)")
            statLine("Rush Yds", "\(s.rushYards)")
            statLine("YPC", String(format: "%.1f",
                Double(s.rushYards) / max(1, Double(s.rushAttempts))))
            statLine("Rush TDs", "\(s.rushTDs)")
            if s.receptions > 0 {
                statLine("Receptions", "\(s.receptions)")
                statLine("Rec Yds", "\(s.recYards)")
            }
        case .WR, .TE:
            statLine("Games", "\(s.gamesPlayed)")
            statLine("Receptions", "\(s.receptions)")
            statLine("Rec Yds", "\(s.recYards)")
            statLine("YPR", String(format: "%.1f",
                Double(s.recYards) / max(1, Double(s.receptions))))
            statLine("Rec TDs", "\(s.recTDs)")
        case .DL, .LB, .CB, .S:
            statLine("Games", "\(s.gamesPlayed)")
            statLine("Tackles", "\(s.tackles)")
            if s.sacks > 0 { statLine("Sacks", String(format: "%.1f", s.sacks)) }
            if s.interceptions > 0 { statLine("INTs", "\(s.interceptions)") }
        default:
            statLine("Games", "\(s.gamesPlayed)")
        }
    }

    private func statLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.lora(11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.lora(12, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color(hex: "#1C1917"))
        }
        .padding(.vertical, 4)
    }
}
