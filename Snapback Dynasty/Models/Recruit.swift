import Foundation
import SwiftData

/// A high-school prospect. ~4,000 are generated per class (CFB-scale pool).
@Model
final class Recruit {
    // MARK: - Identity
    var firstName: String
    var lastName: String
    var positionRaw: String
    var archetype: String  // e.g., "Field General", "Power Rusher"
    var homeState: String
    var pipelineRaw: String
    var classYear: Int  // generation year (2025, etc.)

    // MARK: - Rating
    var stars: Int              // 1-5
    var gemTagRaw: String       // Gem / Neutral / Overrated
    var devTraitRaw: String     // hidden until signed unless Scout's Eye unlocked

    // MARK: - Attributes (hidden until scouted; revealed in 4 tiers)
    var speed: Int
    var strength: Int
    var awareness: Int
    var potential: Int
    var overall: Int

    var scoutingTier: Int = 0   // 0 = unscouted, 4 = fully scouted

    // MARK: - Motivations (3 per recruit, from LegacyCategory)
    var motivationRaws: [String] = []       // 3 items
    var dealbreakerRaw: String               // single category
    var dealbreakerThreshold: Int = 8        // numeric LetterGrade; scales with OVR in CFB 26 model

    // MARK: - Cycle state
    var phaseRaw: String = RecruitPhase.discovery.rawValue
    var isCommittedToTeamId: String?         // Team.abbreviation of commit (nil if uncommitted)
    var isSigned: Bool = false

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \RecruitInterest.recruit)
    var interests: [RecruitInterest] = []

    init(firstName: String, lastName: String, position: Position, archetype: String,
         homeState: String, pipeline: Pipeline, classYear: Int,
         stars: Int, gemTag: GemTag, devTrait: DevTrait,
         speed: Int, strength: Int, awareness: Int, potential: Int,
         motivations: [LegacyCategory], dealbreaker: LegacyCategory,
         dealbreakerThreshold: LetterGrade = .Cplus) {
        self.firstName = firstName
        self.lastName = lastName
        self.positionRaw = position.rawValue
        self.archetype = archetype
        self.homeState = homeState
        self.pipelineRaw = pipeline.rawValue
        self.classYear = classYear
        self.stars = stars
        self.gemTagRaw = gemTag.rawValue
        self.devTraitRaw = devTrait.rawValue
        self.speed = speed
        self.strength = strength
        self.awareness = awareness
        self.potential = potential
        self.motivationRaws = motivations.map(\.rawValue)
        self.dealbreakerRaw = dealbreaker.rawValue
        self.dealbreakerThreshold = dealbreakerThreshold.rawValue
        // Pre-compute overall with the same position-weighted formula used by Player.
        let w = position.overallWeights
        let raw = Double(speed) * w.speed + Double(strength) * w.strength + Double(awareness) * w.awareness
        self.overall = max(1, min(99, Int(raw.rounded())))
    }

    // MARK: - Computed
    var position: Position { Position(rawValue: positionRaw) ?? .QB }
    var pipeline: Pipeline { Pipeline(rawValue: pipelineRaw) ?? .gaRest }
    var gemTag: GemTag { GemTag(rawValue: gemTagRaw) ?? .neutral }
    var devTrait: DevTrait { DevTrait(rawValue: devTraitRaw) ?? .normal }
    var phase: RecruitPhase { RecruitPhase(rawValue: phaseRaw) ?? .discovery }
    var motivations: [LegacyCategory] { motivationRaws.compactMap(LegacyCategory.init) }
    var dealbreaker: LegacyCategory { LegacyCategory(rawValue: dealbreakerRaw) ?? .playingTime }
    var fullName: String { "\(firstName) \(lastName)" }

    // Scouting gates: which attributes are visible given current tier?
    var revealsOverall: Bool     { scoutingTier >= 1 }
    var revealsAttributes: Bool  { scoutingTier >= 2 }
    var revealsPotential: Bool   { scoutingTier >= 3 }
    var revealsDealbreaker: Bool { scoutingTier >= 2 }
    var revealsDevTrait: Bool    { scoutingTier >= 4 }  // CFB 26 Scout's Eye
}
