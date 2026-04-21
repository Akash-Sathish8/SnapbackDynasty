import SpriteKit

/// Retro Bowl–style field, horizontal orientation:
///   - Length runs along screen X (offense drives left → right).
///   - Width runs along screen Y.
/// Bright kelly-green grass, bold yard lines, team-colored end zones with
/// names, team logo at midfield (async loaded).
enum FieldRenderer {

    // MARK: - Constants

    static let endZoneDepth: CGFloat = 70
    static let yardsOnField: Int = 100
    static let yardSpacing: CGFloat = 13     // pts per yard (along X)
    /// Full length along screen X, including both endzones.
    static let fieldLength: CGFloat = CGFloat(yardsOnField) * yardSpacing + endZoneDepth * 2
    /// Field height along screen Y (sideline-to-sideline thickness). Sized to
    /// exactly fill the scene's 400pt vertical extent — no top/bottom margin.
    static let fieldWidth: CGFloat = 400

    /// Kelly-green Retro Bowl grass color.
    static let grassColor = SKColor(red: 0.27, green: 0.64, blue: 0.24, alpha: 1.0)
    static let grassStripeColor = SKColor(red: 0.32, green: 0.70, blue: 0.28, alpha: 1.0)

    // MARK: - Build

    static func build(sceneSize: CGSize, homeColor: String, awayColor: String,
                      homeName: String, awayName: String,
                      homeLogoURL: String? = nil) -> SKNode {
        let root = SKNode()
        root.name = "field"
        // Center the field vertically in the scene.
        let yOffset = (sceneSize.height - fieldWidth) / 2

        // Grass base — alternating "mowed" stripes, each one yard wide,
        // running vertically across the field.
        for yard in 0..<yardsOnField {
            let x = endZoneDepth + CGFloat(yard) * yardSpacing
            let stripeColor = yard % 10 < 5 ? grassColor : grassStripeColor
            let stripe = SKShapeNode(rect: CGRect(x: x, y: yOffset,
                                                   width: yardSpacing, height: fieldWidth))
            stripe.fillColor = stripeColor
            stripe.strokeColor = .clear
            root.addChild(stripe)
        }

        // Sidelines — horizontal lines along top and bottom of field.
        let playFieldLength = CGFloat(yardsOnField) * yardSpacing
        let sidelineBottom = SKShapeNode(rect: CGRect(
            x: endZoneDepth, y: yOffset - 2,
            width: playFieldLength, height: 3))
        sidelineBottom.fillColor = .white
        sidelineBottom.strokeColor = .clear
        root.addChild(sidelineBottom)

        let sidelineTop = SKShapeNode(rect: CGRect(
            x: endZoneDepth, y: yOffset + fieldWidth - 1,
            width: playFieldLength, height: 3))
        sidelineTop.fillColor = .white
        sidelineTop.strokeColor = .clear
        root.addChild(sidelineTop)

        // Yard lines every 5 (thin) and every 10 (thick with numbers).
        for yard in stride(from: 5, through: 95, by: 5) {
            let x = endZoneDepth + CGFloat(yard) * yardSpacing
            let isTen = yard % 10 == 0
            let line = SKShapeNode(rect: CGRect(
                x: x - (isTen ? 1.5 : 0.75), y: yOffset,
                width: isTen ? 3 : 1.5, height: fieldWidth))
            line.fillColor = .white
            line.strokeColor = .clear
            root.addChild(line)

            if isTen {
                let displayYard = yard <= 50 ? yard : 100 - yard
                // Top sideline
                addYardNumber(to: root, yard: displayYard,
                              x: x, y: yOffset + fieldWidth - 18)
                // Bottom sideline
                addYardNumber(to: root, yard: displayYard,
                              x: x, y: yOffset + 18)
            }
        }

        // Hash marks: short horizontal ticks along both inside hash rows.
        for yard in 1..<100 where yard % 10 != 0 && yard % 5 != 0 {
            let x = endZoneDepth + CGFloat(yard) * yardSpacing
            for hashY in [yOffset + fieldWidth * 0.33, yOffset + fieldWidth * 0.67] {
                let hash = SKShapeNode(rect: CGRect(
                    x: x - 0.5, y: hashY - 2,
                    width: 1, height: 4))
                hash.fillColor = .white
                hash.strokeColor = .clear
                root.addChild(hash)
            }
        }

        // End zones — away on the left, home on the right.
        let awayEZ = SKShapeNode(rect: CGRect(
            x: 0, y: yOffset,
            width: endZoneDepth, height: fieldWidth))
        awayEZ.fillColor = skColor(hex: awayColor)
        awayEZ.strokeColor = .white
        awayEZ.lineWidth = 2
        root.addChild(awayEZ)

        let awayLabel = SKLabelNode(text: awayName.uppercased())
        awayLabel.fontName = "Helvetica-Bold"
        awayLabel.fontSize = 22
        awayLabel.fontColor = textColor(for: awayColor)
        awayLabel.position = CGPoint(x: endZoneDepth / 2, y: yOffset + fieldWidth / 2)
        awayLabel.verticalAlignmentMode = .center
        awayLabel.horizontalAlignmentMode = .center
        // Rotate so the team name reads along the endzone's long axis.
        awayLabel.zRotation = .pi / 2
        awayLabel.zPosition = 1
        root.addChild(awayLabel)

        let homeX = endZoneDepth + playFieldLength
        let homeEZ = SKShapeNode(rect: CGRect(
            x: homeX, y: yOffset,
            width: endZoneDepth, height: fieldWidth))
        homeEZ.fillColor = skColor(hex: homeColor)
        homeEZ.strokeColor = .white
        homeEZ.lineWidth = 2
        root.addChild(homeEZ)

        let homeLabel = SKLabelNode(text: homeName.uppercased())
        homeLabel.fontName = "Helvetica-Bold"
        homeLabel.fontSize = 22
        homeLabel.fontColor = textColor(for: homeColor)
        homeLabel.position = CGPoint(x: homeX + endZoneDepth / 2, y: yOffset + fieldWidth / 2)
        homeLabel.verticalAlignmentMode = .center
        homeLabel.horizontalAlignmentMode = .center
        homeLabel.zRotation = -.pi / 2
        homeLabel.zPosition = 1
        root.addChild(homeLabel)

        // Midfield logo.
        let midX = endZoneDepth + 50 * yardSpacing
        let midY = yOffset + fieldWidth / 2
        let circle = SKShapeNode(circleOfRadius: 36)
        circle.fillColor = skColor(hex: homeColor).withAlphaComponent(0.35)
        circle.strokeColor = .white
        circle.lineWidth = 2
        circle.position = CGPoint(x: midX, y: midY)
        circle.name = "midfield_logo"
        root.addChild(circle)

        let logoInitials = SKLabelNode(text: homeName.uppercased())
        logoInitials.fontName = "Helvetica-Bold"
        logoInitials.fontSize = 20
        logoInitials.fontColor = .white
        logoInitials.position = CGPoint(x: midX, y: midY - 6)
        logoInitials.zPosition = 2
        logoInitials.name = "midfield_text"
        root.addChild(logoInitials)

        // Async-load the real logo if a URL was provided.
        if let urlString = homeLogoURL, let url = URL(string: urlString) {
            Task {
                if let image = await LogoCache.shared.load(url: url),
                   let cgImage = image.cgImage {
                    await MainActor.run {
                        let texture = SKTexture(cgImage: cgImage)
                        let sprite = SKSpriteNode(texture: texture)
                        sprite.size = CGSize(width: 60, height: 60)
                        sprite.position = CGPoint(x: midX, y: midY)
                        sprite.zPosition = 2
                        sprite.alpha = 0.95
                        root.addChild(sprite)
                        logoInitials.removeFromParent()
                    }
                }
            }
        }

        return root
    }

    private static func addYardNumber(to root: SKNode, yard: Int,
                                       x: CGFloat, y: CGFloat) {
        let label = SKLabelNode(text: "\(yard)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 16
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        root.addChild(label)
    }

    // MARK: - Coordinate helpers

    /// Screen X coordinate of the given yard line (0 = away endzone far edge,
    /// 100 = home endzone far edge; 25 = own 25, 75 = opponent's 25).
    static func xPosition(forYard yard: Int, sceneSize: CGSize) -> CGFloat {
        endZoneDepth + CGFloat(yard) * yardSpacing
    }

    /// Screen Y of the sideline-to-sideline center line.
    static func centerY(sceneSize: CGSize) -> CGFloat {
        sceneSize.height / 2
    }

    // MARK: - Color helpers

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
