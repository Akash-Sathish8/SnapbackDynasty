import Foundation
import SwiftData

@Model
final class CoachingStaff {
    var team: Team?
    var offenseBonus: Int
    var defenseBonus: Int
    var recruitingBonus: Int
    var developmentBonus: Int

    // MARK: - Archetype & progression
    var archetypeRaw: String = CoachArchetype.recruiter.rawValue
    var level: Int = 1
    var xp: Int = 0

    /// Which pipeline this coach brings; stacks with school tiers.
    var primaryPipelineRaw: String = Pipeline.gaRest.rawValue

    /// Unlocked abilities (raw values of CoachAbility).
    var abilityRaws: [String] = []

    init(offenseBonus: Int = 3, defenseBonus: Int = 3,
         recruitingBonus: Int = 3, developmentBonus: Int = 3,
         archetype: CoachArchetype = .recruiter,
         primaryPipeline: Pipeline = .gaRest) {
        self.offenseBonus = offenseBonus
        self.defenseBonus = defenseBonus
        self.recruitingBonus = recruitingBonus
        self.developmentBonus = developmentBonus
        self.archetypeRaw = archetype.rawValue
        self.primaryPipelineRaw = primaryPipeline.rawValue
    }

    var archetype: CoachArchetype { CoachArchetype(rawValue: archetypeRaw) ?? .recruiter }
    var primaryPipeline: Pipeline { Pipeline(rawValue: primaryPipelineRaw) ?? .gaRest }
    var abilities: [CoachAbility] { abilityRaws.compactMap(CoachAbility.init) }

    func has(_ ability: CoachAbility) -> Bool { abilities.contains(ability) }
}
