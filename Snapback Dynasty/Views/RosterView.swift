import SwiftUI
import SwiftData

struct RosterView: View {
    let team: Team
    @State private var selectedGroup = "Offense"
    private let groups = ["Offense", "Defense", "Special"]

    private var offensePositions: [Position] { [.QB, .RB, .WR, .TE, .OL] }
    private var defensePositions: [Position] { [.DL, .LB, .CB, .S] }
    private var specialPositions: [Position] { [.K, .P] }

    private var activePositions: [Position] {
        switch selectedGroup {
        case "Offense": return offensePositions
        case "Defense": return defensePositions
        default: return specialPositions
        }
    }

    private var primary: Color { Color(hex: team.primaryColor) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Group", selection: $selectedGroup) {
                    ForEach(groups, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                ForEach(activePositions, id: \.rawValue) { pos in
                    positionCard(pos)
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationTitle("Roster")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func positionCard(_ pos: Position) -> some View {
        let players = team.players
            .filter { $0.position == pos }
            .sorted { $0.overall > $1.overall }
        if !players.isEmpty {
            Card {
                SectionLabel("\(pos.rawValue) · \(players.count)")

                HStack(spacing: 0) {
                    Text("PLAYER")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("OVR")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                        .frame(width: 36)
                    Text("SPD")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                    Text("STR")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                    Text("AWR")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                }
                .padding(.vertical, 6)

                ForEach(Array(players.enumerated()), id: \.offset) { idx, player in
                    NavigationLink {
                        PlayerDetailView(player: player)
                    } label: {
                        playerRow(player)
                    }
                    .buttonStyle(.plain)
                    if idx < players.count - 1 {
                        Rectangle().fill(Color(hex: "#F5F3F0")).frame(height: 1)
                    }
                }
            }
        }
    }

    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 10) {
            PlayerAvatar(player: player, size: 32)
                .overlay(
                    Circle()
                        .stroke(player.isStarter ? primary : Color.clear, lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(player.fullName)
                        .font(.lora(12, weight: player.isStarter ? .bold : .regular))
                    if player.isInjured {
                        Image(systemName: "cross.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "#B91C1C"))
                    }
                }
                Text("\(player.classYear.rawValue) · \(player.homeState)")
                    .font(.lora(9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(player.overall)")
                .font(.playfair(14, weight: .black))
                .foregroundStyle(player.overall >= 80 ? primary : Color(hex: "#1C1917"))
                .frame(width: 36)

            Text("\(player.speed)")
                .font(.lora(10, weight: .semibold))
                .foregroundStyle(Color(hex: "#78716C"))
                .frame(width: 30)

            Text("\(player.strength)")
                .font(.lora(10, weight: .semibold))
                .foregroundStyle(Color(hex: "#78716C"))
                .frame(width: 30)

            Text("\(player.awareness)")
                .font(.lora(10, weight: .semibold))
                .foregroundStyle(Color(hex: "#78716C"))
                .frame(width: 30)
        }
        .padding(.vertical, 6)
        .background(
            player.isStarter ? primary.opacity(0.04) : .clear
        )
    }
}
