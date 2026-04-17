import Foundation

/// Position → list of archetype names. Used during recruit generation.
enum Archetypes {
    static let byPosition: [Position: [String]] = [
        .QB: ["Field General", "Improviser", "Scrambler", "Backfield Creator", "Pocket Passer"],
        .RB: ["Power Rusher", "Elusive Back", "Receiving Back", "Balanced"],
        .WR: ["Route Runner", "Deep Threat", "Gadget", "Red Zone Threat", "Possession"],
        .TE: ["Vertical Threat", "Possession", "Blocking"],
        .OL: ["Power Blocker", "Pass Protector", "Agile Blocker"],
        .DL: ["Pass Rusher", "Run Stopper", "Power Rusher", "Speed Rusher"],
        .LB: ["Pass Coverage", "Run Stopper", "Blitzer", "Field General"],
        .CB: ["Man-to-Man", "Zone", "Slot", "Bump-and-Run"],
        .S:  ["Box Safety", "Zone", "Hybrid", "Ball Hawk"],
        .K:  ["Power Leg"],
        .P:  ["Power Leg"],
    ]

    static func random(for position: Position) -> String {
        (byPosition[position] ?? ["Balanced"]).randomElement()!
    }
}
