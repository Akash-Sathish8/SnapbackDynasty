import Foundation
import SwiftData

@Model
final class Team {
    var name: String
    var mascot: String
    var abbreviation: String
    var conference: Conference?
    var legacy: Int
    var offenseRating: Double
    var defenseRating: Double
    var homeState: String
    var primaryColor: String
    var secondaryColor: String = "#1C1917"
    var logoURL: String
    var wins: Int = 0
    var losses: Int = 0
    var conferenceWins: Int = 0
    var conferenceLosses: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Player.team)
    var players: [Player] = []

    @Relationship(deleteRule: .cascade, inverse: \SchoolGrade.team)
    var schoolGrades: [SchoolGrade] = []

    @Relationship(deleteRule: .cascade, inverse: \RecruitInterest.team)
    var recruitInterests: [RecruitInterest] = []

    var coachingStaff: CoachingStaff?

    init(name: String, mascot: String, abbreviation: String,
         legacy: Int, homeState: String, primaryColor: String,
         secondaryColor: String = "#1C1917",
         logoURL: String = "") {
        self.name = name
        self.mascot = mascot
        self.abbreviation = abbreviation
        self.legacy = legacy
        self.homeState = homeState
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.logoURL = logoURL
        self.offenseRating = 50
        self.defenseRating = 50
    }

    /// Returns this team's pipeline tier for the given region. Static table
    /// lookup; see PipelineTiers for data.
    func tier(for pipeline: Pipeline) -> PipelineTier {
        PipelineTiers.tier(team: abbreviation, pipeline: pipeline)
    }

    /// Convenience: current grade for a category (defaults to C if not seeded).
    func grade(for category: LegacyCategory) -> LetterGrade {
        schoolGrades.first { $0.category == category }?.letter ?? .C
    }

    var record: String { "\(wins)-\(losses)" }
    var confRecord: String { "\(conferenceWins)-\(conferenceLosses)" }
}
