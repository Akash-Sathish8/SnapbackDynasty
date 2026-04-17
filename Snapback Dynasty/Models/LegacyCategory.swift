import Foundation

/// The 14 school-grade categories that drive recruiting.
/// Same set is used for a recruit's motivations.
enum LegacyCategory: String, Codable, CaseIterable {
    case playingTime        = "Playing Time"
    case playingStyle       = "Playing Style"
    case titleContender     = "Title Contender"
    case tradition          = "Tradition"
    case campusLife         = "Campus Life"
    case gameDay            = "Game Day"
    case nflTrack           = "NFL Track"
    case nationalSpotlight  = "National Spotlight"
    case academics          = "Academics"
    case conferenceStrength = "Conference Strength"
    case coachReputation    = "Coach Reputation"
    case coachStability     = "Coach Stability"
    case facilities         = "Facilities"
    case proximity          = "Proximity"

    /// True if this grade can change during a season.
    var isDynamic: Bool {
        switch self {
        case .campusLife, .academics, .tradition, .facilities:
            return false
        default:
            return true
        }
    }
}

/// 13-point letter grade scale. Numeric value is used for the Rule-of-19
/// heuristic and for interest-alignment calculations.
enum LetterGrade: Int, Codable, CaseIterable, Comparable {
    case F = 1, Dminus, D, Dplus
    case Cminus, C, Cplus
    case Bminus, B, Bplus
    case Aminus, A, Aplus

    static func < (lhs: LetterGrade, rhs: LetterGrade) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .F: return "F"
        case .Dminus: return "D-"
        case .D: return "D"
        case .Dplus: return "D+"
        case .Cminus: return "C-"
        case .C: return "C"
        case .Cplus: return "C+"
        case .Bminus: return "B-"
        case .B: return "B"
        case .Bplus: return "B+"
        case .Aminus: return "A-"
        case .A: return "A"
        case .Aplus: return "A+"
        }
    }

    static func from(numeric: Int) -> LetterGrade {
        LetterGrade(rawValue: max(1, min(13, numeric))) ?? .C
    }
}
