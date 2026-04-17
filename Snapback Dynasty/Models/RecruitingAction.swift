import Foundation

/// Weekly recruiting actions. Hour costs mirror EA CFB 25/26 reference.
enum RecruitingAction: String, Codable, CaseIterable {
    case scout          = "Scout"
    case searchSocial   = "Social"
    case dm             = "DM"
    case contactFamily  = "Contact"
    case allIn          = "All In"
    case offer          = "Offer"
    case scheduleVisit  = "Visit"
    case nudge          = "Nudge"
    case fullPitch      = "Full Pitch"
    case reframe        = "Reframe"

    var hourCost: Int {
        switch self {
        case .scout:         return 10
        case .searchSocial:  return 5
        case .dm:            return 10
        case .contactFamily: return 25
        case .allIn:         return 50
        case .offer:         return 5
        case .scheduleVisit: return 40   // CFB 26: scales 10–40 by distance
        case .nudge:         return 20
        case .fullPitch:     return 40
        case .reframe:       return 30
        }
    }

    /// Availability gate against the recruit's current phase & top-list slot.
    var requiresTop5: Bool {
        switch self {
        case .scheduleVisit, .nudge, .fullPitch, .reframe: return true
        default: return false
        }
    }
}

/// Recruiting phase state machine.
enum RecruitPhase: String, Codable, CaseIterable {
    case discovery = "Discovery"
    case pitch     = "Pitch"
    case close     = "Close"
    case committed = "Committed"
    case signed    = "Signed"
}

/// Slot in a recruit's top-list as seen from a school.
enum TopListSlot: Int, Codable, CaseIterable {
    case notOnList = 0
    case top10 = 10
    case top8 = 8
    case top5 = 5
    case top3 = 3
    case leader = 1
}
