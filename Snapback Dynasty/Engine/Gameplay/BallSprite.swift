import SpriteKit

/// Small football sprite — brown oval with a separate ground shadow that
/// tracks the ball's X/Y projection so the arc reads visually as a lob.
class BallSprite: SKNode {

    private let ball: SKShapeNode
    private let shadow: SKShapeNode

    override init() {
        ball = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        ball.fillColor = SKColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        ball.strokeColor = .white
        ball.lineWidth = 0.5
        ball.zPosition = 10

        shadow = SKShapeNode(circleOfRadius: 4)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.5)
        shadow.strokeColor = .clear
        shadow.zPosition = -1
        shadow.isHidden = true

        super.init()
        name = "ball"
        addChild(shadow)
        addChild(ball)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Animate ball flight from current position to target over duration.
    /// The ball arcs upward (parabolic); the shadow tracks the ground-plane
    /// projection with shrinking scale + fading alpha at the peak to sell height.
    func fly(to target: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        let start = position
        let distance = hypot(target.x - start.x, target.y - start.y)
        // Arc height scales with sqrt of distance — short throws arc subtly,
        // deep throws lob visibly.
        let arcHeight = max(18, sqrt(distance) * 2.5)

        // Keep the node itself on the ground (= linear interp of start→target)
        // so the shadow child stays accurate. The visible ball child is what
        // rises and falls relative to the node.
        shadow.isHidden = false
        ball.position = .zero

        let spin = SKAction.rotate(byAngle: .pi * 2.0, duration: duration)
        ball.run(spin)

        let flight = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let t = min(1, max(0, elapsed / CGFloat(duration)))
            // Linear ground interpolation for the node position.
            self.position = CGPoint(
                x: start.x + (target.x - start.x) * t,
                y: start.y + (target.y - start.y) * t
            )
            // Parabolic hop for the visible ball child: 4*t*(1-t) peaks at t=0.5.
            let hop = 4 * t * (1 - t)
            self.ball.position = CGPoint(x: 0, y: hop * arcHeight)

            // Shadow shrinks + fades at apex, returns at landing.
            let shadowScale = 1 - hop * 0.35
            self.shadow.setScale(shadowScale)
            self.shadow.alpha = 0.6 - hop * 0.3
        }

        run(flight) { [weak self] in
            self?.ball.position = .zero
            self?.shadow.setScale(1)
            self?.shadow.alpha = 0.6
            self?.shadow.isHidden = true
            completion()
        }
    }
}
