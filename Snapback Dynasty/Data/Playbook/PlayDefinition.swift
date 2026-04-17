import Foundation

/// A single route: a sequence of waypoints relative to the receiver's start.
struct RouteWaypoint {
    let dx: CGFloat   // lateral movement (negative = left, positive = right)
    let dy: CGFloat   // upfield movement
    let duration: TimeInterval  // how long this segment takes
}

/// A complete route path for one receiver.
struct Route {
    let name: String  // "Go", "Slant", "Curl", etc.
    let waypoints: [RouteWaypoint]

    /// At which waypoint index the "sweet spot" timing window opens.
    /// -1 if no sweet spot (e.g., blocker).
    var sweetSpotIndex: Int = -1
}

/// Hot routes the user can override per receiver.
enum HotRoute: String, CaseIterable {
    case slant = "Slant"
    case fade  = "Fade"
    case curl  = "Curl"
    case go    = "Go"

    var route: Route {
        switch self {
        case .slant:
            return Route(name: "Slant", waypoints: [
                RouteWaypoint(dx: 0, dy: 20, duration: 0.4),
                RouteWaypoint(dx: 40, dy: 60, duration: 0.8),
            ], sweetSpotIndex: 1)
        case .fade:
            return Route(name: "Fade", waypoints: [
                RouteWaypoint(dx: -15, dy: 30, duration: 0.5),
                RouteWaypoint(dx: -25, dy: 100, duration: 1.2),
            ], sweetSpotIndex: 1)
        case .curl:
            return Route(name: "Curl", waypoints: [
                RouteWaypoint(dx: 0, dy: 50, duration: 0.7),
                RouteWaypoint(dx: 0, dy: -8, duration: 0.3),
            ], sweetSpotIndex: 1)
        case .go:
            return Route(name: "Go", waypoints: [
                RouteWaypoint(dx: 0, dy: 140, duration: 1.8),
            ], sweetSpotIndex: 0)
        }
    }
}

/// Defines an offensive play.
struct PlayDefinition {
    /// Playcalling bucket shown to the user. Each play belongs to exactly one.
    enum Category: String, CaseIterable {
        case run        = "Run"
        case shortPass  = "Short Pass"
        case mediumPass = "Medium Pass"
        case longPass   = "Long Pass"
    }

    let name: String
    let formation: Formation
    let isRunPlay: Bool
    let category: Category

    /// Routes keyed by slot role. Missing entries = block.
    let routes: [Formation.SlotRole: Route]

    /// For run plays: the direction/path for the RB.
    let runPath: [RouteWaypoint]?

    /// Audible alternate (name of another play in same formation).
    var audibleAlt: String? = nil
}

/// Defines a defensive play.
struct DefensivePlay {
    let name: String
    let description: String

    /// Multiplier on DL rush speed (Blitz = fast).
    let pressureMultiplier: Double

    /// How much this defense penalizes short/deep/run plays.
    /// Negative = good defense against; positive = weak against.
    let shortPassMod: Double
    let deepPassMod: Double
    let runMod: Double
}
