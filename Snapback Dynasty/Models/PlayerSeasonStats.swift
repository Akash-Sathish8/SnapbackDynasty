import Foundation
import SwiftData

/// Aggregated per-season stats for a single player. Upserted after each game.
@Model
final class PlayerSeasonStats {
    var player: Player?
    var season: Season?
    var gamesPlayed: Int = 0

    var passAttempts: Int = 0
    var passCompletions: Int = 0
    var passYards: Int = 0
    var passTDs: Int = 0
    var interceptionsThrown: Int = 0

    var rushAttempts: Int = 0
    var rushYards: Int = 0
    var rushTDs: Int = 0

    var receptions: Int = 0
    var recYards: Int = 0
    var recTDs: Int = 0

    var tackles: Int = 0
    var sacks: Double = 0
    var interceptions: Int = 0

    init(player: Player, season: Season) {
        self.player = player
        self.season = season
    }

    /// Add a single-game stat line to the season totals.
    func aggregate(_ g: PlayerGameStats) {
        gamesPlayed += 1
        passAttempts += g.passAttempts
        passCompletions += g.passCompletions
        passYards += g.passYards
        passTDs += g.passTDs
        interceptionsThrown += g.interceptionsThrown
        rushAttempts += g.rushAttempts
        rushYards += g.rushYards
        rushTDs += g.rushTDs
        receptions += g.receptions
        recYards += g.recYards
        recTDs += g.recTDs
        tackles += g.tackles
        sacks += g.sacks
        interceptions += g.interceptions
    }
}
