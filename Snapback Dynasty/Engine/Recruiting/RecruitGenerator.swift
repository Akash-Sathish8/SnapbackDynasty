import Foundation
import SwiftData

/// Generates a full recruiting class. Mirrors EA CFB 25/26 scale and mix —
/// but with our synonym terminology (All In / Full Pitch / Nudge / Reframe).
enum RecruitGenerator {

    /// Default class size. CFB 25 ships ~3,500; CFB 26 ~4,100. We use 1500
    /// for mobile — enough to keep K/P pools deep without seeding lag.
    static let classSize: Int = 1500

    /// Star distribution: pyramid-shaped.
    /// 5★ 2%, 4★ 10%, 3★ 35%, 2★ 35%, 1★ 18%
    private static let starCuts: [(stars: Int, cumulative: Double)] = [
        (5, 0.02), (4, 0.12), (3, 0.47), (2, 0.82), (1, 1.00),
    ]

    /// Position generation weights.
    private static let positionWeights: [(Position, Double)] = [
        (.QB, 0.07), (.RB, 0.09), (.WR, 0.15), (.TE, 0.06),
        (.OL, 0.20), (.DL, 0.16), (.LB, 0.10), (.CB, 0.09),
        (.S, 0.05), (.K, 0.015), (.P, 0.015),
    ]

    // MARK: - Public

    /// Generate and insert a recruiting class into the provided context.
    /// - Parameter classYear: e.g., 2027 (the year the class signs).
    static func generateClass(into context: ModelContext, classYear: Int,
                              count: Int = RecruitGenerator.classSize) {
        for _ in 0..<count {
            let r = generateOne(classYear: classYear)
            context.insert(r)
        }
    }

    // MARK: - Internal

    static func generateOne(classYear: Int) -> Recruit {
        let stars = rollStars()
        let position = rollPosition()
        let archetype = Archetypes.random(for: position)
        let state = StatePipeline.randomState()
        let pipeline = StatePipeline.pipeline(for: state)
        let (speed, strength, awareness) = rollAttributes(stars: stars, position: position)
        let potential = rollPotential(stars: stars, currentOverall: compute(position: position, s: speed, str: strength, a: awareness))
        let devTrait = rollDevTrait(stars: stars)
        let gem = rollGemTag(stars: stars, devTrait: devTrait)

        let allCats = LegacyCategory.allCases
        // Three unique motivations
        var shuffled = allCats.shuffled()
        let motivations = Array(shuffled.prefix(3))
        shuffled.removeFirst(3)
        let dealbreaker = shuffled.randomElement() ?? .playingTime

        // Dealbreaker threshold scales with stars (higher star = higher demand)
        let threshold: LetterGrade
        switch stars {
        case 5: threshold = .Bplus
        case 4: threshold = .B
        case 3: threshold = .Cplus
        case 2: threshold = .C
        default: threshold = .Cminus
        }

        let first = firstNames.randomElement() ?? "Jordan"
        let last = lastNames.randomElement() ?? "Johnson"

        return Recruit(
            firstName: first, lastName: last,
            position: position, archetype: archetype,
            homeState: state, pipeline: pipeline, classYear: classYear,
            stars: stars, gemTag: gem, devTrait: devTrait,
            speed: speed, strength: strength, awareness: awareness,
            potential: potential,
            motivations: motivations, dealbreaker: dealbreaker,
            dealbreakerThreshold: threshold
        )
    }

    // MARK: - Rolls

    private static func rollStars() -> Int {
        let r = Double.random(in: 0..<1)
        for cut in starCuts where r <= cut.cumulative { return cut.stars }
        return 1
    }

    private static func rollPosition() -> Position {
        let total = positionWeights.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        for (p, w) in positionWeights {
            if r < w { return p }
            r -= w
        }
        return .OL
    }

    /// Attribute rolls by star; position weighting happens via overall calc.
    private static func rollAttributes(stars: Int, position: Position)
        -> (speed: Int, strength: Int, awareness: Int) {
        let base: (mean: Double, std: Double)
        switch stars {
        case 5: base = (84, 5)
        case 4: base = (76, 5)
        case 3: base = (66, 6)
        case 2: base = (57, 6)
        default: base = (49, 6)
        }
        func g() -> Int {
            let v = gaussRandom(mean: base.mean, std: base.std)
            return max(30, min(99, Int(v.rounded())))
        }
        // Bias attributes toward position strengths (give extra to the dominant axis).
        let w = position.overallWeights
        let boost = 4
        var spd = g(); var str = g(); var awr = g()
        if w.speed > 0.4 { spd = min(99, spd + boost) }
        if w.strength > 0.4 { str = min(99, str + boost) }
        if w.awareness > 0.4 { awr = min(99, awr + boost) }
        return (spd, str, awr)
    }

    /// Potential is mostly independent of stars (3★ diamonds exist).
    private static func rollPotential(stars: Int, currentOverall: Int) -> Int {
        let base = Double(currentOverall) + gaussRandom(mean: 6, std: 10)
        let clamped = max(40, min(99, Int(base.rounded())))
        // 5% pool-wide chance of true gem: potential +10–15 on top of base
        if Double.random(in: 0..<1) < 0.05 {
            return min(99, clamped + Int.random(in: 10...15))
        }
        return clamped
    }

    private static func compute(position: Position, s: Int, str: Int, a: Int) -> Int {
        let w = position.overallWeights
        let raw = Double(s) * w.speed + Double(str) * w.strength + Double(a) * w.awareness
        return max(1, min(99, Int(raw.rounded())))
    }

    /// Dev trait rolled per-recruit. Higher stars skew toward Elite/Star.
    private static func rollDevTrait(stars: Int) -> DevTrait {
        let r = Double.random(in: 0..<1)
        let p: (elite: Double, star: Double, impact: Double)
        switch stars {
        case 5: p = (0.12, 0.25, 0.40)
        case 4: p = (0.04, 0.15, 0.33)
        case 3: p = (0.01, 0.07, 0.25)
        case 2: p = (0.005, 0.03, 0.15)
        default: p = (0.002, 0.02, 0.10)
        }
        if r < p.elite { return .elite }
        if r < p.elite + p.star { return .star }
        if r < p.elite + p.star + p.impact { return .impact }
        return .normal
    }

    /// Gem tag correlates with dev trait but isn't a direct reveal.
    private static func rollGemTag(stars: Int, devTrait: DevTrait) -> GemTag {
        // Gems concentrate on 2–3★ with Impact+ dev traits.
        let r = Double.random(in: 0..<1)
        switch (stars, devTrait) {
        case (2, .elite), (3, .elite), (2, .star), (3, .star):
            return r < 0.70 ? .gem : .neutral
        case (2, .impact), (3, .impact):
            return r < 0.30 ? .gem : (r < 0.95 ? .neutral : .overrated)
        case (4, .normal), (5, .normal):
            return r < 0.40 ? .overrated : .neutral
        default:
            if r < 0.08 { return .gem }
            if r < 0.18 { return .overrated }
            return .neutral
        }
    }
}
