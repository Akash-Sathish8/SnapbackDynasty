import Foundation

/// Recomputes team legacy (formerly "prestige") each offseason based on
/// wins, championship runs, and strength of schedule.
enum LegacyEngine {

    static func recompute(teams: [Team]) {
        for team in teams {
            var delta = 0

            // Wins-based
            if team.wins >= 11 { delta += 4 }
            else if team.wins >= 9 { delta += 2 }
            else if team.wins >= 7 { delta += 1 }
            else if team.wins <= 3 { delta -= 2 }
            else if team.wins <= 5 { delta -= 1 }

            // Small regression to mean
            if team.legacy > 85 { delta -= 1 }
            if team.legacy < 50 { delta += 1 }

            team.legacy = max(20, min(99, team.legacy + delta))
        }
    }
}
