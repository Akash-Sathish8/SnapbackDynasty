import SwiftUI
import SwiftData

struct AwardsScreen: View {
    @Query private var allAwards: [Award]

    private var awardsBySeason: [(Int, [Award])] {
        let grouped = Dictionary(grouping: allAwards) { $0.seasonYear }
        return grouped.sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if awardsBySeason.isEmpty {
                    Card {
                        SectionLabel("Awards")
                        Text("Awards will be compiled after your first season ends.")
                            .font(.lora(11))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                    }
                }

                ForEach(awardsBySeason, id: \.0) { year, awards in
                    seasonCard(year: year, awards: awards)
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationTitle("Awards")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func seasonCard(year: Int, awards: [Award]) -> some View {
        Card {
            SectionLabel("\(String(year)) Season")

            // Heisman
            if let heisman = awards.first(where: { $0.type == .heisman }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HEISMAN TROPHY")
                        .font(.lora(9, weight: .bold))
                        .kerning(1.5)
                        .foregroundStyle(Color(hex: "#B45309"))
                    Text(heisman.playerName)
                        .font(.playfair(20, weight: .black))
                    Text("\(heisman.position) · \(heisman.teamAbbreviation)")
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                    Text(heisman.statLine)
                        .font(.loraItalic(12))
                        .foregroundStyle(Color(hex: "#1C1917"))
                }
                .padding(.vertical, 8)
                Divider()
            }

            // All-American
            let aa = awards.filter { $0.type == .allAmerican }
            if !aa.isEmpty {
                Text("ALL-AMERICAN FIRST TEAM")
                    .font(.lora(9, weight: .bold))
                    .kerning(1.5)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                ForEach(aa, id: \.playerName) { award in
                    HStack {
                        Text(award.position)
                            .font(.lora(11, weight: .bold))
                            .frame(width: 32, alignment: .leading)
                            .foregroundStyle(Color(hex: "#78716C"))
                        Text(award.playerName)
                            .font(.lora(12, weight: .semibold))
                        Spacer()
                        Text(award.teamAbbreviation)
                            .font(.lora(11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }
}
