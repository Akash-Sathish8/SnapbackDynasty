import Foundation

/// Complete offensive playbook: 25 plays across 5 formations.
enum Playbook {

    static let all: [PlayDefinition] = shotgun + iForm + spread + pistol + singleback

    static func plays(for formation: Formation) -> [PlayDefinition] {
        all.filter { $0.formation == formation }
    }

    static func plays(for category: PlayDefinition.Category) -> [PlayDefinition] {
        all.filter { $0.category == category }
    }

    // MARK: - Route shorthand

    private static func go(_ dy: CGFloat = 140) -> Route {
        Route(name: "Go", waypoints: [.init(dx: 0, dy: dy, duration: 1.8)], sweetSpotIndex: 0)
    }
    private static func slant(dir: CGFloat = 1) -> Route {
        Route(name: "Slant", waypoints: [
            .init(dx: 0, dy: 18, duration: 0.3),
            .init(dx: 40 * dir, dy: 55, duration: 0.7),
        ], sweetSpotIndex: 1)
    }
    private static func curl(_ depth: CGFloat = 50) -> Route {
        Route(name: "Curl", waypoints: [
            .init(dx: 0, dy: depth, duration: 0.7),
            .init(dx: 0, dy: -8, duration: 0.25),
        ], sweetSpotIndex: 1)
    }
    private static func out(dir: CGFloat = 1, depth: CGFloat = 40) -> Route {
        Route(name: "Out", waypoints: [
            .init(dx: 0, dy: depth, duration: 0.5),
            .init(dx: 35 * dir, dy: 0, duration: 0.4),
        ], sweetSpotIndex: 1)
    }
    private static func flat(dir: CGFloat = 1) -> Route {
        Route(name: "Flat", waypoints: [
            .init(dx: 40 * dir, dy: 5, duration: 0.5),
        ], sweetSpotIndex: 0)
    }
    private static func post(dir: CGFloat = 1) -> Route {
        Route(name: "Post", waypoints: [
            .init(dx: 0, dy: 50, duration: 0.6),
            .init(dx: 30 * dir, dy: 80, duration: 1.0),
        ], sweetSpotIndex: 1)
    }
    private static func corner(dir: CGFloat = 1) -> Route {
        Route(name: "Corner", waypoints: [
            .init(dx: 0, dy: 40, duration: 0.5),
            .init(dx: -40 * dir, dy: 70, duration: 0.9),
        ], sweetSpotIndex: 1)
    }
    private static func drag(dir: CGFloat = 1) -> Route {
        Route(name: "Drag", waypoints: [
            .init(dx: 60 * dir, dy: 8, duration: 0.8),
        ], sweetSpotIndex: 0)
    }
    private static func wheel(dir: CGFloat = 1) -> Route {
        Route(name: "Wheel", waypoints: [
            .init(dx: 20 * dir, dy: 5, duration: 0.3),
            .init(dx: 10 * dir, dy: 100, duration: 1.2),
        ], sweetSpotIndex: 1)
    }
    private static let block = Route(name: "Block", waypoints: [], sweetSpotIndex: -1)

    // MARK: - Shotgun (5 plays)

    static let shotgun: [PlayDefinition] = [
        PlayDefinition(name: "4-Verts", formation: .shotgun, isRunPlay: false,
            category: .longPass,
            routes: [.wr1: go(), .wr2: go(), .wr3: go(120), .te: go(100)],
            runPath: nil, audibleAlt: "HB Draw"),
        PlayDefinition(name: "Mesh", formation: .shotgun, isRunPlay: false,
            category: .shortPass,
            routes: [.wr1: drag(dir: 1), .wr2: drag(dir: -1), .wr3: curl(), .te: flat()],
            runPath: nil, audibleAlt: "Slant-Flat"),
        PlayDefinition(name: "Slant-Flat", formation: .shotgun, isRunPlay: false,
            category: .shortPass,
            routes: [.wr1: slant(dir: 1), .wr2: flat(dir: -1), .wr3: curl(30), .te: out(dir: 1)],
            runPath: nil),
        PlayDefinition(name: "PA Boot", formation: .shotgun, isRunPlay: false,
            category: .longPass,
            routes: [.wr1: corner(dir: 1), .wr2: go(), .wr3: flat(dir: 1), .te: drag(dir: 1)],
            runPath: nil),
        PlayDefinition(name: "HB Draw", formation: .shotgun, isRunPlay: true,
            category: .run,
            routes: [.wr1: go(), .wr2: go()],
            runPath: [.init(dx: 0, dy: 60, duration: 1.0)]),
    ]

    // MARK: - I-Form (5 plays)

    static let iForm: [PlayDefinition] = [
        PlayDefinition(name: "Power O", formation: .iForm, isRunPlay: true,
            category: .run,
            routes: [.wr1: go(), .wr2: block],
            runPath: [.init(dx: 20, dy: 50, duration: 0.8)], audibleAlt: "PA Counter"),
        PlayDefinition(name: "HB Dive", formation: .iForm, isRunPlay: true,
            category: .run,
            routes: [.wr1: block, .wr2: block],
            runPath: [.init(dx: 0, dy: 40, duration: 0.7)]),
        PlayDefinition(name: "PA Counter", formation: .iForm, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: post(dir: 1), .wr2: curl(), .te: drag(dir: 1)],
            runPath: nil),
        PlayDefinition(name: "Flood", formation: .iForm, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: corner(dir: -1), .wr2: out(dir: -1), .te: flat(dir: -1)],
            runPath: nil),
        PlayDefinition(name: "PA Deep", formation: .iForm, isRunPlay: false,
            category: .longPass,
            routes: [.wr1: go(), .wr2: post(dir: -1), .te: curl()],
            runPath: nil, audibleAlt: "HB Dive"),
    ]

    // MARK: - Spread (5 plays)

    static let spread: [PlayDefinition] = [
        PlayDefinition(name: "Shallow Cross", formation: .spread, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: drag(dir: 1), .wr2: drag(dir: -1), .wr3: go(), .te: curl()],
            runPath: nil),
        PlayDefinition(name: "Y Shallow", formation: .spread, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: go(), .wr2: curl(40), .wr3: slant(dir: 1), .te: drag(dir: 1)],
            runPath: nil, audibleAlt: "RPO Slant"),
        PlayDefinition(name: "RPO Slant", formation: .spread, isRunPlay: false,
            category: .shortPass,
            routes: [.wr1: slant(dir: 1), .wr2: slant(dir: -1), .wr3: flat(dir: -1), .te: block],
            runPath: [.init(dx: -10, dy: 40, duration: 0.7)]),
        PlayDefinition(name: "Bubble Screen", formation: .spread, isRunPlay: false,
            category: .shortPass,
            routes: [.wr1: flat(dir: -1), .wr2: block, .wr3: go(), .te: block],
            runPath: nil),
        PlayDefinition(name: "Levels", formation: .spread, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: curl(30), .wr2: curl(55), .wr3: go(100), .te: flat(dir: 1)],
            runPath: nil),
    ]

    // MARK: - Pistol (5 plays)

    static let pistol: [PlayDefinition] = [
        PlayDefinition(name: "Zone Read", formation: .pistol, isRunPlay: true,
            category: .run,
            routes: [.wr1: go(), .wr2: block],
            runPath: [.init(dx: -15, dy: 45, duration: 0.8)], audibleAlt: "TE Delay"),
        PlayDefinition(name: "TE Delay", formation: .pistol, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: go(), .wr2: out(dir: -1), .wr3: slant(dir: 1), .te: Route(
                name: "Delay", waypoints: [.init(dx: 0, dy: 0, duration: 0.5), .init(dx: 20, dy: 50, duration: 0.8)], sweetSpotIndex: 1)],
            runPath: nil),
        PlayDefinition(name: "Drag Wheel", formation: .pistol, isRunPlay: false,
            category: .longPass,
            routes: [.wr1: drag(dir: 1), .wr2: wheel(dir: -1), .wr3: curl(), .te: flat(dir: 1)],
            runPath: nil),
        PlayDefinition(name: "Double Post", formation: .pistol, isRunPlay: false,
            category: .longPass,
            routes: [.wr1: post(dir: 1), .wr2: post(dir: -1), .wr3: flat(dir: -1), .te: curl()],
            runPath: nil, audibleAlt: "Zone Read"),
        PlayDefinition(name: "HB Toss", formation: .pistol, isRunPlay: true,
            category: .run,
            routes: [.wr1: block, .wr2: block],
            runPath: [.init(dx: -30, dy: 35, duration: 0.7)]),
    ]

    // MARK: - Singleback (5 plays)

    static let singleback: [PlayDefinition] = [
        PlayDefinition(name: "Inside Zone", formation: .singleback, isRunPlay: true,
            category: .run,
            routes: [.wr1: go(), .wr2: block],
            runPath: [.init(dx: 5, dy: 45, duration: 0.8)], audibleAlt: "Curl-Flat"),
        PlayDefinition(name: "Curl-Flat", formation: .singleback, isRunPlay: false,
            category: .shortPass,
            routes: [.wr1: curl(), .wr2: flat(dir: -1), .wr3: go(), .te: out(dir: 1)],
            runPath: nil),
        PlayDefinition(name: "Spacing", formation: .singleback, isRunPlay: false,
            category: .shortPass,
            routes: [.wr1: curl(30), .wr2: flat(dir: -1), .wr3: out(dir: 1, depth: 50), .te: drag(dir: 1)],
            runPath: nil),
        PlayDefinition(name: "TE Cross", formation: .singleback, isRunPlay: false,
            category: .mediumPass,
            routes: [.wr1: go(), .wr2: curl(), .te: drag(dir: -1)],
            runPath: nil, audibleAlt: "Inside Zone"),
        PlayDefinition(name: "Counter", formation: .singleback, isRunPlay: true,
            category: .run,
            routes: [.wr1: block, .wr2: go()],
            runPath: [.init(dx: -20, dy: 50, duration: 0.9)]),
    ]
}
