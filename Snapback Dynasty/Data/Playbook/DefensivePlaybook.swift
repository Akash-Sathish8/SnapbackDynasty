import Foundation

/// 4 defensive play calls. Auto-resolved against the offense.
/// Counter-play modifiers determine outcome probabilities.
enum DefensivePlaybook {

    static let all: [DefensivePlay] = [cover2, manToMan, blitz, zone3]

    /// Cover 2: two deep safeties, stops deep passes. Weak to short middle routes.
    static let cover2 = DefensivePlay(
        name: "Cover 2",
        description: "Stops deep",
        pressureMultiplier: 1.0,
        shortPassMod: 0.10,    // weak against short
        deepPassMod: -0.20,    // strong against deep
        runMod: 0.0
    )

    /// Man-to-Man: tight coverage on every receiver. Weak to crossing/drag routes.
    static let manToMan = DefensivePlay(
        name: "Man",
        description: "Tight coverage",
        pressureMultiplier: 1.0,
        shortPassMod: -0.10,
        deepPassMod: -0.05,
        runMod: 0.10    // weak against runs (LBs in coverage)
    )

    /// Blitz: extra rushers. Fast pressure. Weak to quick passes and screens.
    static let blitz = DefensivePlay(
        name: "Blitz",
        description: "Rush all",
        pressureMultiplier: 1.6,
        shortPassMod: 0.15,    // weak if QB gets it out fast
        deepPassMod: 0.20,     // weak deep (fewer DBs)
        runMod: -0.15          // good against runs (extra men at LOS)
    )

    /// Zone 3: three-deep zone. Stops short and intermediate. Weak to deep shots and runs.
    static let zone3 = DefensivePlay(
        name: "Zone 3",
        description: "Cover short",
        pressureMultiplier: 0.85,
        shortPassMod: -0.15,
        deepPassMod: 0.10,
        runMod: 0.05
    )
}
