import Foundation
import SwiftData

/// Estimates per-player stats from a game's final score + team rosters,
/// then writes PlayerGameStats + aggregates PlayerSeasonStats.
/// Used for auto-simmed games where we don't track play-by-play attribution.
enum StatEstimator {

    static func persistGameStats(game: Game, season: Season, context: ModelContext) {
        guard game.isPlayed,
              let home = game.homeTeam, let away = game.awayTeam,
              let hScore = game.homeScore, let aScore = game.awayScore
        else { return }

        generate(for: home, teamScore: hScore, oppScore: aScore,
                 game: game, season: season, context: context)
        generate(for: away, teamScore: aScore, oppScore: hScore,
                 game: game, season: season, context: context)
    }

    private static func generate(for team: Team, teamScore: Int, oppScore: Int,
                                  game: Game, season: Season, context: ModelContext) {
        let roster = team.players.sorted { $0.overall > $1.overall }

        // QB stats
        if let qb = roster.first(where: { $0.position == .QB && $0.isStarter }) {
            let attempts = Int.random(in: 22...35)
            let compPct = 0.50 + Double(qb.awareness - 70) * 0.004
            let completions = Int(Double(attempts) * max(0.40, min(0.72, compPct)))
            let yardsPerComp = 8.0 + Double(qb.awareness - 70) * 0.05
            let yards = Int(Double(completions) * yardsPerComp)
            let tds = min(5, teamScore / 7)
            let ints = teamScore < oppScore ? Int.random(in: 0...2) : Int.random(in: 0...1)

            let gs = PlayerGameStats(player: qb, game: game)
            gs.passAttempts = attempts
            gs.passCompletions = completions
            gs.passYards = yards
            gs.passTDs = tds
            gs.interceptionsThrown = ints
            context.insert(gs)
            upsertSeason(player: qb, season: season, gameStats: gs, context: context)
        }

        // RB stats (top 2 RBs share carries)
        let rbs = roster.filter { $0.position == .RB }.prefix(2)
        if let primary = rbs.first {
            let totalCarries = Int.random(in: 18...30)
            let primaryCarries = Int(Double(totalCarries) * 0.75)
            let ypc = 3.5 + Double(primary.speed - 70) * 0.05
            let yards = Int(Double(primaryCarries) * ypc)
            let tds = teamScore > oppScore ? Int.random(in: 0...2) : Int.random(in: 0...1)
            let gs = PlayerGameStats(player: primary, game: game)
            gs.rushAttempts = primaryCarries
            gs.rushYards = yards
            gs.rushTDs = tds
            context.insert(gs)
            upsertSeason(player: primary, season: season, gameStats: gs, context: context)

            if rbs.count > 1 {
                let backup = rbs[1]
                let bgs = PlayerGameStats(player: backup, game: game)
                bgs.rushAttempts = totalCarries - primaryCarries
                bgs.rushYards = Int(Double(bgs.rushAttempts) * (3.0 + Double(backup.speed - 70) * 0.04))
                context.insert(bgs)
                upsertSeason(player: backup, season: season, gameStats: bgs, context: context)
            }
        }

        // WR stats (top 3 WRs split receptions)
        let wrs = roster.filter { $0.position == .WR || $0.position == .TE }.prefix(3)
        let totalReceptions = Int.random(in: 15...25)
        let weights = [0.45, 0.32, 0.23]
        for (i, wr) in wrs.enumerated() {
            let recs = Int(Double(totalReceptions) * weights[i])
            let ypc = 10.0 + Double(wr.speed - 70) * 0.08
            let yards = Int(Double(recs) * ypc)
            let tds = i == 0 ? Int.random(in: 0...2) : Int.random(in: 0...1)
            let gs = PlayerGameStats(player: wr, game: game)
            gs.receptions = recs
            gs.recYards = yards
            gs.recTDs = tds
            context.insert(gs)
            upsertSeason(player: wr, season: season, gameStats: gs, context: context)
        }

        // Defense — distribute tackles among top LB/CB/S
        let defenders = roster.filter { [.LB, .CB, .S, .DL].contains($0.position) }.prefix(6)
        for def in defenders {
            let gs = PlayerGameStats(player: def, game: game)
            gs.tackles = Int.random(in: 2...9)
            if def.position == .DL || def.position == .LB {
                if Double.random(in: 0..<1) < 0.3 { gs.sacks = Double(Int.random(in: 1...2)) }
            }
            if def.position == .CB || def.position == .S {
                if Double.random(in: 0..<1) < 0.15 { gs.interceptions = 1 }
            }
            context.insert(gs)
            upsertSeason(player: def, season: season, gameStats: gs, context: context)
        }

        // Bump games_played on all starters
        for p in roster.filter({ $0.isStarter }) { p.gamesPlayed += 1 }
    }

    private static func upsertSeason(player: Player, season: Season,
                                      gameStats: PlayerGameStats,
                                      context: ModelContext) {
        let desc = FetchDescriptor<PlayerSeasonStats>()
        let all = (try? context.fetch(desc)) ?? []
        if let existing = all.first(where: { $0.player === player && $0.season === season }) {
            existing.aggregate(gameStats)
        } else {
            let fresh = PlayerSeasonStats(player: player, season: season)
            fresh.aggregate(gameStats)
            context.insert(fresh)
        }
    }
}
