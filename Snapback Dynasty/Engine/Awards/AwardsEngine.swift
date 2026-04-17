import Foundation
import SwiftData

/// Computes end-of-season awards (Heisman, All-American, All-Conference)
/// from PlayerSeasonStats.
enum AwardsEngine {

    /// Run awards for a completed season. Persists Award rows.
    static func run(season: Season, allTeams: [Team],
                    allStats: [PlayerSeasonStats], context: ModelContext) {
        // Score each player using position-specific weights.
        let scored = allStats.compactMap { stats -> (Player, Double, String, String)? in
            guard let p = stats.player, p.gamesPlayed > 0 else { return nil }
            let score = heismanScore(stats: stats, position: p.position)
            let line = statLine(stats: stats, position: p.position)
            return (p, score, p.position.rawValue, line)
        }

        let sorted = scored.sorted { $0.1 > $1.1 }

        // Heisman — top overall
        if let winner = sorted.first {
            let (player, _, pos, line) = winner
            let teamAbbr = player.team?.abbreviation ?? "—"
            let award = Award(
                seasonYear: season.year,
                type: .heisman,
                playerName: player.fullName,
                teamAbbreviation: teamAbbr,
                position: pos,
                statLine: line
            )
            context.insert(award)
        }

        // All-American First Team — top 1 per position nationally
        for pos in Position.allCases {
            let best = sorted.first(where: { $0.2 == pos.rawValue })
            if let (player, _, _, line) = best {
                let award = Award(
                    seasonYear: season.year,
                    type: .allAmerican,
                    playerName: player.fullName,
                    teamAbbreviation: player.team?.abbreviation ?? "—",
                    position: pos.rawValue,
                    statLine: line
                )
                context.insert(award)
            }
        }

        // All-Conference — top 1 per position per conference
        let conferences = Set(allTeams.compactMap { $0.conference?.name })
        for conf in conferences {
            for pos in Position.allCases {
                let best = sorted.first { (p, _, posRaw, _) in
                    posRaw == pos.rawValue && p.team?.conference?.name == conf
                }
                if let (player, _, _, line) = best {
                    let award = Award(
                        seasonYear: season.year,
                        type: .allConference,
                        playerName: player.fullName,
                        teamAbbreviation: player.team?.abbreviation ?? "—",
                        position: pos.rawValue,
                        statLine: line,
                        conferenceName: conf
                    )
                    context.insert(award)
                }
            }
        }
    }

    // MARK: - Score & stat line helpers

    private static func heismanScore(stats: PlayerSeasonStats, position: Position) -> Double {
        switch position {
        case .QB:
            return Double(stats.passYards) + 4 * Double(stats.passTDs)
                   - 2 * Double(stats.interceptionsThrown)
                   + 0.5 * Double(stats.rushYards) + 6 * Double(stats.rushTDs)
        case .RB:
            return Double(stats.rushYards) + 6 * Double(stats.rushTDs)
                   + 0.5 * Double(stats.recYards)
        case .WR, .TE:
            return Double(stats.recYards) + 6 * Double(stats.recTDs)
        case .LB, .DL, .CB, .S:
            return Double(stats.tackles) * 3 + stats.sacks * 15
                   + Double(stats.interceptions) * 20
        default:
            return 0
        }
    }

    private static func statLine(stats: PlayerSeasonStats, position: Position) -> String {
        switch position {
        case .QB:
            return "\(stats.passYards) yds, \(stats.passTDs) TD"
        case .RB:
            return "\(stats.rushYards) yds, \(stats.rushTDs) TD"
        case .WR, .TE:
            return "\(stats.receptions) rec, \(stats.recYards) yds, \(stats.recTDs) TD"
        case .LB, .DL, .CB, .S:
            return "\(stats.tackles) tkl, \(String(format: "%.1f", stats.sacks)) sck, \(stats.interceptions) INT"
        default:
            return "\(stats.gamesPlayed) games"
        }
    }
}
