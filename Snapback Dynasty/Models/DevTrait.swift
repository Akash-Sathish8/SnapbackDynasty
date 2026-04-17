import Foundation

/// Hidden-until-signing development trait. Drives XP multiplier on
/// accrued stats and determines skill ceiling.
enum DevTrait: String, Codable, CaseIterable {
    case normal = "Normal"
    case impact = "Impact"
    case star   = "Star"
    case elite  = "Elite"

    var xpMultiplier: Double {
        switch self {
        case .normal: return 1.00
        case .impact: return 1.35
        case .star:   return 1.75
        case .elite:  return 2.50
        }
    }
}

/// Visible probability indicator on a recruit's card.
enum GemTag: String, Codable, CaseIterable {
    case gem       = "Gem"        // skews higher dev trait
    case neutral   = "Neutral"
    case overrated = "Overrated"  // skews lower dev trait
}
