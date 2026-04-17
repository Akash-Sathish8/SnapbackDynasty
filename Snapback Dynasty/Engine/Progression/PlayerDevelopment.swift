import Foundation

/// Player attribute growth each offseason. Ported from retro-gridiron.
///
/// growth = baseRate × playingTimeMod × coachingMod × ageMod × uniform(0.7, 1.3)
enum PlayerDevelopment {

    /// Develop a single player. Caps attributes at `potential`.
    static func develop(_ player: Player, coachDevBonus: Int = 0) {
        let ageMod: Double = {
            switch player.classYear {
            case .FR: return 1.25
            case .SO: return 1.10
            case .JR: return 0.95
            case .SR: return 0.75
            }
        }()
        let ptMod: Double = player.isStarter ? 1.3 : 0.9
        let coachMod: Double = 1.0 + Double(coachDevBonus) * 0.01

        func grow(_ current: Int) -> Int {
            let base = 0.18 * ptMod * coachMod * ageMod * Double.random(in: 0.7...1.3)
            let points = Int((base * 6).rounded())  // 6 = rough per-attribute scale
            // Cap at potential.
            let capped = min(player.potential, current + points)
            return max(current, capped)
        }

        // 5% breakout (SO/JR) — 2x growth this offseason
        let multiplier: Double
        if (player.classYear == .SO || player.classYear == .JR) &&
           Double.random(in: 0..<1) < 0.05 {
            multiplier = 2.0
        } else if (player.classYear == .JR || player.classYear == .SR) &&
                  Double.random(in: 0..<1) < 0.03 {
            multiplier = -1.0  // regression
        } else {
            multiplier = 1.0
        }

        if multiplier > 0 {
            for _ in 0..<Int(multiplier) {
                player.speed = grow(player.speed)
                player.strength = grow(player.strength)
                player.awareness = grow(player.awareness)
            }
        } else {
            let drop = Int.random(in: 1...3)
            player.speed = max(30, player.speed - drop)
            player.strength = max(30, player.strength - drop)
            player.awareness = max(30, player.awareness - drop)
        }

        player.calculateOverall()
    }
}
