import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query(sort: \Team.legacy, order: .reverse) private var allTeams: [Team]
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]

    @State private var isSimming = false
    @State private var liveGameBundle: LiveGameBundle?
    @State private var weekResults: [(Game, GameResult)] = []
    @State private var showWeekResults = false
    @State private var showPlayComingSoon = false
    @State private var showGameplay = false

    /// Bundles what LiveGameView needs so `fullScreenCover(item:)` can drive it.
    struct LiveGameBundle: Identifiable {
        let id = UUID()
        let home: TeamSnap
        let away: TeamSnap
        let result: GameResult
    }

    var playerTeam: Team? { allTeams.first { $0.name == playerTeamName } }
    var season: Season? { seasons.first }

    private var manager: SeasonManager { SeasonManager(context: context) }

    private var hasSchedule: Bool {
        guard let season else { return false }
        return !manager.fetchGames(for: season).isEmpty
    }

    private var nextWeek: Int? {
        guard let season else { return nil }
        return manager.nextWeek(season: season)
    }

    private var allPlayed: Bool {
        guard let season else { return false }
        return hasSchedule && manager.allWeeksPlayed(season: season)
    }

    private var primary: Color { Color(hex: playerTeam?.primaryColor ?? "#7BAFD4") }
    private var secondary: Color {
        Color(hex: darkenHex(playerTeam?.primaryColor ?? "#7BAFD4", by: 0.4))
    }

    var body: some View {
        NavigationStack {
            if let team = playerTeam, let season = season {
                ScrollView {
                    VStack(spacing: 12) {
                        heroCard(team: team, season: season)
                        nextGameCard(team: team, season: season)
                        keyPlayersCard(team: team)
                        quickLinksGrid(team: team, season: season)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "#FAF8F4"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .fullScreenCover(item: $liveGameBundle) { bundle in
                    LiveGameView(
                        homeTeam: bundle.home,
                        awayTeam: bundle.away,
                        result: bundle.result,
                        onDismiss: { liveGameBundle = nil }
                    )
                }
                .fullScreenCover(isPresented: $showGameplay) {
                    if let week = nextWeek,
                       let game = findPlayerGame(week: week),
                       let opp = opponentTeam(for: game, playerTeam: team) {
                        GameplayView(
                            homeTeamName: team.abbreviation,
                            awayTeamName: opp.abbreviation,
                            homeColor: team.primaryColor,
                            awayColor: opp.primaryColor,
                            homeLogo: team.logoURL,
                            homeRoster: GameplayRoster.from(team: team),
                            awayRoster: GameplayRoster.from(team: opp)
                        ) { homeScore, awayScore in
                            savePlayedGame(game: game, playerTeam: team,
                                           playerScore: homeScore, oppScore: awayScore)
                            showGameplay = false
                        }
                    } else {
                        GameplayView(
                            homeTeamName: team.abbreviation,
                            awayTeamName: "OPP",
                            homeColor: team.primaryColor,
                            awayColor: "#444444",
                            homeLogo: team.logoURL,
                            homeRoster: GameplayRoster.from(team: team)
                        ) { _, _ in showGameplay = false }
                    }
                }
            } else {
                Text("Loading…").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Hero card

    @ViewBuilder
    private func heroCard(team: Team, season: Season) -> some View {
        let textColor: Color = isLightHex(team.primaryColor) ? Color(hex: "#1C1917") : .white
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [primary, secondary],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Team abbreviation watermark
            Text(team.abbreviation)
                .font(.custom(Theme.fontDisplay, size: 140).weight(.black))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 140, y: 30)

            VStack(alignment: .leading, spacing: 10) {
                Text("SEASON 1 · WEEK \(season.currentWeek)")
                    .font(.lora(9, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(textColor.opacity(0.65))

                Text(team.name)
                    .font(.playfair(26, weight: .black))
                    .foregroundStyle(textColor)

                Text("\(team.mascot) · \(team.conference?.name ?? "")")
                    .font(.lora(12))
                    .foregroundStyle(textColor.opacity(0.75))

                HStack(spacing: 32) {
                    heroStat(label: "RECORD", value: team.record, color: textColor)
                    if let rank = currentRank(team: team) {
                        heroStat(label: "RANK", value: "#\(rank)", color: textColor)
                    }
                    heroStat(label: "LEGACY", value: "\(team.legacy)", color: textColor)
                }
                .padding(.top, 8)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private func heroStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.playfair(22, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.lora(8, weight: .semibold))
                .kerning(1)
                .foregroundStyle(color.opacity(0.55))
        }
    }

    private func currentRank(team: Team) -> Int? {
        guard let season, team.wins + team.losses > 0 else { return nil }
        let rankings = manager.getRankings(season: season, teams: allTeams)
        guard let idx = rankings.prefix(25).firstIndex(where: { $0.0.name == team.name }) else { return nil }
        return idx + 1
    }

    // MARK: - Next game card

    @ViewBuilder
    private func nextGameCard(team: Team, season: Season) -> some View {
        Card {
            SectionLabel("Next Game")

            if !hasSchedule {
                HStack {
                    Text("Generate schedule to begin the season.")
                        .font(.lora(12))
                        .foregroundStyle(Color(hex: "#78716C"))
                    Spacer()
                    Button {
                        isSimming = true
                        // SwiftData ModelContext is NOT thread-safe.
                        // Run on main — schedule gen is ~680 games, fast enough.
                        Task { @MainActor in
                            manager.generateSchedule(season: season, teams: allTeams)
                            isSimming = false
                        }
                    } label: {
                        Text(isSimming ? "…" : "Generate")
                            .font(.lora(11, weight: .bold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(primary, in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(isLightHex(team.primaryColor) ? .black : .white)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSimming)
                }
            } else if let week = nextWeek {
                let game = findPlayerGame(week: week)
                let opp = game.flatMap { opponentTeam(for: $0, playerTeam: team) }
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(opp?.name ?? "Opponent")
                            .font(.playfair(15, weight: .black))
                        Text("Week \(week) · \(game?.isConferenceGame == true ? "Conference" : "Non-Conference")")
                            .font(.lora(10))
                            .foregroundStyle(Color(hex: "#78716C"))
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button { showGameplay = true } label: {
                            Text("Play")
                                .font(.lora(11, weight: .bold))
                                .kerning(0.5)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(primary, in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(isLightHex(team.primaryColor) ? .black : .white)
                        }
                        .buttonStyle(.plain)

                        Button { simWeek(week) } label: {
                            Text(isSimming ? "…" : "Sim")
                                .font(.lora(11, weight: .bold))
                                .kerning(0.5)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
                                .foregroundStyle(Color(hex: "#78716C"))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSimming)
                    }
                }
            } else if allPlayed {
                VStack(spacing: 8) {
                    Text("Season Complete")
                        .font(.lora(12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#15803D"))

                    Button {
                        let summary = OffseasonManager.runOffseason(
                            currentSeason: season, allTeams: allTeams, context: context)
                        print("Offseason complete: graduated \(summary.graduated), developed \(summary.developed), new year \(summary.newSeasonYear)")
                    } label: {
                        Text("Advance to Offseason →")
                            .font(.lora(12, weight: .bold))
                            .kerning(0.5)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(primary, in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(isLightHex(playerTeam?.primaryColor ?? "#7BAFD4") ? .black : .white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Key players card

    @ViewBuilder
    private func keyPlayersCard(team: Team) -> some View {
        Card {
            HStack {
                SectionLabel("Key Players")
                Spacer()
                NavigationLink {
                    RosterView(team: team)
                } label: {
                    Text("View Roster →")
                        .font(.lora(10, weight: .bold))
                        .foregroundStyle(primary)
                }
            }

            let topPlayers = team.players
                .sorted { $0.overall > $1.overall }
                .prefix(4)

            ForEach(Array(topPlayers), id: \.persistentModelID) { player in
                HStack(spacing: 10) {
                    PositionBadge(position: player.positionRaw, size: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.fullName)
                            .font(.lora(12, weight: .bold))
                        Text("\(player.classYear.rawValue) · \(player.homeState)")
                            .font(.lora(9))
                            .foregroundStyle(Color(hex: "#78716C"))
                    }
                    Spacer()
                    Text("\(player.overall)")
                        .font(.playfair(18, weight: .black))
                        .foregroundStyle(player.overall >= 80 ? primary : Color(hex: "#1C1917"))
                }
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    if player !== topPlayers.last {
                        Rectangle().fill(Color(hex: "#F5F3F0"))
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    // MARK: - Quick links grid

    @ViewBuilder
    private func quickLinksGrid(team: Team, season: Season) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            if let week = nextWeek, week <= 10 {
                quickLinkButton(title: "Sim Full Season",
                                icon: "forward.end.fill") {
                    simEntireSeason()
                }
            }
            NavigationLink {
                ScheduleView(team: team, season: season)
            } label: {
                quickLinkTile(title: "Schedule", icon: "calendar")
            }
            .buttonStyle(.plain)

            NavigationLink {
                RankingsView()
            } label: {
                quickLinkTile(title: "Rankings", icon: "trophy.fill")
            }
            .buttonStyle(.plain)

            NavigationLink {
                StandingsView()
            } label: {
                quickLinkTile(title: "Standings", icon: "list.number")
            }
            .buttonStyle(.plain)
        }
    }

    private func quickLinkButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickLinkTile(title: title, icon: icon)
        }
        .buttonStyle(.plain)
        .disabled(isSimming)
    }

    private func quickLinkTile(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(primary)
            Text(title)
                .font(.lora(11, weight: .bold))
                .foregroundStyle(Color(hex: "#1C1917"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
    }

    // MARK: - Sim actions

    private func simWeek(_ week: Int) {
        guard let season else { return }
        isSimming = true
        let results = manager.simulateWeek(season: season, week: week)

        advanceRecruiting(season: season)
        runSigningDaysIfNeeded(week: week, season: season)

        if let playerGame = results.first(where: {
            $0.0.homeTeam?.name == playerTeamName || $0.0.awayTeam?.name == playerTeamName
        }),
           let home = playerGame.0.homeTeam,
           let away = playerGame.0.awayTeam {
            liveGameBundle = LiveGameBundle(
                home: home.snapshot(),
                away: away.snapshot(),
                result: playerGame.1
            )
        }
        isSimming = false
    }

    private func simEntireSeason() {
        guard let season else { return }
        isSimming = true
        while let week = manager.nextWeek(season: season), week <= 10 {
            _ = manager.simulateWeek(season: season, week: week)
            advanceRecruiting(season: season)
            runSigningDaysIfNeeded(week: week, season: season)
        }
        _ = manager.simulateConferenceChampionships(season: season, teams: allTeams)
        _ = manager.simulatePlayoff(season: season, teams: allTeams)

        let recruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
        _ = SigningDay.run(kind: .national, allRecruits: recruits,
                           allTeams: allTeams, context: context)
        isSimming = false
    }

    private func advanceRecruiting(season: Season) {
        let engine = RecruitingEngine(context: context)
        let recruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
        engine.advanceWeek(season: season, playerTeam: playerTeam,
                           allTeams: allTeams, allRecruits: recruits)
    }

    // MARK: - Gameplay integration

    private func findPlayerGame(week: Int) -> Game? {
        guard let season, let team = playerTeam else { return nil }
        return manager.fetchGames(for: season).first { g in
            g.week == week && !g.isPlayed &&
            (g.homeTeam?.name == team.name || g.awayTeam?.name == team.name)
        }
    }

    private func opponentTeam(for game: Game, playerTeam: Team) -> Team? {
        if game.homeTeam?.name == playerTeam.name { return game.awayTeam }
        return game.homeTeam
    }

    private func savePlayedGame(game: Game, playerTeam: Team,
                                 playerScore: Int, oppScore: Int) {
        let playerIsHome = game.homeTeam?.name == playerTeam.name
        if playerIsHome {
            game.homeScore = playerScore
            game.awayScore = oppScore
        } else {
            game.homeScore = oppScore
            game.awayScore = playerScore
        }
        game.isPlayed = true

        if let h = game.homeTeam, let a = game.awayTeam,
           let hScore = game.homeScore, let aScore = game.awayScore {
            if hScore > aScore { h.wins += 1; a.losses += 1 }
            else if aScore > hScore { a.wins += 1; h.losses += 1 }
            if game.isConferenceGame {
                if hScore > aScore { h.conferenceWins += 1; a.conferenceLosses += 1 }
                else if aScore > hScore { a.conferenceWins += 1; h.conferenceLosses += 1 }
            }
        }

        if let season {
            let week = season.currentWeek > 0 ? season.currentWeek : game.week
            _ = manager.simulateWeek(season: season, week: week)
            advanceRecruiting(season: season)
            runSigningDaysIfNeeded(week: week, season: season)
        }

        try? context.save()
    }

    private func runSigningDaysIfNeeded(week: Int, season: Season) {
        if week == 11 {
            let recruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
            _ = SigningDay.run(kind: .early, allRecruits: recruits,
                               allTeams: allTeams, context: context)
        }
    }
}
