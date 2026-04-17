import Foundation

/// Lightweight roster snapshot — pulled from real Team models at game start.
/// Used by GameplayScene + PlayOutcomeResolver so outcomes are driven by
/// actual player attributes, not hardcoded values.
struct GameplayRoster {
    struct PlayerStat {
        let number: Int
        let position: Position
        let speed: Int
        let strength: Int
        let awareness: Int
        let overall: Int
    }

    let teamName: String
    let abbreviation: String
    let primaryColor: String
    let secondaryColor: String
    let logoURL: String

    let qb: PlayerStat
    let rbs: [PlayerStat]           // top 2
    let wrs: [PlayerStat]           // top 3
    let te: PlayerStat
    let ol: [PlayerStat]            // 5
    let dl: [PlayerStat]            // 4
    let lb: [PlayerStat]            // 3
    let cb: [PlayerStat]            // 3
    let safeties: [PlayerStat]      // 2
    let kicker: PlayerStat

    /// Average OL strength (for pass-block timing).
    var olStrength: Int {
        guard !ol.isEmpty else { return 70 }
        return ol.map(\.strength).reduce(0, +) / ol.count
    }

    /// Average DL speed (for pass rush).
    var dlSpeed: Int {
        guard !dl.isEmpty else { return 70 }
        return dl.map(\.speed).reduce(0, +) / dl.count
    }

    /// Average CB awareness (for pass defense).
    var cbAwareness: Int {
        guard !cb.isEmpty else { return 70 }
        return cb.map(\.awareness).reduce(0, +) / cb.count
    }

    /// Average LB speed (for run defense).
    var lbSpeed: Int {
        guard !lb.isEmpty else { return 70 }
        return lb.map(\.speed).reduce(0, +) / lb.count
    }

    /// Jersey color for the offense/defense based on home/away.
    /// Home wears team color; Away wears white with a colored trim.
    var homeJerseyColor: String { primaryColor }
    var awayJerseyColor: String { "#F5F5F5" }  // off-white
    var pantsColor: String { secondaryColor }
}

extension GameplayRoster {
    /// Build a roster snapshot from a real Team.
    static func from(team: Team, secondaryFallback: String = "#1C1917") -> GameplayRoster {
        let players = team.players.sorted { $0.overall > $1.overall }

        func filter(_ position: Position, take: Int = 1) -> [PlayerStat] {
            let filtered = players.filter { $0.position == position }.prefix(take)
            return filtered.enumerated().map { i, p in
                PlayerStat(number: jerseyNumber(for: position, index: i),
                           position: position, speed: p.speed, strength: p.strength,
                           awareness: p.awareness, overall: p.overall)
            }
        }

        let qb = filter(.QB, take: 1).first ?? .init(number: 1, position: .QB,
            speed: 60, strength: 60, awareness: 60, overall: 60)
        let rbs = filter(.RB, take: 2)
        let wrs = filter(.WR, take: 3)
        let te = filter(.TE, take: 1).first ?? .init(number: 88, position: .TE,
            speed: 70, strength: 70, awareness: 70, overall: 70)
        let ol = filter(.OL, take: 5)
        let dl = filter(.DL, take: 4)
        let lb = filter(.LB, take: 3)
        let cb = filter(.CB, take: 3)
        let s = filter(.S, take: 2)
        let k = filter(.K, take: 1).first ?? .init(number: 2, position: .K,
            speed: 50, strength: 70, awareness: 70, overall: 70)

        return GameplayRoster(
            teamName: team.name,
            abbreviation: team.abbreviation,
            primaryColor: team.primaryColor,
            secondaryColor: team.secondaryColor.isEmpty ? secondaryFallback : team.secondaryColor,
            logoURL: team.logoURL,
            qb: qb, rbs: rbs, wrs: wrs, te: te, ol: ol, dl: dl, lb: lb, cb: cb,
            safeties: s, kicker: k
        )
    }

    private static func jerseyNumber(for position: Position, index: Int) -> Int {
        switch position {
        case .QB: return [1, 12, 7][index % 3]
        case .RB: return [22, 28, 34][index % 3]
        case .WR: return [11, 82, 13][index % 3]
        case .TE: return 88
        case .OL: return [65, 71, 74, 78, 52][index % 5]
        case .DL: return [91, 94, 97, 99][index % 4]
        case .LB: return [44, 54, 58][index % 3]
        case .CB: return [21, 24, 27][index % 3]
        case .S:  return [20, 31][index % 2]
        case .K:  return 3
        case .P:  return 5
        }
    }
}
