import SwiftUI
import SwiftData

struct DynastyHomeView: View {
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var allTeams: [Team]
    @Query private var allHistory: [DynastyHistory]
    @State private var showSettings = false

    private var playerTeam: Team? { allTeams.first { $0.name == playerTeamName } }
    private var primary: Color { Color(hex: playerTeam?.primaryColor ?? "#1C1917") }

    private var myHistory: [DynastyHistory] {
        guard let team = playerTeam else { return [] }
        return allHistory.filter { $0.team === team }
            .sorted { $0.seasonYear < $1.seasonYear }
    }

    private var totalWins: Int { myHistory.reduce(0) { $0 + $1.wins } }
    private var totalLosses: Int { myHistory.reduce(0) { $0 + $1.losses } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let team = playerTeam {
                        headerCard(team: team)
                        legacyChart
                        if !myHistory.isEmpty {
                            careerCard
                        }
                        yearCards
                        NavigationLink {
                            AwardsScreen()
                        } label: {
                            Card {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        SectionLabel("Awards")
                                        Text("Heisman, All-American, All-Conference")
                                            .font(.lora(11))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Card {
                            Text("Choose a team to begin your dynasty.")
                                .font(.lora(12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(hex: "#FAF8F4"))
            .navigationTitle("Dynasty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                GameSettingsView()
            }
        }
    }

    @ViewBuilder
    private func headerCard(team: Team) -> some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Dynasty")
                    Text("\(team.name) \(team.mascot)")
                        .font(.playfair(20, weight: .black))
                    Text("Year \(myHistory.count + 1) · Head Coach")
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(team.legacy)")
                        .font(.playfair(22, weight: .black))
                        .foregroundStyle(primary)
                    Text("LEGACY")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var legacyChart: some View {
        if !myHistory.isEmpty {
            Card {
                SectionLabel("Legacy Trajectory")
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(myHistory, id: \.seasonYear) { h in
                        VStack(spacing: 4) {
                            Text("\(h.legacyAtEnd)")
                                .font(.playfair(11, weight: .black))
                                .foregroundStyle(primary)
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [primary, primary.opacity(0.6)],
                                    startPoint: .top, endPoint: .bottom))
                                .frame(height: CGFloat(h.legacyAtEnd) * 1.2)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                            Text("'\(String(h.seasonYear).suffix(2))")
                                .font(.lora(8))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 6)
                .frame(height: 150)
            }
        }
    }

    private var careerCard: some View {
        Card {
            SectionLabel("Career")
            HStack(spacing: 28) {
                careerStat(label: "WINS", value: "\(totalWins)", tint: Color(hex: "#15803D"))
                careerStat(label: "LOSSES", value: "\(totalLosses)",
                           tint: Color(hex: "#1C1917"))
                careerStat(label: "WIN %", value: winPct, tint: primary)
                careerStat(label: "SEASONS", value: "\(myHistory.count)",
                           tint: Color(hex: "#1C1917"))
            }
        }
    }

    private var winPct: String {
        let total = totalWins + totalLosses
        guard total > 0 else { return "—" }
        return "\(Int(Double(totalWins) / Double(total) * 100))%"
    }

    private func careerStat(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.playfair(18, weight: .black))
                .foregroundStyle(tint)
            Text(label)
                .font(.lora(8, weight: .semibold))
                .kerning(1)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var yearCards: some View {
        if myHistory.isEmpty {
            Card {
                SectionLabel("History")
                Text("Finish your first season to build your dynasty story.")
                    .font(.lora(11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        } else {
            ForEach(myHistory.reversed(), id: \.seasonYear) { h in
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(String(h.seasonYear))")
                                .font(.playfair(16, weight: .black))
                            Text("Completed")
                                .font(.lora(10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(h.wins)-\(h.losses)")
                                .font(.playfair(20, weight: .black))
                                .foregroundStyle(
                                    h.wins > h.losses ?
                                        Color(hex: "#15803D") : Color(hex: "#1C1917")
                                )
                            Text("Legacy \(h.legacyAtEnd)")
                                .font(.lora(10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if h.wonChampionship || h.madePlayoff {
                        HStack(spacing: 6) {
                            if h.wonChampionship {
                                Badge(text: "CHAMPION", color: .white,
                                      bg: Color(hex: "#B45309"))
                            }
                            if h.madePlayoff {
                                Badge(text: "PLAYOFF", color: .white,
                                      bg: Color(hex: "#15803D"))
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
    }
}
