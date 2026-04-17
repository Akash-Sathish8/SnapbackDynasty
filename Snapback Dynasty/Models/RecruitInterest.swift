import Foundation
import SwiftData

/// Tracks one team's standing with one recruit across the cycle.
@Model
final class RecruitInterest {
    var recruit: Recruit?
    var team: Team?

    /// 0–100 interest bar fill. 100 = commit-eligible.
    var interestLevel: Double = 0

    /// Hours the team has invested this season (diagnostics).
    var hoursInvested: Int = 0

    /// Weekly hours burned this week (resets each advance).
    var hoursThisWeek: Int = 0

    /// Does the team currently hold a scholarship offer out?
    var hasOffered: Bool = false

    /// Did the recruit take a visit with this team? And when (week).
    var visitWeek: Int?

    /// Their current top-list slot from this team's perspective.
    var topSlotRaw: Int = TopListSlot.notOnList.rawValue

    init(recruit: Recruit, team: Team) {
        self.recruit = recruit
        self.team = team
    }

    var topSlot: TopListSlot { TopListSlot(rawValue: topSlotRaw) ?? .notOnList }
}
