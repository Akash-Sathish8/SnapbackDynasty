import Foundation
import SwiftData

// MARK: - Data types

struct PlayResult {
    let type: String          // pass, run, scramble, sack
    let yards: Int
    let isComplete: Bool      // for passes
    let isTurnover: Bool
    let turnoverType: String? // INT, FUMBLE
    let isTouchdown: Bool
    let scoringPlayerName: String?
    let ballCarrierName: String?
    let description: String
}

struct DriveResult {
    let teamName: String
    let startPosition: Int
    let plays: [PlayResult]
    let result: String       // TD, FG, FG_MISS, PUNT, TURNOVER_INT, TURNOVER_FUMBLE, END_OF_HALF
    let totalYards: Int
    let scoring: Int
}

struct PlayerStats {
    var passAttempts = 0, passCompletions = 0, passYards = 0, passTDs = 0, interceptions = 0
    var rushAttempts = 0, rushYards = 0, rushTDs = 0
    var receptions = 0, recYards = 0, recTDs = 0
    var tackles = 0, sacks: Double = 0, ints = 0, fumblesForced = 0
    var fgAttempts = 0, fgMade = 0
}

struct GameResult {
    let homeScore: Int
    let awayScore: Int
    let quarterScores: [(Int, Int)]
    let playerStats: [String: PlayerStats]   // keyed by "firstName lastName"
    let drives: [DriveResult]
    let plays: [PlayResult]                  // all plays flat for live view
}

// MARK: - Roster snapshot (avoid SwiftData threading issues)

struct PlayerSnap {
    let name: String
    let shortName: String
    let position: Position
    let speed: Int, strength: Int, awareness: Int, overall: Int
    let isStarter: Bool
}

struct TeamSnap {
    let name: String
    let abbreviation: String
    let legacy: Int
    let primaryColor: String
    let starters: [PlayerSnap]
    let backups: [PlayerSnap]

    func startersAt(_ pos: Position) -> [PlayerSnap] { starters.filter { $0.position == pos } }
    func best(_ pos: Position) -> PlayerSnap? { startersAt(pos).max(by: { $0.overall < $1.overall }) }
    func avgOverall(_ pos: Position) -> Double {
        let ps = startersAt(pos)
        guard !ps.isEmpty else { return 50 }
        return Double(ps.map(\.overall).reduce(0, +)) / Double(ps.count)
    }
}

// MARK: - Simulator

class GameSimulator {
    let home: TeamSnap
    let away: TeamSnap
    let isNeutral: Bool

    private var homeScore = 0
    private var awayScore = 0
    private var quarterScores: [(Int, Int)] = []
    private var momentum: Double = 0
    private var stats: [String: PlayerStats] = [:]
    private var allDrives: [DriveResult] = []
    private var allPlays: [PlayResult] = []

    init(home: TeamSnap, away: TeamSnap, isNeutral: Bool = false) {
        self.home = home
        self.away = away
        self.isNeutral = isNeutral
    }

    func simulate() -> GameResult {
        // 4 quarters, ~6 possessions each (3 per team)
        for q in 1...4 {
            let qStart = (homeScore, awayScore)
            for drive in 0..<6 {
                let isHome = drive % 2 == 0
                let offense = isHome ? home : away
                let defense = isHome ? away : home
                simulateDrive(offense: offense, defense: defense, isHome: isHome, quarter: q)
            }
            quarterScores.append((homeScore - qStart.0, awayScore - qStart.1))
        }

        // Overtime
        var otRound = 0
        while homeScore == awayScore && otRound < 3 {
            otRound += 1
            simulateDrive(offense: away, defense: home, isHome: false, quarter: 5, startPos: 75)
            simulateDrive(offense: home, defense: away, isHome: true, quarter: 5, startPos: 75)
        }
        if homeScore == awayScore {
            // Coin flip
            if Bool.random() { homeScore += 3 } else { awayScore += 3 }
        }

        return GameResult(
            homeScore: homeScore, awayScore: awayScore,
            quarterScores: quarterScores,
            playerStats: stats, drives: allDrives, plays: allPlays
        )
    }

    // MARK: - Drive simulation

    private func simulateDrive(offense: TeamSnap, defense: TeamSnap,
                               isHome: Bool, quarter: Int, startPos: Int = 25) {
        var fieldPos = startPos
        var down = 1
        var yardsToGo = 10
        var drivePlays: [PlayResult] = []
        var driveYards = 0
        let scoreDiff = isHome ? homeScore - awayScore : awayScore - homeScore

        for _ in 0..<12 {  // max plays per drive
            let play = simulatePlay(
                offense: offense, defense: defense,
                fieldPos: fieldPos, down: down, yardsToGo: yardsToGo,
                scoreDiff: scoreDiff, quarter: quarter, isHome: isHome
            )
            drivePlays.append(play)
            allPlays.append(play)

            if play.isTurnover {
                adjustMomentum(toward: !isHome, amount: 0.20)
                let dr = DriveResult(teamName: offense.name, startPosition: startPos,
                                     plays: drivePlays, result: play.turnoverType == "INT" ? "TURNOVER_INT" : "TURNOVER_FUMBLE",
                                     totalYards: driveYards, scoring: 0)
                allDrives.append(dr)
                return
            }

            fieldPos += play.yards
            driveYards += play.yards

            if play.isTouchdown || fieldPos >= 100 {
                let pts = 7  // assume XP
                if isHome { homeScore += pts } else { awayScore += pts }
                adjustMomentum(toward: isHome, amount: 0.15)
                let dr = DriveResult(teamName: offense.name, startPosition: startPos,
                                     plays: drivePlays, result: "TD",
                                     totalYards: driveYards, scoring: pts)
                allDrives.append(dr)
                return
            }

            if play.yards >= yardsToGo {
                down = 1; yardsToGo = min(10, 100 - fieldPos)
            } else {
                yardsToGo -= play.yards
                down += 1
            }

            if down > 4 {
                // 4th down decisions
                let fgDistance = 100 - fieldPos + 17
                if fieldPos >= 65 && fgDistance <= 52 {
                    // FG attempt
                    let kicker = offense.best(.K)
                    let kickerOvr = Double(kicker?.overall ?? 65)
                    let fgProb = 0.85 - Double(fgDistance - 20) * 0.018 + (kickerOvr - 70) * 0.004
                    let made = Double.random(in: 0...1) < min(0.95, max(0.25, fgProb))
                    let fgPlay = PlayResult(type: "fg", yards: 0, isComplete: false,
                                            isTurnover: false, turnoverType: nil,
                                            isTouchdown: false,
                                            scoringPlayerName: made ? kicker?.name : nil,
                                            ballCarrierName: kicker?.name,
                                            description: made ? "FG GOOD from \(fgDistance) yards" : "FG MISSED from \(fgDistance) yards")
                    drivePlays.append(fgPlay)
                    allPlays.append(fgPlay)
                    if made {
                        if isHome { homeScore += 3 } else { awayScore += 3 }
                    }
                    let dr = DriveResult(teamName: offense.name, startPosition: startPos,
                                         plays: drivePlays, result: made ? "FG" : "FG_MISS",
                                         totalYards: driveYards, scoring: made ? 3 : 0)
                    allDrives.append(dr)
                    return
                } else if yardsToGo <= 2 && fieldPos >= 55 && scoreDiff < 0 {
                    // Go for it — continue
                    down = 1; yardsToGo = 10
                } else {
                    // Punt
                    let puntDist = max(28, min(62, Int(gaussRandom(mean: 42, std: 7))))
                    let punter = offense.best(.P)
                    let puntPlay = PlayResult(type: "punt", yards: 0, isComplete: false,
                                              isTurnover: false, turnoverType: nil,
                                              isTouchdown: false, scoringPlayerName: nil,
                                              ballCarrierName: punter?.name,
                                              description: "\(punter?.shortName ?? "Punter") punts \(puntDist) yards")
                    drivePlays.append(puntPlay)
                    allPlays.append(puntPlay)
                    if drivePlays.count <= 3 { adjustMomentum(toward: !isHome, amount: 0.10) }
                    let dr = DriveResult(teamName: offense.name, startPosition: startPos,
                                         plays: drivePlays, result: "PUNT",
                                         totalYards: driveYards, scoring: 0)
                    allDrives.append(dr)
                    return
                }
            }
        }

        // Max plays reached
        let dr = DriveResult(teamName: offense.name, startPosition: startPos,
                             plays: drivePlays, result: "END_OF_HALF",
                             totalYards: driveYards, scoring: 0)
        allDrives.append(dr)
    }

    // MARK: - Play simulation

    private func simulatePlay(offense: TeamSnap, defense: TeamSnap,
                               fieldPos: Int, down: Int, yardsToGo: Int,
                               scoreDiff: Int, quarter: Int, isHome: Bool) -> PlayResult {
        // Play call
        var passRate = 0.55
        if scoreDiff < -14 && quarter == 4 { passRate = 0.75 }
        else if scoreDiff > 14 && quarter == 4 { passRate = 0.30 }
        if fieldPos >= 95 { passRate = 0.40 } // goal line

        let roll = Double.random(in: 0...1)
        let scrambleRate = 0.05
        if roll < scrambleRate {
            return scramblePlay(offense: offense, defense: defense, isHome: isHome)
        } else if roll < scrambleRate + passRate {
            return passPlay(offense: offense, defense: defense, fieldPos: fieldPos, isHome: isHome)
        } else {
            return runPlay(offense: offense, defense: defense, fieldPos: fieldPos, isHome: isHome)
        }
    }

    private func passPlay(offense: TeamSnap, defense: TeamSnap,
                          fieldPos: Int, isHome: Bool) -> PlayResult {
        let qb = offense.best(.QB) ?? offense.starters[0]
        let wrs = offense.startersAt(.WR).sorted { $0.overall > $1.overall }
        let te = offense.best(.TE)
        let bestCB = defense.best(.CB) ?? defense.starters[0]
        let olAvg = offense.avgOverall(.OL)
        let dlAvg = defense.avgOverall(.DL)

        // Sack check
        let sackProb = max(0.03, min(0.12, 0.065 - (olAvg - dlAvg) * 0.002))
        if Double.random(in: 0...1) < sackProb {
            let yards = -Int.random(in: 4...12)
            let sacker = randomDefender(defense: defense, dlPct: 0.6, lbPct: 0.4)
            recordStat(sacker) { $0.sacks += 1 }
            recordStat(qb.name) { $0.passAttempts += 1 }
            return PlayResult(type: "sack", yards: yards, isComplete: false,
                              isTurnover: false, turnoverType: nil, isTouchdown: false,
                              scoringPlayerName: nil, ballCarrierName: qb.name,
                              description: "\(qb.shortName) sacked for \(yards) yds")
        }

        // Home field
        var compBonus = 0.0
        if !isNeutral {
            compBonus = isHome ? 0.009 : -0.006
            if (isHome && home.legacy > 80) || (!isHome && away.legacy > 80) {
                compBonus = isHome ? 0.014 : -0.009
            }
        }

        let bestWR = wrs.first ?? offense.starters[0]
        var compProb = 0.58 + Double(qb.awareness - 70) * 0.004
            + Double(bestWR.speed - 70) * 0.003
            - Double(bestCB.awareness - 70) * 0.003
            + momentum * (isHome ? 0.02 : -0.02) + compBonus
        compProb = max(0.40, min(0.75, compProb))

        recordStat(qb.name) { $0.passAttempts += 1 }

        // Pick target — best WR gets 40%, second 33%, third 20%, TE 7%
        let target: PlayerSnap
        let tRoll = Double.random(in: 0...1)
        if wrs.count >= 3 && tRoll < 0.40 { target = wrs[0] }
        else if wrs.count >= 2 && tRoll < 0.73 { target = wrs.count >= 2 ? wrs[1] : wrs[0] }
        else if let te = te, tRoll > 0.93 { target = te }
        else { target = wrs.count >= 3 ? wrs[2] : wrs.first ?? qb }

        if Double.random(in: 0...1) < compProb {
            // Complete
            var yards = max(1, Int(gaussRandom(mean: 8.0, std: 5.5)))
            if bestWR.speed > 85 && Double.random(in: 0...1) < 0.08 {
                yards += Int.random(in: 15...50)
            }
            let td = fieldPos + yards >= 100
            if td { yards = 100 - fieldPos }
            recordStat(qb.name) { $0.passCompletions += 1; $0.passYards += yards; if td { $0.passTDs += 1 } }
            recordStat(target.name) { $0.receptions += 1; $0.recYards += yards; if td { $0.recTDs += 1 } }
            distributeTackle(defense: defense)
            let desc = td ? "\(qb.shortName) → \(target.shortName) \(yards) yd TD!"
                          : "\(qb.shortName) → \(target.shortName) for \(yards) yds"
            if yards >= 20 { adjustMomentum(toward: isHome, amount: 0.10) }
            return PlayResult(type: "pass", yards: yards, isComplete: true,
                              isTurnover: false, turnoverType: nil, isTouchdown: td,
                              scoringPlayerName: td ? target.name : nil,
                              ballCarrierName: target.name, description: desc)
        } else {
            // Incomplete — INT check
            let sAvg = defense.avgOverall(.S)
            let intProb = max(0.01, min(0.06,
                0.035 - Double(qb.awareness - 70) * 0.001 + (sAvg - 70) * 0.001))
            if Double.random(in: 0...1) < intProb {
                let interceptor = randomDefender(defense: defense, dlPct: 0, lbPct: 0.1, cbPct: 0.5, sPct: 0.4)
                recordStat(qb.name) { $0.interceptions += 1 }
                recordStat(interceptor) { $0.ints += 1 }
                return PlayResult(type: "pass", yards: 0, isComplete: false,
                                  isTurnover: true, turnoverType: "INT", isTouchdown: false,
                                  scoringPlayerName: nil, ballCarrierName: qb.name,
                                  description: "\(qb.shortName) INTERCEPTED!")
            }
            return PlayResult(type: "pass", yards: 0, isComplete: false,
                              isTurnover: false, turnoverType: nil, isTouchdown: false,
                              scoringPlayerName: nil, ballCarrierName: qb.name,
                              description: "\(qb.shortName) pass incomplete to \(target.shortName)")
        }
    }

    private func runPlay(offense: TeamSnap, defense: TeamSnap,
                         fieldPos: Int, isHome: Bool) -> PlayResult {
        let rbs = offense.startersAt(.RB)
        let rb = rbs.first ?? offense.starters.first { $0.position == .RB } ?? offense.starters[0]
        let olAvg = offense.avgOverall(.OL)
        let dlAvg = defense.avgOverall(.DL)
        let lbAvg = defense.avgOverall(.LB)

        var rushBonus = 0.0
        if !isNeutral {
            rushBonus = isHome ? 0.12 : -0.06
        }

        var yards = gaussRandom(mean: 4.0 + rushBonus, std: 3.2)
            + Double(rb.speed - 70) * 0.08
            + Double(rb.strength - 70) * 0.06
            - (lbAvg - 70) * 0.05
            - (dlAvg - 70) * 0.04
            + momentum * (isHome ? 0.5 : -0.5)
        yards = max(-4, min(15, yards))

        if rb.speed > 82 && Double.random(in: 0...1) < 0.06 {
            yards += Double(Int.random(in: 15...55))
        }

        let intYards = Int(yards.rounded())
        let td = fieldPos + intYards >= 100
        let finalYards = td ? 100 - fieldPos : intYards

        // Fumble
        let fumbleProb = max(0.005, min(0.025, 0.013 - Double(rb.awareness - 70) * 0.0005))
        if Double.random(in: 0...1) < fumbleProb {
            let forcer = randomDefender(defense: defense, dlPct: 0.3, lbPct: 0.4, cbPct: 0.2, sPct: 0.1)
            recordStat(rb.name) { $0.rushAttempts += 1; $0.rushYards += finalYards }
            recordStat(forcer) { $0.fumblesForced += 1 }
            return PlayResult(type: "run", yards: finalYards, isComplete: false,
                              isTurnover: true, turnoverType: "FUMBLE", isTouchdown: false,
                              scoringPlayerName: nil, ballCarrierName: rb.name,
                              description: "\(rb.shortName) FUMBLES after \(finalYards) yds!")
        }

        recordStat(rb.name) { $0.rushAttempts += 1; $0.rushYards += finalYards; if td { $0.rushTDs += 1 } }
        distributeTackle(defense: defense)
        if finalYards >= 20 { adjustMomentum(toward: isHome, amount: 0.10) }
        let desc = td ? "\(rb.shortName) rushes \(finalYards) yds for a TD!"
                      : "\(rb.shortName) rushes for \(finalYards) yds"
        return PlayResult(type: "run", yards: finalYards, isComplete: false,
                          isTurnover: false, turnoverType: nil, isTouchdown: td,
                          scoringPlayerName: td ? rb.name : nil,
                          ballCarrierName: rb.name, description: desc)
    }

    private func scramblePlay(offense: TeamSnap, defense: TeamSnap, isHome: Bool) -> PlayResult {
        let qb = offense.best(.QB) ?? offense.starters[0]
        var yards = gaussRandom(mean: 3.5, std: 3.0)
            + Double(qb.speed - 70) * 0.10
        yards = max(-3, min(18, yards))
        let intYards = Int(yards.rounded())
        recordStat(qb.name) { $0.rushAttempts += 1; $0.rushYards += intYards }
        distributeTackle(defense: defense)
        return PlayResult(type: "scramble", yards: intYards, isComplete: false,
                          isTurnover: false, turnoverType: nil, isTouchdown: false,
                          scoringPlayerName: nil, ballCarrierName: qb.name,
                          description: "\(qb.shortName) scrambles for \(intYards) yds")
    }

    // MARK: - Stat helpers

    private func recordStat(_ name: String, update: (inout PlayerStats) -> Void) {
        var s = stats[name] ?? PlayerStats()
        update(&s)
        stats[name] = s
    }

    private func distributeTackle(defense: TeamSnap) {
        let tackler = randomDefender(defense: defense, dlPct: 0.25, lbPct: 0.40, cbPct: 0.20, sPct: 0.15)
        recordStat(tackler) { $0.tackles += 1 }
    }

    private func randomDefender(defense: TeamSnap, dlPct: Double = 0.25,
                                 lbPct: Double = 0.40, cbPct: Double = 0.20,
                                 sPct: Double = 0.15) -> String {
        let roll = Double.random(in: 0...1)
        let pos: Position
        if roll < dlPct { pos = .DL }
        else if roll < dlPct + lbPct { pos = .LB }
        else if roll < dlPct + lbPct + cbPct { pos = .CB }
        else { pos = .S }
        let candidates = defense.startersAt(pos)
        return candidates.randomElement()?.name ?? defense.starters.randomElement()?.name ?? "Unknown"
    }

    private func adjustMomentum(toward isHome: Bool, amount: Double) {
        momentum += isHome ? amount : -amount
        momentum *= 0.95 // decay
        momentum = max(-1, min(1, momentum))
    }
}

// MARK: - Snapshot builders

extension Team {
    func snapshot() -> TeamSnap {
        let starters = players.filter { $0.isStarter }.map { $0.snap() }
        let backups = players.filter { !$0.isStarter }.map { $0.snap() }
        return TeamSnap(name: name, abbreviation: abbreviation,
                        legacy: legacy, primaryColor: primaryColor,
                        starters: starters, backups: backups)
    }
}

extension Player {
    func snap() -> PlayerSnap {
        PlayerSnap(name: fullName, shortName: shortName,
                   position: position, speed: speed, strength: strength,
                   awareness: awareness, overall: overall, isStarter: isStarter)
    }
}
