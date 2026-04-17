import SwiftUI
import SwiftData

struct StandingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.legacy, order: .reverse) private var allTeams: [Team]
    @AppStorage("playerTeamName") private var playerTeamName: String = ""

    private var standings: [(String, [Team])] {
        let mgr = SeasonManager(context: context)
        let raw = mgr.getStandings(teams: allTeams)
        return raw.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(standings, id: \.0) { confName, teams in
                    conferenceCard(name: confName, teams: teams)
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationTitle("Standings")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func conferenceCard(name: String, teams: [Team]) -> some View {
        Card {
            SectionLabel(name)

            HStack(spacing: 0) {
                Text("TEAM")
                    .font(.lora(8, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("CONF")
                    .font(.lora(8, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
                Text("OVR")
                    .font(.lora(8, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
            }
            .padding(.vertical, 6)

            ForEach(Array(teams.enumerated()), id: \.offset) { idx, team in
                let isPlayer = team.name == playerTeamName
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: team.primaryColor))
                        .frame(width: 8, height: 8)
                    Text(team.abbreviation)
                        .font(.lora(12, weight: isPlayer ? .bold : .regular))
                    Text(team.name)
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text(team.confRecord)
                        .font(.lora(11, weight: .semibold))
                        .monospacedDigit()
                        .frame(width: 50)
                    Text(team.record)
                        .font(.lora(11, weight: .bold))
                        .monospacedDigit()
                        .frame(width: 50)
                }
                .padding(.vertical, 4)
                .background(
                    isPlayer ? Color(hex: team.primaryColor).opacity(0.08) : .clear
                )
                if idx < teams.count - 1 {
                    Rectangle().fill(Color(hex: "#F5F3F0")).frame(height: 1)
                }
            }
        }
    }
}
