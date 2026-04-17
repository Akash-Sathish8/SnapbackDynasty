import Foundation
import SwiftData

/// One row per (team × completed season). Snapshot at season's end.
@Model
final class DynastyHistory {
    var team: Team?
    var seasonYear: Int
    var wins: Int
    var losses: Int
    var conferenceWins: Int
    var conferenceLosses: Int
    var conferenceFinish: String  // "1st in SEC", etc.
    var madePlayoff: Bool
    var wonChampionship: Bool
    var legacyAtEnd: Int
    var heismanWinnerId: String?  // player name as simple ref

    init(team: Team, seasonYear: Int, wins: Int, losses: Int,
         conferenceWins: Int, conferenceLosses: Int,
         conferenceFinish: String = "",
         madePlayoff: Bool = false, wonChampionship: Bool = false,
         legacyAtEnd: Int = 50) {
        self.team = team
        self.seasonYear = seasonYear
        self.wins = wins; self.losses = losses
        self.conferenceWins = conferenceWins; self.conferenceLosses = conferenceLosses
        self.conferenceFinish = conferenceFinish
        self.madePlayoff = madePlayoff
        self.wonChampionship = wonChampionship
        self.legacyAtEnd = legacyAtEnd
    }
}
