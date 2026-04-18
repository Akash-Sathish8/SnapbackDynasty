import Foundation
import SwiftData

enum TransferPortalEngine {

    // MARK: - Phase A: Open portal

    @discardableResult
    static func openPortal(season: Season, allTeams: [Team],
                            playerTeam: Team?,
                            context: ModelContext) -> [TransferEntry] {
        var entries: [TransferEntry] = []

        for team in allTeams {
            for player in team.players {
                guard player.classYear != .SR else { continue }

                var rate: Double
                switch (player.isStarter, player.classYear) {
                case (true,  .FR): rate = RecruitingConfig.Portal.starterFR
                case (true,  .SO): rate = RecruitingConfig.Portal.starterSO
                case (true,  .JR): rate = RecruitingConfig.Portal.starterJRSR
                case (false, .FR): rate = RecruitingConfig.Portal.nonStarterFR
                case (false, .SO): rate = RecruitingConfig.Portal.nonStarterSO
                case (false, .JR): rate = RecruitingConfig.Portal.nonStarterJRSR
                default: rate = 0
                }

                if player.isStarter {
                    let higherCount = team.players.filter {
                        $0.position == player.position && $0.overall > player.overall
                    }.count
                    if higherCount >= 2 { rate += RecruitingConfig.Portal.starterPushedOut }
                }

                if team.wins < team.losses { rate += RecruitingConfig.Portal.belowFiveHundred }
                if team.wins < 6 { rate += RecruitingConfig.Portal.missedBowl }

                if player.overall >= 85 { rate += RecruitingConfig.Portal.highOVRBonus }
                if player.overall <= 60 { rate += RecruitingConfig.Portal.lowOVRBonus }

                guard Double.random(in: 0..<1) < rate else { continue }

                let entry = TransferEntry(player: player, fromTeam: team,
                                          seasonYear: season.year)
                context.insert(entry)
                entries.append(entry)

                if entries.count >= RecruitingConfig.Portal.globalPoolCap { return entries }
            }
        }

        let offersBase = RecruitingConfig.Portal.baseRetentionOffers
        let offersBonus = playerTeam?.coachingStaff?.has(.silverTongue) == true
            ? RecruitingConfig.Portal.silverTongueBonus : 0
        season.portalRetentionOffersRemaining = offersBase + offersBonus

        let normalWeekly = playerTeam.map {
            RecruitingEngine.weeklyHours(for: $0, staff: $0.coachingStaff)
        } ?? 500
        season.portalHoursRemaining = normalWeekly
        season.portalIsOpen = true

        return entries
    }

    // MARK: - Retention

    @discardableResult
    static func retain(entry: TransferEntry, playerTeam: Team,
                        season: Season) -> Bool {
        guard season.portalRetentionOffersRemaining > 0 else { return false }
        guard entry.status == .available else { return false }

        season.portalRetentionOffersRemaining -= 1

        let baseChance = entry.player?.isStarter == true
            ? RecruitingConfig.Portal.retentionSuccessStarter
            : RecruitingConfig.Portal.retentionSuccessNonStarter
        let bonus = playerTeam.coachingStaff?.has(.lockdown) == true
            ? RecruitingConfig.Portal.lockdownBonus : 0.0
        let retained = Double.random(in: 0..<1) < (baseChance + bonus)

        if retained {
            entry.status = .retained
            entry.toTeam = playerTeam
        }
        return retained
    }

    // MARK: - Portal board actions

    static func addToBoard(entry: TransferEntry, playerTeam: Team,
                            allEntries: [TransferEntry]) -> Bool {
        let onBoard = allEntries.filter { $0.isOnPlayerBoard }.count
        guard onBoard < RecruitingConfig.Portal.portalBoardCap else { return false }
        entry.isOnPlayerBoard = true
        return true
    }

    static func dm(entry: TransferEntry, season: Season) -> RecruitingResult {
        guard season.portalHoursRemaining >= 10 else { return .insufficientHours }
        season.portalHoursRemaining -= 10
        entry.portalInterestLevel = min(100, entry.portalInterestLevel + RecruitingConfig.Portal.dmInterestGain)
        return .ok(delta: RecruitingConfig.Portal.dmInterestGain,
                   message: "+\(Int(RecruitingConfig.Portal.dmInterestGain)) interest")
    }

    static func allIn(entry: TransferEntry, season: Season) -> RecruitingResult {
        guard season.portalHoursRemaining >= 50 else { return .insufficientHours }
        season.portalHoursRemaining -= 50
        entry.portalInterestLevel = min(100, entry.portalInterestLevel + RecruitingConfig.Portal.allInInterestGain)
        return .ok(delta: RecruitingConfig.Portal.allInInterestGain,
                   message: "+\(Int(RecruitingConfig.Portal.allInInterestGain)) interest")
    }

    static func offer(entry: TransferEntry, playerTeam: Team,
                       allTeams: [Team], season: Season) -> RecruitingResult {
        guard entry.status == .available else { return .gated("Already committed") }
        guard season.portalHoursRemaining >= 5 else { return .insufficientHours }

        if entry.starsAtEntry >= 4 {
            let sorted = allTeams.sorted { $0.legacy > $1.legacy }
            let rank = (sorted.firstIndex { $0.name == playerTeam.name } ?? 99) + 1
            guard rank <= RecruitingConfig.Portal.fourStarLegacyMinRank else {
                return .gated("4★+ transfers only consider top-25 programs")
            }
        }

        guard entry.portalInterestLevel >= RecruitingConfig.Portal.offerInterestThreshold else {
            return .gated("Build more interest before offering (need \(Int(RecruitingConfig.Portal.offerInterestThreshold))%)")
        }

        season.portalHoursRemaining -= 5

        let legacyScore = Double(playerTeam.legacy) / 100.0
        let starPenalty = entry.starsAtEntry >= 4 ? 0.2 : 0.0
        let chance = max(0.3, min(0.85, legacyScore - starPenalty))

        if Double.random(in: 0..<1) < chance {
            entry.status = .committed
            entry.toTeam = playerTeam
            return .ok(delta: 0, message: "\(entry.fullName) committed to transfer!")
        }
        return .ok(delta: 0, message: "\(entry.fullName) chose another program")
    }

    // MARK: - Phase B: Resolve and finalize

    static func resolveAI(allTeams: [Team], playerTeam: Team?,
                           entries: [TransferEntry]) {
        let available = entries.filter { $0.status == .available }
        let aiTeams = allTeams
            .filter { $0 !== playerTeam }
            .sorted { $0.legacy > $1.legacy }

        for entry in available {
            for team in aiTeams {
                let currentAtPos = team.players.filter { $0.position == entry.position }.count
                guard currentAtPos < entry.position.rosterCount else { continue }
                guard team.players.count < 85 else { continue }
                entry.status = .aiClaimed
                entry.toTeam = team
                break
            }
        }
    }

    static func finalize(entries: [TransferEntry]) {
        for entry in entries {
            guard let player = entry.player else { continue }
            switch entry.status {
            case .retained, .available:
                break
            case .committed, .aiClaimed:
                guard let dest = entry.toTeam, dest !== entry.fromTeam else { continue }
                player.team = dest
            }
        }
    }
}
