import Foundation
import SwiftData

/// Core weekly recruiting loop: actions, interest, phases, commits, AI.
///
/// EA's exact interest-point values aren't published. These numbers are
/// internally-consistent and map cleanly onto the arrow scale users see.
enum RecruitingResult {
    case ok(delta: Double, message: String)
    case insufficientHours
    case gated(String)
    case dealbreakerBlocked
}

final class RecruitingEngine {
    let context: ModelContext

    init(context: ModelContext) { self.context = context }

    // MARK: - Board management

    static let boardCap = 35
    static let perRecruitWeeklyCap = 50  // raised to 70 by "On The Trail"

    /// Returns true if a team already has the recruit on its board.
    static func isOnBoard(team: Team, recruit: Recruit) -> Bool {
        team.recruitInterests.contains { $0.recruit === recruit }
    }

    /// Current count of this team's board.
    static func boardCount(team: Team) -> Int {
        team.recruitInterests.count
    }

    @discardableResult
    func addToBoard(team: Team, recruit: Recruit) -> Bool {
        guard Self.boardCount(team: team) < Self.boardCap else { return false }
        guard !Self.isOnBoard(team: team, recruit: recruit) else { return false }
        let interest = RecruitInterest(recruit: recruit, team: team)
        context.insert(interest)
        return true
    }

    func removeFromBoard(team: Team, recruit: Recruit) {
        if let interest = team.recruitInterests.first(where: { $0.recruit === recruit }) {
            context.delete(interest)
        }
    }

    // MARK: - Hour budget

    /// Weekly hour allotment based on legacy (rating).
    /// Table from CFB 25 community-documented numbers.
    static func weeklyHours(for team: Team) -> Int {
        let legacy = team.legacy
        // Map legacy 25–99 onto 350–1000 hour range in steps.
        let bands: [(legacyFloor: Int, hours: Int)] = [
            (95, 1000), (90, 900), (85, 800), (80, 750),
            (75, 700),  (70, 650), (65, 600), (60, 550),
            (55, 500),  (50, 450), (40, 400), (0, 350),
        ]
        for band in bands where legacy >= band.legacyFloor { return band.hours }
        return 350
    }

    /// Apply recruiting staff bonus.
    static func weeklyHours(for team: Team, staff: CoachingStaff?) -> Int {
        var hours = weeklyHours(for: team)
        if let staff {
            let bonus = Double(staff.recruitingBonus) * 0.02
            hours = Int(Double(hours) * (1.0 + bonus))
        }
        return hours
    }

    // MARK: - Scouting

    /// Advance the recruit's scouting tier (0 → 4). Each Scout action = one tier.
    private func applyScouting(_ recruit: Recruit) {
        recruit.scoutingTier = min(4, recruit.scoutingTier + 1)
    }

    // MARK: - Perform action

    /// User-initiated action.
    @discardableResult
    func perform(action: RecruitingAction, team: Team, recruit: Recruit,
                 season: Season) -> RecruitingResult {
        // Ensure recruit is on board.
        if !Self.isOnBoard(team: team, recruit: recruit) {
            _ = addToBoard(team: team, recruit: recruit)
        }
        guard let interest = team.recruitInterests.first(where: { $0.recruit === recruit })
        else { return .gated("Not on board") }

        // Check dealbreaker gate (only blocks if revealed).
        if recruit.revealsDealbreaker {
            let threshold = LetterGrade(rawValue: recruit.dealbreakerThreshold) ?? .C
            let teamGrade = team.grade(for: recruit.dealbreaker)
            if teamGrade < threshold && !hasFlexStandards(team: team) {
                return .dealbreakerBlocked
            }
        }

        // Reassure is only valid when the recruit is committed to this team and loyalty is low.
        if action == .reassure {
            guard recruit.isCommittedToTeamId == team.abbreviation else {
                return .gated("Recruit is not committed to your team")
            }
            guard interest.loyalty < RecruitingConfig.Decommit.loyaltyWarningThreshold else {
                return .gated("Recruit is not wavering")
            }
        }

        // Phase gate on Top-5 actions.
        if action.requiresTop5 {
            if interest.topSlot.rawValue == 0 || interest.topSlot.rawValue > 5 {
                return .gated("Need to be in Top 5")
            }
        }

        // Hour budget.
        let cost = action.hourCost
        if season.recruitingHoursRemaining < cost {
            return .insufficientHours
        }

        // Per-recruit weekly cap.
        let perRecruitCap = hasOnTheTrail(team: team) ? 70 : Self.perRecruitWeeklyCap
        // Visits are EXEMPT from the per-recruit cap (EA behavior).
        if action != .scheduleVisit && interest.hoursThisWeek + cost > perRecruitCap {
            return .gated("Per-recruit cap reached")
        }

        // Deduct hours.
        season.recruitingHoursRemaining -= cost
        if action != .scheduleVisit { interest.hoursThisWeek += cost }
        interest.hoursInvested += cost

        // Compute interest delta.
        let delta = computeDelta(action: action, team: team, recruit: recruit, interest: interest)
        interest.interestLevel = max(0, min(100, interest.interestLevel + delta))

        // Side effects.
        switch action {
        case .scout:
            applyScouting(recruit)
        case .offer:
            interest.hasOffered = true
        case .scheduleVisit:
            interest.visitWeek = season.currentWeek
        case .reassure:
            interest.loyalty = min(RecruitingConfig.Decommit.startingLoyalty,
                                   interest.loyalty + RecruitingConfig.Decommit.reassureLoyaltyGain)
        default: break
        }

        let msg = delta >= 0 ? "+\(String(format: "%.1f", delta)) interest" :
                                "\(String(format: "%.1f", delta)) interest"
        return .ok(delta: delta, message: msg)
    }

    // MARK: - Interest formula

    /// Rule of 19: sum the 3 motivation grades (numeric 1–13). ≥19 → Full Pitch is +EV.
    static func motivationFitScore(team: Team, recruit: Recruit) -> Int {
        recruit.motivations.reduce(0) { $0 + team.grade(for: $1).rawValue }
    }

    private func computeDelta(action: RecruitingAction, team: Team, recruit: Recruit,
                              interest: RecruitInterest) -> Double {
        let base: Double = {
            switch action {
            case .scout:         return 0
            case .searchSocial:  return 1
            case .dm:            return 2
            case .contactFamily: return 4
            case .allIn:         return 7
            case .offer:         return 5
            case .scheduleVisit: return 10
            case .nudge:         return 3
            case .fullPitch:     return 8
            case .reframe:       return 2
            case .reassure:      return 0
            }
        }()

        // Pipeline multiplier (team's tier in recruit's region).
        let pipelineMult = team.tier(for: recruit.pipeline).interestMultiplier

        // Coaching recruiting bonus.
        let coachMult = 1.0 + Double(team.coachingStaff?.recruitingBonus ?? 0) * 0.015

        // Motivation alignment: scaled linearly around an average grade of 7 (C+).
        let fit = Self.motivationFitScore(team: team, recruit: recruit)  // 3–39
        let fitMult = 0.6 + (Double(fit - 9) / 30.0)  // 0.6 → 1.6

        // Phase multiplier.
        let phaseMult: Double = {
            switch recruit.phase {
            case .discovery: return 0.85
            case .pitch:     return 1.05
            case .close:     return 1.25
            default:         return 0.0
            }
        }()

        var delta = base * pipelineMult * coachMult * fitMult * phaseMult

        // Action-specific quirks.
        switch action {
        case .fullPitch:
            // Rule of 19: sum of motivation grades ≥ 19 → bonus; else penalty.
            if fit >= 19 { delta *= 1.3 }
            else { delta *= -0.6 }
        case .nudge:
            // Nudge is precision: great when a specific motivation grade is strong.
            let bestMotivationGrade = recruit.motivations
                .map { team.grade(for: $0).rawValue }
                .max() ?? 0
            if bestMotivationGrade < 8 { delta *= 0.3 }  // diminished if no B- or better
        case .reframe:
            // 45% chance to succeed, more if Persuasive Charm unlocked.
            let succeeds = Double.random(in: 0..<1) < (hasPersuasiveCharm(team: team) ? 0.65 : 0.45)
            if !succeeds { delta = 0 }
        case .scheduleVisit:
            // Base +10; actual outcome comes from game-day (Phase E.4 hook).
            break
        default: break
        }

        return delta
    }

    private func hasOnTheTrail(team: Team) -> Bool {
        team.coachingStaff?.has(.onTheTrail) ?? false
    }
    private func hasPersuasiveCharm(team: Team) -> Bool {
        team.coachingStaff?.has(.persuasiveCharm) ?? false
    }
    private func hasFlexStandards(team: Team) -> Bool {
        team.coachingStaff?.has(.flexStandards) ?? false
    }
    private func hasDestinyPick(team: Team) -> Bool {
        team.coachingStaff?.has(.destinyPick) ?? false
    }

    // MARK: - Weekly advance

    /// Call once per game-week to update AI pressure, reset weekly caps,
    /// advance phases, and trigger commits.
    func advanceWeek(season: Season, playerTeam: Team?, allTeams: [Team],
                     allRecruits: [Recruit]) {
        // 1) Reset weekly hours across all interests.
        for team in allTeams {
            for interest in team.recruitInterests {
                interest.hoursThisWeek = 0
            }
        }

        // 2) Reset player's weekly hour pool.
        if let team = playerTeam {
            season.recruitingHoursRemaining = Self.weeklyHours(for: team,
                                                               staff: team.coachingStaff)
        }

        // 3) AI pressure — non-player teams gain passive interest on
        //    prospects in their pipeline regions.
        for recruit in allRecruits where !recruit.isSigned && recruit.isCommittedToTeamId == nil {
            applyAIPressure(recruit: recruit, allTeams: allTeams,
                            playerTeam: playerTeam, allRecruits: allRecruits)
        }

        // 4) Recompute top-list slots + phase for each recruit.
        for recruit in allRecruits where !recruit.isSigned && recruit.isCommittedToTeamId == nil {
            recomputeSlotsAndPhase(recruit: recruit)
        }

        // 5) Check commits.
        for recruit in allRecruits where !recruit.isSigned && recruit.isCommittedToTeamId == nil {
            checkCommit(recruit: recruit, playerTeam: playerTeam)
        }

        // 6) Check decommits — must run after commits so newly committed recruits
        //    don't immediately get decommit-checked the same week.
        for recruit in allRecruits where recruit.isCommittedToTeamId != nil && !recruit.isSigned {
            checkDecommit(recruit: recruit, allRecruits: allRecruits)
        }

        // 7) Refresh dynamic school grades weekly.
        for team in allTeams {
            SchoolGradeEngine.refreshDynamic(for: team, allTeams: allTeams, context: context)
        }
    }

    // MARK: - AI pressure

    private func applyAIPressure(recruit: Recruit, allTeams: [Team],
                                  playerTeam: Team?, allRecruits: [Recruit]) {
        let candidates = allTeams.filter { $0 !== playerTeam }

        let scored: [(Team, Double)] = candidates.map { team in
            let tierMult = team.tier(for: recruit.pipeline).interestMultiplier
            let legacyScore = Double(team.legacy) / 100.0

            // Positional need: how many more players does this team need at this position?
            let currentAtPos = team.players.filter { $0.position == recruit.position }.count
            let targetCount = max(1, recruit.position.rosterCount)
            let need = max(0.0, Double(targetCount - currentAtPos) / Double(targetCount))
            let needMult = RecruitingConfig.AI.needMultiplierFull
                + need * (RecruitingConfig.AI.needMultiplierEmpty - RecruitingConfig.AI.needMultiplierFull)

            return (team, tierMult * legacyScore * needMult)
        }.sorted { $0.1 > $1.1 }

        let pickCount = Int.random(in: 2...4)
        for (team, score) in scored.prefix(pickCount) {
            // Skip if this team already has enough committed recruits + players at this position.
            let committedAtPos = allRecruits.filter {
                $0.position == recruit.position &&
                $0.isCommittedToTeamId == team.abbreviation
            }.count
            let currentAtPos = team.players.filter { $0.position == recruit.position }.count
            if committedAtPos + currentAtPos >= recruit.position.rosterCount { continue }

            var interest = team.recruitInterests.first { $0.recruit === recruit }
            if interest == nil {
                if score < RecruitingConfig.AI.minimumScoreToAddBoard { continue }
                guard team.recruitInterests.count < Self.boardCap else { continue }
                let newInterest = RecruitInterest(recruit: recruit, team: team)
                context.insert(newInterest)
                interest = newInterest
            }

            // Phase-aware gain.
            let phaseMult = RecruitingConfig.AI.phaseMultipliers[recruit.phase] ?? 1.0
            let baseGain = Double.random(
                in: RecruitingConfig.AI.baseWeeklyGainRange.0...RecruitingConfig.AI.baseWeeklyGainRange.1
            )
            let gain = baseGain * score * phaseMult
            interest?.interestLevel = min(100, (interest?.interestLevel ?? 0) + gain)

            // Late swoop: high-legacy teams occasionally burst-push a committed recruit.
            guard team.legacy >= 80,
                  let committedAbbr = recruit.isCommittedToTeamId,
                  committedAbbr != team.abbreviation,
                  Double.random(in: 0..<1) < RecruitingConfig.AI.swoopChance else { continue }

            let swoopGain = Double.random(
                in: RecruitingConfig.AI.swoopGainRange.0...RecruitingConfig.AI.swoopGainRange.1
            )
            interest?.interestLevel = min(100, (interest?.interestLevel ?? 0) + swoopGain)

            // Hit the committed team's loyalty for the recruit.
            if let committedTeam = allTeams.first(where: { $0.abbreviation == committedAbbr }),
               let committedInterest = committedTeam.recruitInterests.first(where: { $0.recruit === recruit }) {
                committedInterest.loyalty += RecruitingConfig.Decommit.eventHitSwoop
            }
        }
    }

    // MARK: - Slot + phase

    private func recomputeSlotsAndPhase(recruit: Recruit) {
        // Rank teams by interest level.
        let ranked = recruit.interests
            .filter { $0.interestLevel > 0 }
            .sorted { $0.interestLevel > $1.interestLevel }

        for (idx, interest) in ranked.enumerated() {
            let slot: TopListSlot
            switch idx {
            case 0:       slot = .leader
            case 1, 2:    slot = .top3
            case 3, 4:    slot = .top5
            case 5, 6, 7: slot = .top8
            case 8, 9:    slot = .top10
            default:      slot = .notOnList
            }
            interest.topSlotRaw = slot.rawValue
        }

        // Phase transitions — allowed in both directions so a recruit whose
        // interest drops can return to an earlier phase.
        let maxInterest = ranked.first?.interestLevel ?? 0
        let newPhase: RecruitPhase
        if maxInterest >= 60      { newPhase = .close }
        else if maxInterest >= 30 { newPhase = .pitch }
        else                       { newPhase = .discovery }
        if newPhase != recruit.phase { recruit.phaseRaw = newPhase.rawValue }
    }

    // MARK: - Commit

    private func checkCommit(recruit: Recruit, playerTeam: Team?) {
        guard recruit.phase == .close else { return }
        let ranked = recruit.interests.sorted { $0.interestLevel > $1.interestLevel }
        guard let leader = ranked.first else { return }
        let second = ranked.count > 1 ? ranked[1].interestLevel : 0
        let gap = leader.interestLevel - second
        let leaderTeam = leader.team

        // Destiny Pick buffs instant-commit odds when the player's team is the leader.
        let hasDP: Bool
        if let pt = playerTeam, pt === leaderTeam {
            hasDP = pt.coachingStaff?.has(.destinyPick) ?? false
        } else {
            hasDP = false
        }

        let threshold: Double = hasDP ? 80.0 : 85.0
        let gapReq: Double   = hasDP ? 5.0  : 8.0

        if leader.interestLevel >= threshold && gap >= gapReq {
            recruit.isCommittedToTeamId = leaderTeam?.abbreviation
            recruit.phaseRaw = RecruitPhase.committed.rawValue
        }
    }

    // MARK: - Decommit

    func checkDecommit(recruit: Recruit, allRecruits: [Recruit]) {
        guard let committedAbbr = recruit.isCommittedToTeamId else { return }
        guard let committedInterest = recruit.interests.first(where: {
            $0.team?.abbreviation == committedAbbr
        }) else { return }

        // Passive drift: erodes loyalty when a rival is within the gap threshold.
        let rivalClose = recruit.interests.contains { interest in
            guard interest.team?.abbreviation != committedAbbr else { return false }
            let gap = committedInterest.interestLevel - interest.interestLevel
            return gap < RecruitingConfig.Decommit.rivalGapThreshold
        }

        if rivalClose {
            let drift = Double.random(
                in: RecruitingConfig.Decommit.passiveDriftRange.0...RecruitingConfig.Decommit.passiveDriftRange.1
            )
            let floor = recruit.stars >= 4 ? RecruitingConfig.Decommit.loyaltyFloor4And5Star : 0.0
            committedInterest.loyalty = max(floor, committedInterest.loyalty - drift)
        }

        // Oversign event: ≥ 3 other recruits already committed to same team at same position.
        if !committedInterest.oversignHitApplied {
            let samePosSameTeam = allRecruits.filter {
                $0.position == recruit.position &&
                $0.isCommittedToTeamId == committedAbbr &&
                $0 !== recruit
            }.count
            if samePosSameTeam >= 3 {
                committedInterest.loyalty += RecruitingConfig.Decommit.eventHitOversign
                committedInterest.oversignHitApplied = true
            }
        }

        // Decommit resolution.
        guard committedInterest.loyalty <= 0 else { return }
        recruit.isCommittedToTeamId = nil
        recruit.phaseRaw = RecruitPhase.close.rawValue
        committedInterest.loyalty = RecruitingConfig.Decommit.startingLoyalty
        committedInterest.oversignHitApplied = false
    }

    /// Call from DashboardView after simulateWeek to apply big-loss loyalty hits.
    func applyGameResultEffects(playerTeamWon: Bool, margin: Int,
                                 playerTeam: Team, allRecruits: [Recruit]) {
        guard !playerTeamWon && margin <= -21 else { return }

        for recruit in allRecruits {
            guard recruit.isCommittedToTeamId == playerTeam.abbreviation else { continue }
            guard recruit.motivations.contains(.titleContender) ||
                  recruit.motivations.contains(.tradition) else { continue }
            if let interest = playerTeam.recruitInterests.first(where: { $0.recruit === recruit }) {
                interest.loyalty += RecruitingConfig.Decommit.eventHitBigLoss
            }
        }
    }
}
