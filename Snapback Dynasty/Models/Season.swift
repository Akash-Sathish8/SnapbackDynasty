import Foundation
import SwiftData

enum RecruitingPeriod: String, Codable, CaseIterable {
    case offseason       = "Offseason"
    case regularSeason   = "Regular Season"
    case earlySigning    = "Early Signing"
    case postSeason      = "Post-Season"
    case nationalSigning = "National Signing"
}

@Model
final class Season {
    var year: Int
    var currentWeek: Int = 0
    var isActive: Bool = true

    /// Recruiting hours remaining for the player's team this week.
    var recruitingHoursRemaining: Int = 0

    /// Where we are in the recruiting calendar.
    var recruitingPeriodRaw: String = RecruitingPeriod.offseason.rawValue

    var portalIsOpen: Bool = false
    var portalHoursRemaining: Int = 0
    var portalRetentionOffersRemaining: Int = 0

    init(year: Int) {
        self.year = year
    }

    var recruitingPeriod: RecruitingPeriod {
        RecruitingPeriod(rawValue: recruitingPeriodRaw) ?? .offseason
    }
}
