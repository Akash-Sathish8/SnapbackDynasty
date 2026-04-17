import Foundation
import SwiftData

/// Per-game stats for a single player. Written at end of each simulated game.
@Model
final class PlayerGameStats {
    var player: Player?
    var game: Game?

    // Passing
    var passAttempts: Int = 0
    var passCompletions: Int = 0
    var passYards: Int = 0
    var passTDs: Int = 0
    var interceptionsThrown: Int = 0

    // Rushing
    var rushAttempts: Int = 0
    var rushYards: Int = 0
    var rushTDs: Int = 0

    // Receiving
    var receptions: Int = 0
    var recYards: Int = 0
    var recTDs: Int = 0

    // Defense
    var tackles: Int = 0
    var sacks: Double = 0
    var interceptions: Int = 0

    init(player: Player, game: Game) {
        self.player = player
        self.game = game
    }
}
