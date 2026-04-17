import Foundation
import SwiftData

enum Position: String, Codable, CaseIterable {
    case QB, RB, WR, TE, OL, DL, LB, CB, S, K, P

    var overallWeights: (speed: Double, strength: Double, awareness: Double) {
        switch self {
        case .QB: return (0.25, 0.15, 0.60)
        case .RB: return (0.45, 0.30, 0.25)
        case .WR: return (0.50, 0.15, 0.35)
        case .TE: return (0.25, 0.40, 0.35)
        case .OL: return (0.10, 0.55, 0.35)
        case .DL: return (0.25, 0.50, 0.25)
        case .LB: return (0.35, 0.35, 0.30)
        case .CB: return (0.50, 0.10, 0.40)
        case .S:  return (0.40, 0.20, 0.40)
        case .K:  return (0.10, 0.30, 0.60)
        case .P:  return (0.10, 0.30, 0.60)
        }
    }

    var starterCount: Int {
        switch self {
        case .QB: return 1; case .RB: return 1; case .WR: return 3
        case .TE: return 1; case .OL: return 5; case .DL: return 4
        case .LB: return 3; case .CB: return 3; case .S: return 2
        case .K: return 1; case .P: return 1
        }
    }

    /// Only starters + minimum depth. Cuts roster to ~27 per team.
    var rosterCount: Int {
        switch self {
        case .QB: return 1; case .RB: return 1; case .WR: return 3
        case .TE: return 1; case .OL: return 7; case .DL: return 4
        case .LB: return 3; case .CB: return 3; case .S: return 2
        case .K: return 1; case .P: return 1
        }
    }
}

enum ClassYear: String, Codable, CaseIterable {
    case FR, SO, JR, SR
}

@Model
final class Player {
    var firstName: String
    var lastName: String
    var positionRaw: String
    var yearRaw: String
    var team: Team?
    var speed: Int
    var strength: Int
    var awareness: Int
    var potential: Int
    var overall: Int
    var stars: Int
    var homeState: String
    var isStarter: Bool = false
    var gamesPlayed: Int = 0
    var isInjured: Bool = false
    var injuryWeeks: Int = 0

    var position: Position {
        get { Position(rawValue: positionRaw) ?? .QB }
        set { positionRaw = newValue.rawValue }
    }

    var classYear: ClassYear {
        get { ClassYear(rawValue: yearRaw) ?? .FR }
        set { yearRaw = newValue.rawValue }
    }

    var fullName: String { "\(firstName) \(lastName)" }
    var shortName: String { "\(firstName.prefix(1)). \(lastName)" }

    init(firstName: String, lastName: String, position: Position,
         year: ClassYear, speed: Int, strength: Int, awareness: Int,
         potential: Int, homeState: String = "TX") {
        self.firstName = firstName
        self.lastName = lastName
        self.positionRaw = position.rawValue
        self.yearRaw = year.rawValue
        self.speed = speed
        self.strength = strength
        self.awareness = awareness
        self.potential = potential
        self.homeState = homeState
        self.stars = 3
        self.overall = 50
        self.calculateOverall()
    }

    @discardableResult
    func calculateOverall() -> Int {
        let w = position.overallWeights
        let raw = Double(speed) * w.speed + Double(strength) * w.strength + Double(awareness) * w.awareness
        overall = max(1, min(99, Int(raw.rounded())))
        if overall >= 85 { stars = [4, 5].randomElement()! }
        else if overall >= 70 { stars = 3 }
        else if overall >= 60 { stars = 2 }
        else { stars = 1 }
        return overall
    }
}
