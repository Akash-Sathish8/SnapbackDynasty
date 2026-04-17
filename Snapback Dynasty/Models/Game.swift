import Foundation
import SwiftData

@Model
final class Game {
    var season: Season?
    var week: Int
    var homeTeam: Team?
    var awayTeam: Team?
    var homeScore: Int?
    var awayScore: Int?
    var isConferenceGame: Bool = false
    var isPlayoff: Bool = false
    var isPlayed: Bool = false
    var attendance: Int?

    init(week: Int) {
        self.week = week
    }
}
