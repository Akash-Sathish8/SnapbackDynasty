import SpriteKit

/// Retro Bowl–style player sprite: chunky pixel-art look.
///
/// Composed of flat rectangles:
///   - Helmet (team primary color, with face mask line)
///   - Jersey body (jersey color — typically white for away, team color for home)
///   - Pants (darker team color)
///   - Small legs
///   - Jersey number on chest
///
/// ~18pt tall total. Deliberately no anti-aliasing — crisp pixel look.
class PlayerSprite: SKNode {

    let jerseyNumber: Int
    let teamPrimary: String
    let jerseyColor: String
    let pantsColor: String
    let isOffense: Bool
    let isQB: Bool

    // Sprite parts (cached for recolor / highlight)
    private let helmet: SKShapeNode
    private let mask: SKShapeNode
    private let jersey: SKShapeNode
    private let pants: SKShapeNode
    private let legL: SKShapeNode
    private let legR: SKShapeNode
    private let numberLabel: SKLabelNode
    private var highlightRing: SKShapeNode?

    var isTapTarget: Bool = false
    var isSweetSpotActive: Bool = false {
        didSet { updateSweetSpot() }
    }

    /// Set by the pressure engine once the pocket starts collapsing. Tints
    /// the helmet red so the player has a readable "rush is here" cue.
    var isRushing: Bool = false {
        didSet { updateRushing() }
    }

    /// Temporary stun after a broken tackle — sprite flickers and the
    /// breakaway logic skips pursuit until the stun window expires.
    var isStunned: Bool = false {
        didSet { updateStunned() }
    }

    /// Scene timestamp at which an active stun expires. Written by
    /// GameplayScene, read by PressureEngine / run-defense loops.
    var stunnedUntil: TimeInterval = 0

    // MARK: - Dimensions (retro-bowl proportions)
    static let bodyWidth: CGFloat = 11
    static let helmetHeight: CGFloat = 7
    static let jerseyHeight: CGFloat = 8
    static let pantsHeight: CGFloat = 4
    static let legHeight: CGFloat = 3
    static var totalHeight: CGFloat { helmetHeight + jerseyHeight + pantsHeight + legHeight }

    init(number: Int, primary: String, jerseyColor: String, pantsColor: String,
         isOffense: Bool, isQB: Bool = false) {
        self.jerseyNumber = number
        self.teamPrimary = primary
        self.jerseyColor = jerseyColor
        self.pantsColor = pantsColor
        self.isOffense = isOffense
        self.isQB = isQB

        let primary = PlayerSprite.skColor(hex: primary)
        let jersey = PlayerSprite.skColor(hex: jerseyColor)
        let pants = PlayerSprite.skColor(hex: pantsColor)
        let faceMask = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)

        // Build the figure from bottom up.
        // Legs
        let legY: CGFloat = isOffense ? 0 : -Self.totalHeight
        legL = Self.rect(x: -3, y: legY, w: 2, h: Self.legHeight, fill: pants)
        legR = Self.rect(x: 1,  y: legY, w: 2, h: Self.legHeight, fill: pants)

        // Pants (right above legs)
        let pantsY = legY + Self.legHeight
        self.pants = Self.rect(x: -Self.bodyWidth/2, y: pantsY,
                                w: Self.bodyWidth, h: Self.pantsHeight, fill: pants)

        // Jersey (above pants)
        let jerseyY = pantsY + Self.pantsHeight
        self.jersey = Self.rect(x: -Self.bodyWidth/2, y: jerseyY,
                                 w: Self.bodyWidth, h: Self.jerseyHeight, fill: jersey)

        // Helmet (above jersey)
        let helmetY = jerseyY + Self.jerseyHeight
        helmet = Self.rect(x: -Self.bodyWidth/2, y: helmetY,
                           w: Self.bodyWidth, h: Self.helmetHeight, fill: primary,
                           cornerRadius: 2)

        // Face mask — small white line on the "front" of the helmet (offense facing up)
        let maskY = isOffense ? helmetY + 1 : helmetY + Self.helmetHeight - 2
        mask = Self.rect(x: -Self.bodyWidth/2 + 1, y: maskY,
                         w: Self.bodyWidth - 2, h: 1, fill: faceMask)

        // Jersey number
        numberLabel = SKLabelNode(text: "\(number % 100)")
        numberLabel.fontName = "Helvetica-Bold"
        numberLabel.fontSize = 6
        numberLabel.fontColor = PlayerSprite.textColor(for: jerseyColor)
        numberLabel.verticalAlignmentMode = .center
        numberLabel.horizontalAlignmentMode = .center
        numberLabel.position = CGPoint(x: 0, y: jerseyY + Self.jerseyHeight / 2)

        super.init()
        name = "player_\(number)"
        isUserInteractionEnabled = false

        addChild(legL); addChild(legR)
        addChild(self.pants)
        addChild(self.jersey)
        addChild(helmet)
        addChild(mask)
        addChild(numberLabel)

        if isQB { addQBHighlight() }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Helpers

    private static func rect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                              fill: SKColor, cornerRadius: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(rect: CGRect(x: x, y: y, width: w, height: h),
                                cornerRadius: cornerRadius)
        node.fillColor = fill
        node.strokeColor = .clear
        node.lineWidth = 0
        return node
    }

    private func addQBHighlight() {
        let ring = SKShapeNode(circleOfRadius: Self.bodyWidth / 2 + 3)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 1, green: 0.84, blue: 0, alpha: 0.75)
        ring.lineWidth = 1.5
        ring.position = CGPoint(x: 0, y: isOffense ? Self.totalHeight / 2 : -Self.totalHeight / 2)
        ring.name = "qb_ring"
        addChild(ring)
        highlightRing = ring
    }

    private func updateRushing() {
        if isRushing {
            // Red overlay on the jersey to signal the pocket is collapsing.
            jersey.fillColor = SKColor(red: 0.90, green: 0.15, blue: 0.15, alpha: 1)
        } else {
            jersey.fillColor = PlayerSprite.skColor(hex: jerseyColor)
        }
    }

    private func updateStunned() {
        removeAction(forKey: "stun_flicker")
        if isStunned {
            let flicker = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            ]))
            run(flicker, withKey: "stun_flicker")
        } else {
            alpha = 1
        }
    }

    private func updateSweetSpot() {
        childNode(withName: "sweet_ring")?.removeFromParent()
        guard isSweetSpotActive else { return }
        let ring = SKShapeNode(circleOfRadius: Self.bodyWidth / 2 + 5)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 0.9)
        ring.lineWidth = 2.5
        ring.name = "sweet_ring"
        ring.position = CGPoint(x: 0, y: isOffense ? Self.totalHeight / 2 : -Self.totalHeight / 2)
        ring.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.18),
                SKAction.fadeAlpha(to: 1.0, duration: 0.18),
            ])
        ))
        addChild(ring)
    }

    // MARK: - Color utilities

    private static func skColor(hex: String) -> SKColor {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        return SKColor(
            red: CGFloat((int >> 16) & 0xFF) / 255,
            green: CGFloat((int >> 8) & 0xFF) / 255,
            blue: CGFloat(int & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func textColor(for hex: String) -> SKColor {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF)
        let g = Double((int >> 8) & 0xFF)
        let b = Double(int & 0xFF)
        let lum = (r * 299 + g * 587 + b * 114) / 1000
        return lum > 155 ? SKColor(white: 0.1, alpha: 1) : .white
    }
}
