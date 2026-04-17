import Foundation
import SwiftData

/// Orchestrates all offseason work: graduation, age, develop, new recruits,
/// legacy recalc, new season.
enum OffseasonManager {

    struct Summary {
        let graduated: Int
        let developed: Int
        let newSeasonYear: Int
    }

    @discardableResult
    static func runOffseason(currentSeason: Season, allTeams: [Team],
                              context: ModelContext) -> Summary {
        // 0. Awards + Dynasty history snapshots BEFORE wiping stats
        let seasonStats = (try? context.fetch(FetchDescriptor<PlayerSeasonStats>())) ?? []
        AwardsEngine.run(season: currentSeason, allTeams: allTeams,
                         allStats: seasonStats, context: context)

        for team in allTeams {
            let history = DynastyHistory(
                team: team, seasonYear: currentSeason.year,
                wins: team.wins, losses: team.losses,
                conferenceWins: team.conferenceWins,
                conferenceLosses: team.conferenceLosses,
                legacyAtEnd: team.legacy
            )
            context.insert(history)
        }

        // 1. Sign any remaining recruits (NSD catch-all)
        let allRecruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
        _ = SigningDay.run(kind: .national, allRecruits: allRecruits,
                           allTeams: allTeams, context: context)

        // 2. Graduate seniors
        var graduated = 0
        for team in allTeams {
            for player in team.players where player.classYear == .SR {
                player.team = nil  // detach (archived for career stats if needed)
                graduated += 1
            }
        }

        // 3. Advance class years for remaining players
        var developed = 0
        for team in allTeams {
            for player in team.players {
                switch player.classYear {
                case .FR: player.classYear = .SO
                case .SO: player.classYear = .JR
                case .JR: player.classYear = .SR
                case .SR: break  // handled above
                }
                PlayerDevelopment.develop(player,
                    coachDevBonus: team.coachingStaff?.developmentBonus ?? 0)
                developed += 1
            }
        }

        // 4. Recompute team legacy
        LegacyEngine.recompute(teams: allTeams)

        // 5. Wipe last season's per-game stats (keep season stats)
        let oldGameStats = (try? context.fetch(FetchDescriptor<PlayerGameStats>())) ?? []
        for gs in oldGameStats { context.delete(gs) }

        // 6. Reset team records
        for team in allTeams {
            team.wins = 0; team.losses = 0
            team.conferenceWins = 0; team.conferenceLosses = 0
            team.offenseRating = 50; team.defenseRating = 50
            // Re-set starters based on new overalls
            for pos in Position.allCases {
                let sorted = team.players.filter { $0.position == pos }
                    .sorted { $0.overall > $1.overall }
                for (i, p) in sorted.enumerated() {
                    p.isStarter = i < pos.starterCount
                }
            }
        }

        // 7. Delete old games
        let oldGames = (try? context.fetch(FetchDescriptor<Game>())) ?? []
        for g in oldGames { context.delete(g) }

        // 8. Clear old recruits (unsigned ones) + generate new class
        let oldRecruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
        for r in oldRecruits where !r.isSigned { context.delete(r) }

        // 9. Mark old season inactive, create new
        currentSeason.isActive = false
        let newYear = currentSeason.year + 1
        let newSeason = Season(year: newYear)
        newSeason.recruitingHoursRemaining = 0
        context.insert(newSeason)

        // 10. Generate new recruiting class
        RecruitGenerator.generateClass(into: context, classYear: newYear + 1)

        // 11. Refresh school grades
        SchoolGradeEngine.seedAll(teams: allTeams, context: context)

        try? context.save()

        return Summary(graduated: graduated, developed: developed,
                       newSeasonYear: newYear)
    }
}
