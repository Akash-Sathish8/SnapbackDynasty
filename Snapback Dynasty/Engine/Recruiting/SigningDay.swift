import Foundation
import SwiftData

/// Early Signing Day (mid-season lock) + National Signing Day (offseason finalize).
/// Lock turns verbal commits into Player records on each team's roster.
enum SigningDay {

    /// Lock all currently committed recruits (commit → signed). Creates
    /// matching Player records on each team.
    static func run(kind: Kind, allRecruits: [Recruit], allTeams: [Team],
                    context: ModelContext) -> [SigningRecord] {
        var records: [SigningRecord] = []
        for recruit in allRecruits {
            guard !recruit.isSigned else { continue }

            // On NSD: try to commit any recruit with a clear interest leader before
            // the guard below skips them. This block was unreachable in the prior
            // version because the guard fired first.
            if kind == .national && recruit.isCommittedToTeamId == nil {
                if let leader = recruit.interests.sorted(by: { $0.interestLevel > $1.interestLevel }).first,
                   leader.interestLevel >= 50,
                   let leadTeam = leader.team {
                    recruit.isCommittedToTeamId = leadTeam.abbreviation
                }
            }

            guard let abbr = recruit.isCommittedToTeamId,
                  let team = allTeams.first(where: { $0.abbreviation == abbr })
            else { continue }

            // Enforce 85-scholarship cap.
            guard team.players.count < 85 else { continue }

            recruit.isSigned = true
            recruit.phaseRaw = RecruitPhase.signed.rawValue

            let p = Player(
                firstName: recruit.firstName,
                lastName: recruit.lastName,
                position: recruit.position,
                year: .FR,
                speed: recruit.speed,
                strength: recruit.strength,
                awareness: recruit.awareness,
                potential: recruit.potential,
                homeState: recruit.homeState
            )
            p.stars = recruit.stars
            p.team = team
            context.insert(p)

            records.append(SigningRecord(recruit: recruit, team: team, kind: kind))
        }
        return records
    }

    enum Kind: String {
        case early     = "Early Signing Day"
        case national  = "National Signing Day"
    }

    struct SigningRecord {
        let recruit: Recruit
        let team: Team
        let kind: Kind
    }
}
