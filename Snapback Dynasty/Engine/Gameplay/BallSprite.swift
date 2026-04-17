import SpriteKit

/// Small football sprite — brown oval.
class BallSprite: SKNode {

    private let ball: SKShapeNode

    override init() {
        ball = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        ball.fillColor = SKColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        ball.strokeColor = .white
        ball.lineWidth = 0.5
        ball.zPosition = 10
        super.init()
        name = "ball"
        addChild(ball)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Animate ball flight from current position to target over duration.
    func fly(to target: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        let path = CGMutablePath()
        path.move(to: position)
        let midY = (position.y + target.y) / 2 + 20 // arc up
        path.addQuadCurve(to: target, control: CGPoint(x: (position.x + target.x) / 2, y: midY))
        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeInEaseOut
        run(follow) { completion() }
    }
}
