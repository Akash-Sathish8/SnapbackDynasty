import SwiftUI
import SwiftData
import Combine

struct TeamPickerView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @State private var searchText = ""
    @State private var isSeeding = false
    @State private var selectedConference: String = "All"
    @State private var confirmingTeam: Team?
    @State private var taglineIndex = 0
    @Query(sort: \Team.legacy, order: .reverse) private var teams: [Team]

    /// Rotating taglines on the start screen.
    private let taglines: [String] = [
        "College football, year after year.",
        "Build your dynasty. One season at a time.",
        "Recruit hard. Coach harder.",
        "Every Saturday matters.",
        "Pack the stadium. Win the day.",
        "Rivalries. Tradition. Legacy.",
        "The road to the Heisman starts here.",
        "From the recruit trail to the title game.",
        "Your program. Your decade.",
        "Where tradition is forged.",
        "Saturday in the South.",
        "The fight song never stops.",
    ]

    /// Pre-shuffled list of all 136 FBS team logo URLs (from static seed data).
    private static let logoURLs: [String] = {
        conferenceSeeds.flatMap { $0.teams.map(\.logoURL) }.shuffled()
    }()

    private var conferences: [String] {
        var set = Set(teams.compactMap { $0.conference?.name })
        return ["All"] + set.sorted()
    }

    var filteredTeams: [Team] {
        var list = teams
        if selectedConference != "All" {
            list = list.filter { $0.conference?.name == selectedConference }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.mascot.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if teams.isEmpty {
                    FootballFieldBackground().ignoresSafeArea()
                    startScreen
                } else {
                    Color(hex: "#FAF8F4").ignoresSafeArea()
                    teamList
                }
            }
        }
    }

    // MARK: - Start

    private var startScreen: some View {
        VStack(spacing: 0) {
            Spacer().frame(maxHeight: .infinity)

            VStack(spacing: 8) {
                Text("SNAPBACK")
                    .font(.playfair(44, weight: .black))
                    .foregroundStyle(Color(hex: "#1C1917"))
                Text("DYNASTY")
                    .font(.playfair(36, weight: .black))
                    .foregroundStyle(Color(hex: "#B45309"))
            }

            Text(taglines[taglineIndex])
                .font(.loraItalic(14))
                .foregroundStyle(Color(hex: "#78716C"))
                .multilineTextAlignment(.center)
                .id(taglineIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.6), value: taglineIndex)
                .frame(height: 24)
                .padding(.top, 12)
                .onReceive(
                    Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()
                ) { _ in
                    taglineIndex = (taglineIndex + 1) % taglines.count
                }

            Spacer().frame(maxHeight: .infinity)

            // Logo marquee — halfway between title and start button
            LogoMarquee()
                .frame(height: 56)
                .opacity(0.42)

            Spacer().frame(maxHeight: .infinity)

            Button {
                isSeeding = true
                Task {
                    seedDatabase()
                    isSeeding = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isSeeding { ProgressView().tint(.white) }
                    Text(isSeeding ? "Building dynasty…" : "START NEW DYNASTY")
                        .font(.lora(13, weight: .bold))
                        .kerning(1.5)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#1C1917"), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isSeeding)
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Team list

    private var teamList: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("SNAPBACK DYNASTY")
                    .font(.lora(9, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(Color(hex: "#78716C"))
                Text("Choose Your Program")
                    .font(.playfair(26, weight: .black))
                    .foregroundStyle(Color(hex: "#1C1917"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Conference chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(conferences, id: \.self) { conf in
                        Button {
                            selectedConference = conf
                        } label: {
                            Text(conf)
                                .font(.lora(11, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    conf == selectedConference
                                        ? Color(hex: "#1C1917")
                                        : Color.white,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
                                .foregroundStyle(
                                    conf == selectedConference ? .white : Color(hex: "#1C1917")
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Team list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTeams, id: \.persistentModelID) { team in
                        Button {
                            confirmingTeam = team
                        } label: {
                            teamCard(team)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
        .searchable(text: $searchText, prompt: "Search teams…")
        .sheet(item: Binding(
            get: { confirmingTeam },
            set: { confirmingTeam = $0 }
        )) { team in
            confirmationSheet(team: team)
        }
    }

    private func teamCard(_ team: Team) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: team.primaryColor))
                Text(team.abbreviation)
                    .font(.playfair(11, weight: .black))
                    .foregroundStyle(
                        isLightHex(team.primaryColor) ? Color(hex: "#1C1917") : .white
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 4)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.name)
                    .font(.playfair(15, weight: .black))
                    .foregroundStyle(Color(hex: "#1C1917"))
                Text("\(team.mascot) · \(team.conference?.name ?? "")")
                    .font(.lora(10))
                    .foregroundStyle(Color(hex: "#78716C"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(team.legacy)")
                    .font(.playfair(18, weight: .black))
                    .foregroundStyle(Color(hex: team.primaryColor))
                Text("LEGACY")
                    .font(.lora(7, weight: .semibold))
                    .kerning(1)
                    .foregroundStyle(Color(hex: "#78716C"))
            }
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
    }

    // MARK: - Confirmation sheet

    private func confirmationSheet(team: Team) -> some View {
        VStack(spacing: 18) {
            // Team header
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: team.primaryColor),
                        Color(hex: darkenHex(team.primaryColor, by: 0.4))
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                VStack(spacing: 4) {
                    Text(team.name)
                        .font(.playfair(28, weight: .black))
                    Text(team.mascot)
                        .font(.loraItalic(14))
                        .opacity(0.8)
                }
                .foregroundStyle(
                    isLightHex(team.primaryColor) ? Color(hex: "#1C1917") : .white
                )
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 28) {
                detailStat(label: "LEGACY", value: "\(team.legacy)")
                detailStat(label: "CONF", value: team.conference?.name ?? "IND")
                detailStat(label: "STATE", value: team.homeState)
            }

            Text("Start a multi-season dynasty. Recruit, develop, and win titles.")
                .font(.lora(12))
                .foregroundStyle(Color(hex: "#78716C"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            Button {
                playerTeamName = team.name
                confirmingTeam = nil
            } label: {
                Text("START DYNASTY")
                    .font(.lora(13, weight: .bold))
                    .kerning(1.5)
                    .foregroundStyle(
                        isLightHex(team.primaryColor) ? Color(hex: "#1C1917") : .white
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: team.primaryColor),
                                in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .background(Color(hex: "#FAF8F4"))
        .presentationDetents([.medium])
    }

    private func detailStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.playfair(18, weight: .black))
                .foregroundStyle(Color(hex: "#1C1917"))
            Text(label)
                .font(.lora(8, weight: .semibold))
                .kerning(1)
                .foregroundStyle(Color(hex: "#78716C"))
        }
    }

    // MARK: - Seeding

    private func seedDatabase() {
        var teamsSeeded = 0
        for cs in conferenceSeeds {
            let conf = Conference(name: cs.name, fullName: cs.fullName)
            context.insert(conf)

            for ts in cs.teams {
                let team = Team(name: ts.name, mascot: ts.mascot,
                                abbreviation: ts.abbreviation, legacy: ts.legacy,
                                homeState: ts.homeState, primaryColor: ts.primaryColor,
                                logoURL: ts.logoURL)
                team.conference = conf
                context.insert(team)

                let staff = CoachingStaff(
                    offenseBonus: Int.random(in: -2...8),
                    defenseBonus: Int.random(in: -2...8),
                    recruitingBonus: Int.random(in: -2...8),
                    developmentBonus: Int.random(in: -2...8))
                staff.team = team
                team.coachingStaff = staff
                context.insert(staff)

                for pos in Position.allCases {
                    for _ in 0..<pos.rosterCount {
                        let baseMean = 45.0 + Double(team.legacy) * 0.35
                        let spd = max(25, min(99, Int(gaussRandom(mean: baseMean, std: 8))))
                        let str = max(25, min(99, Int(gaussRandom(mean: baseMean, std: 8))))
                        let awr = max(25, min(99, Int(gaussRandom(mean: baseMean, std: 8))))
                        let pot = max(40, min(99, Int(gaussRandom(mean: Double(spd+str+awr)/3 + 5, std: 12))))
                        let years: [ClassYear] = [.FR,.FR,.FR,.SO,.SO,.SO,.JR,.JR,.JR,.SR,.SR]
                        let p = Player(firstName: firstNames.randomElement()!,
                                       lastName: lastNames.randomElement()!,
                                       position: pos, year: years.randomElement()!,
                                       speed: spd, strength: str, awareness: awr,
                                       potential: pot, homeState: team.homeState)
                        p.team = team
                        context.insert(p)
                    }
                }

                teamsSeeded += 1
                if teamsSeeded % 20 == 0 { try? context.save() }

                for pos in Position.allCases {
                    let sorted = team.players.filter { $0.position == pos }
                        .sorted { $0.overall > $1.overall }
                    for (i, p) in sorted.enumerated() {
                        p.isStarter = i < pos.starterCount
                    }
                }
            }
        }

        let season = Season(year: 2026)
        context.insert(season)

        let allTeams = (try? context.fetch(FetchDescriptor<Team>())) ?? []
        SchoolGradeEngine.seedAll(teams: allTeams, context: context)
        RecruitGenerator.generateClass(into: context, classYear: season.year + 1)
        season.recruitingHoursRemaining = 0
        try? context.save()
    }
}
