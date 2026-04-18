import Foundation
import SwiftData

enum TransferEntryStatus: String, Codable {
    case available  = "Available"
    case retained   = "Retained"
    case committed  = "Committed"
    case aiClaimed  = "AI Claimed"
}

@Model
final class TransferEntry {
    var firstName: String
    var lastName: String
    var positionRaw: String
    var overallAtEntry: Int
    var starsAtEntry: Int
    var fromTeam: Team?
    var toTeam: Team?
    var player: Player?
    var seasonYear: Int
    var statusRaw: String

    /// Whether this entry is on the player's portal recruiting board.
    var isOnPlayerBoard: Bool = false

    /// Interest level built up by the player through portal actions (0–100).
    var portalInterestLevel: Double = 0

    init(player: Player, fromTeam: Team, seasonYear: Int) {
        self.firstName = player.firstName
        self.lastName = player.lastName
        self.positionRaw = player.positionRaw
        self.overallAtEntry = player.overall
        self.starsAtEntry = player.stars
        self.fromTeam = fromTeam
        self.toTeam = nil
        self.player = player
        self.seasonYear = seasonYear
        self.statusRaw = TransferEntryStatus.available.rawValue
    }

    var position: Position { Position(rawValue: positionRaw) ?? .QB }
    var fullName: String { "\(firstName) \(lastName)" }
    var status: TransferEntryStatus {
        get { TransferEntryStatus(rawValue: statusRaw) ?? .available }
        set { statusRaw = newValue.rawValue }
    }
}
