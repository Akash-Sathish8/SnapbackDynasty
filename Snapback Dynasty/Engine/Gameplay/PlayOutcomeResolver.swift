import Foundation

/// Resolves pass/run outcomes using player stats + timing + defensive play.
enum PlayOutcome {
    case complete(yards: Int)
    case incomplete
    case interception
    case sack(yardsLost: Int)
    case runResult(yards: Int)
    case fumble
    case touchdown
}

enum PlayOutcomeResolver {

    /// Resolve a pass attempt.
    /// - Parameters:
    ///   - timing: 0 = perfect, positive = late, negative = early
    ///   - qbAwareness: 1-99
    ///   - wrSpeed: 1-99
    ///   - cbAwareness: 1-99
    ///   - defense: the chosen defensive play (modifiers)
    ///   - routeDepth: how far the route goes (short < 40, deep >= 40)
    static func resolvePass(timing: Double, qbAwareness: Int, wrSpeed: Int,
                            cbAwareness: Int, defense: DefensivePlay?,
                            routeDepth: CGFloat) -> PlayOutcome {
        let isDeep = routeDepth >= 40
        let defMod = defense.map { isDeep ? $0.deepPassMod : $0.shortPassMod } ?? 0

        // Base catch probability from timing
        let baseCatch: Double
        if abs(timing) < 0.15 {
            baseCatch = 0.82  // sweet spot
        } else if timing < -0.2 {
            baseCatch = 0.50  // early
        } else if timing > 0.3 {
            baseCatch = 0.35  // late
        } else {
            baseCatch = 0.65  // decent
        }

        let statMod = Double(wrSpeed - cbAwareness) * 0.003
        let catchProb = max(0.10, min(0.95, baseCatch + statMod + defMod))

        let roll = Double.random(in: 0..<1)
        if roll < catchProb {
            var yards = Int(routeDepth / 3)  // rough yards from route depth
            // YAC based on WR speed
            let yac = Int(Double.random(in: 0...Double(wrSpeed) * 0.08))
            yards += yac
            return .complete(yards: max(1, yards))
        }

        // INT check — higher if late timing or way late
        let intProb = timing > 0.3 ? 0.18 : (timing > 0.15 ? 0.08 : 0.03)
        let intMod = Double(cbAwareness - qbAwareness) * 0.002
        if Double.random(in: 0..<1) < max(0.02, intProb + intMod) {
            return .interception
        }

        return .incomplete
    }

    /// Resolve a run play.
    static func resolveRun(rbSpeed: Int, rbStrength: Int, olStrength: Int,
                           dlSpeed: Int, lbSpeed: Int,
                           defense: DefensivePlay?,
                           distanceDragged: CGFloat) -> PlayOutcome {
        let defMod = defense?.runMod ?? 0
        let baseMod = Double(rbSpeed + rbStrength - dlSpeed - lbSpeed) * 0.04
        let dragBonus = Double(distanceDragged) * 0.1
        var yards = Int(3.0 + baseMod + dragBonus + defMod * 10)

        // Breakaway chance
        if rbSpeed > dlSpeed + 10 && Double.random(in: 0..<1) < 0.08 {
            yards += Int.random(in: 10...25)
        }

        // Fumble
        if Double.random(in: 0..<1) < 0.02 { return .fumble }

        return .runResult(yards: max(-3, yards))
    }

    /// Resolve a sack.
    static func resolveSack() -> PlayOutcome {
        .sack(yardsLost: Int.random(in: 4...10))
    }
}
