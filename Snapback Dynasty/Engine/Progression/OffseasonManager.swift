import Foundation
import SwiftData

enum OffseasonManager {

    struct Summary {
        let graduated: Int
        let developed: Int
        let newSeasonYear: Int
    }

    // MARK: - Phase A: run immediately when "Advance to Offseason" is tapped

    /// Awards, history, NSD signing, portal open. Sets season.portalIsOpen = true.
    static func runOffseasonPhaseA(currentSeason: Season, allTeams: [Team],
                                    playerTeam: Team?, context: ModelContext) {
        // 0. Awards + dynasty history snapshots BEFORE wiping stats.
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

        // 1. Sign any remaining recruits (NSD catch-all).
        let allRecruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
        _ = SigningDay.run(kind: .national, allRecruits: allRecruits,
                           allTeams: allTeams, context: context)

        // 2. Open transfer portal.
        _ = TransferPortalEngine.openPortal(season: currentSeason, allTeams: allTeams,
                                             playerTeam: playerTeam, context: context)

        try? context.save()
    }

    // MARK: - Phase B: run when "Close Portal & Advance" is tapped

    /// Finalizes portal, graduates seniors, develops players, resets for new season.
    @discardableResult
    static func runOffseasonPhaseB(currentSeason: Season, allTeams: [Team],
                                    playerTeam: Team?, context: ModelContext) -> Summary {
        // 0. Resolve and finalize portal.
        let allEntries = (try? context.fetch(FetchDescriptor<TransferEntry>())) ?? []
        let currentEntries = allEntries.filter { $0.seasonYear == currentSeason.year }
        TransferPortalEngine.resolveAI(allTeams: allTeams, playerTeam: playerTeam,
                                        entries: currentEntries)
        TransferPortalEngine.finalize(entries: currentEntries)
        currentSeason.portalIsOpen = false

        // 1. Graduate seniors — delete to prevent orphaned record accumulation.
        var graduated = 0
        for team in allTeams {
            let seniors = team.players.filter { $0.classYear == .SR }
            for player in seniors {
                context.delete(player)
                graduated += 1
            }
        }

        // 2. Advance class years + develop.
        var developed = 0
        for team in allTeams {
            for player in team.players {
                switch player.classYear {
                case .FR: player.classYear = .SO
                case .SO: player.classYear = .JR
                case .JR: player.classYear = .SR
                case .SR: break
                }
                PlayerDevelopment.develop(player,
                    coachDevBonus: team.coachingStaff?.developmentBonus ?? 0)
                developed += 1
            }
        }

        // 3. Recompute legacy.
        LegacyEngine.recompute(teams: allTeams)

        // 4. Wipe per-game stats.
        let oldGameStats = (try? context.fetch(FetchDescriptor<PlayerGameStats>())) ?? []
        for gs in oldGameStats { context.delete(gs) }

        // 5. Reset team records + re-set starters.
        for team in allTeams {
            team.wins = 0; team.losses = 0
            team.conferenceWins = 0; team.conferenceLosses = 0
            team.offenseRating = 50; team.defenseRating = 50
            for pos in Position.allCases {
                let sorted = team.players.filter { $0.position == pos }
                    .sorted { $0.overall > $1.overall }
                for (i, p) in sorted.enumerated() {
                    p.isStarter = i < pos.starterCount
                }
            }
        }

        // 6. Delete old games.
        let oldGames = (try? context.fetch(FetchDescriptor<Game>())) ?? []
        for g in oldGames { context.delete(g) }

        // 7. Clear unsigned recruits.
        let allRecruits = (try? context.fetch(FetchDescriptor<Recruit>())) ?? []
        for r in allRecruits where !r.isSigned { context.delete(r) }

        // 8. Mark old season inactive, create new.
        currentSeason.isActive = false
        let newYear = currentSeason.year + 1
        let newSeason = Season(year: newYear)
        newSeason.recruitingHoursRemaining = 0
        context.insert(newSeason)

        // 9. Generate new recruiting class.
        RecruitGenerator.generateClass(into: context, classYear: newYear + 1)

        // 10. Refresh school grades.
        SchoolGradeEngine.seedAll(teams: allTeams, context: context)

        try? context.save()

        return Summary(graduated: graduated, developed: developed,
                       newSeasonYear: newYear)
    }
}
