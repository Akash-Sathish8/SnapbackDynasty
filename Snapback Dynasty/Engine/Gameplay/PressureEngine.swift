import SpriteKit

/// Moves DL sprites toward the QB and checks for sack contact.
class PressureEngine {

    /// Time elapsed since snap. Used for pressure timing.
    var elapsed: TimeInterval = 0

    /// DL rush speed, computed from attributes + defensive play multiplier.
    var rushSpeed: CGFloat = 1.0

    /// Points per second the DL moves toward QB.
    /// Tuned so a neutral-stat play gives ~4-5s in the pocket.
    private let baseSpeed: CGFloat = 14

    /// How far the DL must be from QB to trigger a sack.
    let sackThreshold: CGFloat = 8

    /// OL holds before DL starts pushing through. Extended to feel like
    /// a real pocket rather than instant pressure.
    private let olHoldSeconds: TimeInterval = 1.5

    /// Previous QB position — used to estimate QB drag velocity so DL can
    /// pursue at a matching pace instead of being outrun by fast swipes.
    private var lastQBPos: CGPoint?

    /// Stat-driven multiplier applied to QB speed when DL is chasing.
    /// DL of equal DL-speed to QB-speed keeps pace; higher DL speed closes.
    private var pursuitFactor: CGFloat = 1.0

    /// Configure from player stats + defense.
    func configure(dlSpeed: Int, olStrength: Int, defense: DefensivePlay?) {
        let dlFactor = CGFloat(dlSpeed) / 70.0
        let olFactor = CGFloat(olStrength) / 70.0
        let defMult = CGFloat(defense?.pressureMultiplier ?? 1.0)
        rushSpeed = baseSpeed * (dlFactor / olFactor) * defMult
        // Pursuit factor: scales how much of the QB's drag velocity DL matches.
        pursuitFactor = min(1.15, max(0.85, (dlFactor / olFactor) * defMult))
    }

    /// Call each frame update. Returns true if sack occurs.
    func update(dt: TimeInterval, dlNodes: [SKNode], qbNode: SKNode) -> Bool {
        elapsed += dt

        // Always track QB velocity — even during OL hold window — so the
        // first post-hold frame has a usable sample.
        let qbVelocity: CGFloat = {
            guard let last = lastQBPos, dt > 0 else { return 0 }
            let dx = qbNode.position.x - last.x
            let dy = qbNode.position.y - last.y
            return sqrt(dx * dx + dy * dy) / CGFloat(dt)
        }()
        lastQBPos = qbNode.position

        // OL holds for pocket time before DL starts moving
        guard elapsed > olHoldSeconds else { return false }

        // When the QB is scrambling fast, DL pursue at a matching rate
        // (scaled by stats) rather than a flat base speed. This prevents
        // the QB from simply outrunning pressure by dragging quickly.
        let matchedSpeed = max(rushSpeed, qbVelocity * pursuitFactor)

        for dl in dlNodes {
            let direction = CGPoint(
                x: qbNode.position.x - dl.position.x,
                y: qbNode.position.y - dl.position.y
            )
            let length = sqrt(direction.x * direction.x + direction.y * direction.y)
            guard length > sackThreshold else { return true }

            let normalized = CGPoint(x: direction.x / length, y: direction.y / length)
            let speed = matchedSpeed * CGFloat(dt)
            dl.position.x += normalized.x * speed
            dl.position.y += normalized.y * speed
        }
        return false
    }

    func reset() {
        elapsed = 0
        lastQBPos = nil
    }
}
