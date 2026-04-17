import Foundation
import SwiftData

enum AwardType: String, Codable, CaseIterable {
    case heisman        = "Heisman Trophy"
    case allAmerican    = "All-American"
    case allConference  = "All-Conference"
    case offensivePOY   = "Offensive Player of the Year"
    case defensivePOY   = "Defensive Player of the Year"
}

@Model
final class Award {
    var seasonYear: Int
    var typeRaw: String
    var playerName: String
    var teamAbbreviation: String
    var position: String
    var statLine: String  // e.g., "3,412 yds, 32 TDs"
    var conferenceName: String?

    init(seasonYear: Int, type: AwardType, playerName: String,
         teamAbbreviation: String, position: String, statLine: String,
         conferenceName: String? = nil) {
        self.seasonYear = seasonYear
        self.typeRaw = type.rawValue
        self.playerName = playerName
        self.teamAbbreviation = teamAbbreviation
        self.position = position
        self.statLine = statLine
        self.conferenceName = conferenceName
    }

    var type: AwardType { AwardType(rawValue: typeRaw) ?? .heisman }
}
