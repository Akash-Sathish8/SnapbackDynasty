import Foundation
import SwiftData

class SeasonManager {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Schedule generation

    func generateSchedule(season: Season, teams: [Team]) {
        // Group by conference
        var confTeams: [String: [Team]] = [:]
        for t in teams {
            if let conf = t.conference {
                confTeams[conf.name, default: []].append(t)
            }
        }

        var allGames: [(Team, Team, Bool)] = [] // home, away, isConference

        // Conference schedule: each team plays up to 8 random conference opponents
        // (real CFB plays 8-9 conf games; small conferences play full round-robin).
        let maxConfGames = 8
        for (_, members) in confTeams {
            if members.count <= maxConfGames + 1 {
                // Small enough for full round-robin
                for i in 0..<members.count {
                    for j in (i+1)..<members.count {
                        let homeFirst = Bool.random()
                        let home = homeFirst ? members[i] : members[j]
                        let away = homeFirst ? members[j] : members[i]
                        allGames.append((home, away, true))
                    }
                }
            } else {
                // Partial schedule: random pairs, cap each team at maxConfGames
                var confGameCount: [String: Int] = [:]
                for t in members { confGameCount[t.name] = 0 }
                var pairedSet: Set<String> = []

                // Iterate randomly; attempt to give each team maxConfGames
                for _ in 0..<500 {
                    let shuffled = members.shuffled()
                    for i in 0..<shuffled.count {
                        let t1 = shuffled[i]
                        guard (confGameCount[t1.name] ?? 0) < maxConfGames else { continue }
                        for j in (i+1)..<shuffled.count {
                            let t2 = shuffled[j]
                            guard (confGameCount[t2.name] ?? 0) < maxConfGames else { continue }
                            let pairKey = [t1.name, t2.name].sorted().joined(separator: "|")
                            guard !pairedSet.contains(pairKey) else { continue }
                            let home = Bool.random() ? t1 : t2
                            let away = home.name == t1.name ? t2 : t1
                            allGames.append((home, away, true))
                            confGameCount[t1.name, default: 0] += 1
                            confGameCount[t2.name, default: 0] += 1
                            pairedSet.insert(pairKey)
                            break
                        }
                    }
                    // Done if everyone has enough
                    if (confGameCount.values.min() ?? 0) >= maxConfGames { break }
                }
            }
        }

        // Build a unified Set of all paired matchups (sorted names) for O(1) duplicate checks.
        var scheduledPairs: Set<String> = pairedSet  // pairedSet already has all conf pairings
        for (h, a, _) in allGames {
            scheduledPairs.insert([h.name, a.name].sorted().joined(separator: "|"))
        }

        // Track how many games each team has
        var gameCounts: [String: Int] = [:]
        for t in teams { gameCounts[t.name] = 0 }
        for (h, a, _) in allGames {
            gameCounts[h.name, default: 0] += 1
            gameCounts[a.name, default: 0] += 1
        }

        // Fill non-conference to reach 10 games per team
        var allTeamsList = teams.shuffled()
        for _ in 0..<200 {
            allTeamsList.shuffle()
            var added = false
            for i in 0..<allTeamsList.count {
                let t1 = allTeamsList[i]
                guard (gameCounts[t1.name] ?? 0) < 10 else { continue }
                for j in (i+1)..<allTeamsList.count {
                    let t2 = allTeamsList[j]
                    guard (gameCounts[t2.name] ?? 0) < 10 else { continue }
                    let pairKey = [t1.name, t2.name].sorted().joined(separator: "|")
                    guard !scheduledPairs.contains(pairKey) else { continue }
                    let sameConf = t1.conference?.name == t2.conference?.name && t1.conference != nil
                    guard !sameConf else { continue }

                    let home = Bool.random() ? t1 : t2
                    let away = home.name == t1.name ? t2 : t1
                    allGames.append((home, away, false))
                    scheduledPairs.insert(pairKey)
                    gameCounts[t1.name, default: 0] += 1
                    gameCounts[t2.name, default: 0] += 1
                    added = true
                    break
                }
                if added { break }
            }
            if !added {
                let minGames = gameCounts.values.min() ?? 10
                if minGames >= 9 { break }
                let under = allTeamsList.filter { (gameCounts[$0.name] ?? 0) < 10 }
                if under.count >= 2 {
                    let pairKey = [under[0].name, under[1].name].sorted().joined(separator: "|")
                    allGames.append((under[0], under[1], false))
                    scheduledPairs.insert(pairKey)
                    gameCounts[under[0].name, default: 0] += 1
                    gameCounts[under[1].name, default: 0] += 1
                } else { break }
            }
        }

        // Assign weeks
        var teamWeeks: [String: Set<Int>] = [:]
        for t in teams { teamWeeks[t.name] = [] }

        // Conference games → weeks 2-10, non-conference → weeks 1-3
        var confGames = allGames.filter { $0.2 }.shuffled()
        var ncGames = allGames.filter { !$0.2 }.shuffled()

        func assign(_ game: (Team, Team, Bool), weekRange: ClosedRange<Int>) -> Bool {
            for w in weekRange.shuffled() {
                if !(teamWeeks[game.0.name]?.contains(w) ?? false) &&
                   !(teamWeeks[game.1.name]?.contains(w) ?? false) {
                    let g = Game(week: w)
                    g.season = season
                    g.homeTeam = game.0
                    g.awayTeam = game.1
                    g.isConferenceGame = game.2
                    context.insert(g)
                    teamWeeks[game.0.name]?.insert(w)
                    teamWeeks[game.1.name]?.insert(w)
                    return true
                }
            }
            return false
        }

        // Assign non-conference first (weeks 1-3)
        for g in ncGames {
            if !assign(g, weekRange: 1...3) {
                _ = assign(g, weekRange: 1...10)  // overflow to any week
            }
        }
        // Conference games (weeks 2-10)
        for g in confGames {
            if !assign(g, weekRange: 2...10) {
                _ = assign(g, weekRange: 1...10)
            }
        }

        try? context.save()
    }

    // MARK: - Sim week

    func simulateWeek(season: Season, week: Int) -> [(Game, GameResult)] {
        let descriptor = FetchDescriptor<Game>(predicate: #Predicate {
            $0.week == week && $0.isPlayed == false
        })
        guard let games = try? context.fetch(descriptor) else { return [] }
        let weekGames = games.filter { $0.season?.id == season.id }

        var results: [(Game, GameResult)] = []
        for game in weekGames {
            guard let homeTeam = game.homeTeam, let awayTeam = game.awayTeam else { continue }
            let homeSnap = homeTeam.snapshot()
            let awaySnap = awayTeam.snapshot()
            let sim = GameSimulator(home: homeSnap, away: awaySnap, isNeutral: game.isPlayoff)
            let result = sim.simulate()

            game.homeScore = result.homeScore
            game.awayScore = result.awayScore
            game.isPlayed = true
            StatEstimator.persistGameStats(game: game, season: season, context: context)

            // Update records
            if result.homeScore > result.awayScore {
                homeTeam.wins += 1; awayTeam.losses += 1
                if game.isConferenceGame { homeTeam.conferenceWins += 1; awayTeam.conferenceLosses += 1 }
            } else {
                awayTeam.wins += 1; homeTeam.losses += 1
                if game.isConferenceGame { awayTeam.conferenceWins += 1; homeTeam.conferenceLosses += 1 }
            }

            // Injuries (3.5% per starter per game)
            for team in [homeTeam, awayTeam] {
                for player in team.players where player.isStarter && !player.isInjured {
                    if Double.random(in: 0...1) < 0.035 {
                        player.isInjured = true
                        let roll = Double.random(in: 0...1)
                        if roll < 0.50 { player.injuryWeeks = 1 }
                        else if roll < 0.80 { player.injuryWeeks = Int.random(in: 2...3) }
                        else if roll < 0.95 { player.injuryWeeks = Int.random(in: 4...6) }
                        else { player.injuryWeeks = 99 } // season-ending
                    }
                }
                // Heal injuries
                for player in team.players where player.isInjured && player.injuryWeeks < 99 {
                    player.injuryWeeks -= 1
                    if player.injuryWeeks <= 0 {
                        player.isInjured = false
                        player.injuryWeeks = 0
                    }
                }
            }

            results.append((game, result))
        }

        season.currentWeek = week
        try? context.save()
        return results
    }

    // MARK: - Rankings

    func getRankings(season: Season, teams: [Team]) -> [(Team, Double)] {
        // Pre-compute all per-team stats in a single pass to avoid O(teams × games) fetches.
        let playedGames = fetchGames(for: season).filter(\.isPlayed)
        var ptFor:     [String: Int]    = [:]
        var ptAgainst: [String: Int]    = [:]
        var oppLegacy: [String: [Int]]  = [:]

        for g in playedGames {
            guard let home = g.homeTeam, let away = g.awayTeam,
                  let hScore = g.homeScore, let aScore = g.awayScore else { continue }
            ptFor[home.name,     default: 0]  += hScore
            ptAgainst[home.name, default: 0]  += aScore
            ptFor[away.name,     default: 0]  += aScore
            ptAgainst[away.name, default: 0]  += hScore
            oppLegacy[home.name, default: []].append(away.legacy)
            oppLegacy[away.name, default: []].append(home.legacy)
        }

        return teams.map { team in
            let gamesPlayed = team.wins + team.losses
            guard gamesPlayed > 0 else { return (team, Double(team.legacy) * 0.25) }

            let opponents = oppLegacy[team.name] ?? []
            let sos = opponents.isEmpty ? 0.0
                : Double(opponents.reduce(0, +)) / Double(opponents.count) / 100.0
            let diff = Double((ptFor[team.name] ?? 0) - (ptAgainst[team.name] ?? 0))
            let power = Double(team.wins) * 12
                - Double(team.losses) * 8
                + Double(team.legacy) * 0.25
                + sos * 6
                + diff / Double(gamesPlayed) * 1.5
                + Double(team.conferenceWins) * 2
            return (team, power)
        }.sorted { $0.1 > $1.1 }
    }

    // MARK: - Standings

    func getStandings(teams: [Team]) -> [String: [Team]] {
        var confTeams: [String: [Team]] = [:]
        for t in teams {
            let conf = t.conference?.name ?? "Independent"
            confTeams[conf, default: []].append(t)
        }
        for (key, members) in confTeams {
            confTeams[key] = members.sorted {
                if $0.conferenceWins != $1.conferenceWins { return $0.conferenceWins > $1.conferenceWins }
                if $0.conferenceLosses != $1.conferenceLosses { return $0.conferenceLosses < $1.conferenceLosses }
                if $0.wins != $1.wins { return $0.wins > $1.wins }
                return $0.legacy > $1.legacy
            }
        }
        return confTeams
    }

    // MARK: - Conference Championships

    func simulateConferenceChampionships(season: Season, teams: [Team]) -> [(Game, GameResult)] {
        let standings = getStandings(teams: teams)
        var results: [(Game, GameResult)] = []

        for (confName, members) in standings {
            guard confName != "Independent" && members.count >= 2 else { continue }
            let t1 = members[0], t2 = members[1]
            let game = Game(week: 11)
            game.season = season
            game.homeTeam = t1
            game.awayTeam = t2
            game.isConferenceGame = true
            context.insert(game)

            let sim = GameSimulator(home: t1.snapshot(), away: t2.snapshot())
            let result = sim.simulate()
            game.homeScore = result.homeScore
            game.awayScore = result.awayScore
            game.isPlayed = true
            StatEstimator.persistGameStats(game: game, season: season, context: context)

            if result.homeScore > result.awayScore {
                t1.wins += 1; t2.losses += 1; t1.conferenceWins += 1; t2.conferenceLosses += 1
                t1.legacy = min(99, t1.legacy + 2)
            } else {
                t2.wins += 1; t1.losses += 1; t2.conferenceWins += 1; t1.conferenceLosses += 1
                t2.legacy = min(99, t2.legacy + 2)
            }
            results.append((game, result))
        }

        season.currentWeek = 11
        try? context.save()
        return results
    }

    // MARK: - Playoff

    func simulatePlayoff(season: Season, teams: [Team]) -> [(Game, GameResult)] {
        let rankings = getRankings(season: season, teams: teams)
        guard rankings.count >= 4 else { return [] }

        let seed1 = rankings[0].0, seed2 = rankings[1].0
        let seed3 = rankings[2].0, seed4 = rankings[3].0

        var results: [(Game, GameResult)] = []

        // Semifinals (week 12)
        let semi1 = Game(week: 12)
        semi1.season = season; semi1.homeTeam = seed1; semi1.awayTeam = seed4; semi1.isPlayoff = true
        context.insert(semi1)
        let r1 = GameSimulator(home: seed1.snapshot(), away: seed4.snapshot()).simulate()
        semi1.homeScore = r1.homeScore; semi1.awayScore = r1.awayScore; semi1.isPlayed = true
        let winner1 = r1.homeScore > r1.awayScore ? seed1 : seed4
        results.append((semi1, r1))

        let semi2 = Game(week: 12)
        semi2.season = season; semi2.homeTeam = seed2; semi2.awayTeam = seed3; semi2.isPlayoff = true
        context.insert(semi2)
        let r2 = GameSimulator(home: seed2.snapshot(), away: seed3.snapshot()).simulate()
        semi2.homeScore = r2.homeScore; semi2.awayScore = r2.awayScore; semi2.isPlayed = true
        let winner2 = r2.homeScore > r2.awayScore ? seed2 : seed3
        results.append((semi2, r2))

        // Update records
        for (game, result) in [(semi1, r1), (semi2, r2)] {
            if result.homeScore > result.awayScore {
                game.homeTeam?.wins += 1; game.awayTeam?.losses += 1
            } else {
                game.awayTeam?.wins += 1; game.homeTeam?.losses += 1
            }
        }

        season.currentWeek = 12

        // Championship (week 13, neutral site)
        let final_ = Game(week: 13)
        final_.season = season; final_.homeTeam = winner1; final_.awayTeam = winner2; final_.isPlayoff = true
        context.insert(final_)
        let r3 = GameSimulator(home: winner1.snapshot(), away: winner2.snapshot(), isNeutral: true).simulate()
        final_.homeScore = r3.homeScore; final_.awayScore = r3.awayScore; final_.isPlayed = true
        results.append((final_, r3))

        let champion = r3.homeScore > r3.awayScore ? winner1 : winner2
        let runnerUp = r3.homeScore > r3.awayScore ? winner2 : winner1
        champion.wins += 1; runnerUp.losses += 1
        champion.legacy = min(99, champion.legacy + 8)
        runnerUp.legacy = min(99, runnerUp.legacy + 4)
        // Semifinalist bonuses
        seed1.legacy = min(99, seed1.legacy + 3)
        seed2.legacy = min(99, seed2.legacy + 3)
        seed3.legacy = min(99, seed3.legacy + 3)
        seed4.legacy = min(99, seed4.legacy + 3)

        season.currentWeek = 13
        try? context.save()
        return results
    }

    // MARK: - Helpers

    func fetchGames(for season: Season) -> [Game] {
        let descriptor = FetchDescriptor<Game>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.season?.id == season.id }
    }

    func gamesForTeam(_ team: Team, season: Season) -> [Game] {
        fetchGames(for: season).filter {
            $0.homeTeam?.name == team.name || $0.awayTeam?.name == team.name
        }.sorted { $0.week < $1.week }
    }

    func nextWeek(season: Season) -> Int? {
        let games = fetchGames(for: season)
        let unplayed = games.filter { !$0.isPlayed }
        return unplayed.map(\.week).min()
    }

    func allWeeksPlayed(season: Season) -> Bool {
        let games = fetchGames(for: season)
        return !games.isEmpty && games.allSatisfy(\.isPlayed)
    }
}
