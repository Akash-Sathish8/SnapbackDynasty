import SpriteKit

/// Retro Bowl–style field.
/// Vertical orientation, bright kelly-green grass, bold yard lines,
/// team-colored end zones with names, team logo at midfield (async loaded).
enum FieldRenderer {

    // MARK: - Constants

    static let endZoneDepth: CGFloat = 70
    static let yardsOnField: Int = 100
    static let yardSpacing: CGFloat = 13     // pts per yard
    static let fieldHeight: CGFloat = CGFloat(yardsOnField) * yardSpacing + endZoneDepth * 2
    static let fieldWidth: CGFloat = 360

    /// Kelly-green Retro Bowl grass color.
    static let grassColor = SKColor(red: 0.27, green: 0.64, blue: 0.24, alpha: 1.0)
    static let grassStripeColor = SKColor(red: 0.32, green: 0.70, blue: 0.28, alpha: 1.0)

    // MARK: - Build

    static func build(sceneSize: CGSize, homeColor: String, awayColor: String,
                      homeName: String, awayName: String,
                      homeLogoURL: String? = nil) -> SKNode {
        let root = SKNode()
        root.name = "field"
        let xOffset = (sceneSize.width - fieldWidth) / 2

        // Grass base with alternating "mowed" stripes for texture.
        for yard in 0..<yardsOnField {
            let y = endZoneDepth + CGFloat(yard) * yardSpacing
            let stripeColor = yard % 10 < 5 ? grassColor : grassStripeColor
            let stripe = SKShapeNode(rect: CGRect(x: xOffset, y: y,
                                                   width: fieldWidth, height: yardSpacing))
            stripe.fillColor = stripeColor
            stripe.strokeColor = .clear
            root.addChild(stripe)
        }

        // White sidelines
        let sidelineLeft = SKShapeNode(rect: CGRect(x: xOffset - 2, y: endZoneDepth,
                                                     width: 3,
                                                     height: CGFloat(yardsOnField) * yardSpacing))
        sidelineLeft.fillColor = .white
        sidelineLeft.strokeColor = .clear
        root.addChild(sidelineLeft)
        let sidelineRight = SKShapeNode(rect: CGRect(x: xOffset + fieldWidth - 1,
                                                      y: endZoneDepth, width: 3,
                                                      height: CGFloat(yardsOnField) * yardSpacing))
        sidelineRight.fillColor = .white
        sidelineRight.strokeColor = .clear
        root.addChild(sidelineRight)

        // Yard lines every 5 (thin) and every 10 (thick with numbers)
        for yard in stride(from: 5, through: 95, by: 5) {
            let y = endZoneDepth + CGFloat(yard) * yardSpacing
            let isTen = yard % 10 == 0
            let line = SKShapeNode(rect: CGRect(x: xOffset,
                                                 y: y - (isTen ? 1.5 : 0.75),
                                                 width: fieldWidth,
                                                 height: isTen ? 3 : 1.5))
            line.fillColor = .white
            line.strokeColor = .clear
            root.addChild(line)

            if isTen {
                let displayYard = yard <= 50 ? yard : 100 - yard
                addYardNumber(to: root, yard: displayYard,
                              x: xOffset + 22, y: y + 4, rotate: false)
                addYardNumber(to: root, yard: displayYard,
                              x: xOffset + fieldWidth - 22, y: y + 4, rotate: false)
            }
        }

        // Hash marks every yard
        for yard in 1..<100 where yard % 10 != 0 && yard % 5 != 0 {
            let y = endZoneDepth + CGFloat(yard) * yardSpacing
            for hashX in [xOffset + fieldWidth * 0.33, xOffset + fieldWidth * 0.67] {
                let hash = SKShapeNode(rect: CGRect(x: hashX - 1, y: y - 0.5,
                                                     width: 4, height: 1))
                hash.fillColor = .white
                hash.strokeColor = .clear
                root.addChild(hash)
            }
        }

        // End zones (team-colored)
        let awayEZ = SKShapeNode(rect: CGRect(x: xOffset, y: 0,
                                               width: fieldWidth, height: endZoneDepth))
        awayEZ.fillColor = skColor(hex: awayColor)
        awayEZ.strokeColor = .white
        awayEZ.lineWidth = 2
        root.addChild(awayEZ)

        let awayLabel = SKLabelNode(text: awayName.uppercased())
        awayLabel.fontName = "Helvetica-Bold"
        awayLabel.fontSize = 26
        awayLabel.fontColor = textColor(for: awayColor)
        awayLabel.position = CGPoint(x: sceneSize.width / 2, y: endZoneDepth / 2 - 9)
        awayLabel.zPosition = 1
        root.addChild(awayLabel)

        let homeY = endZoneDepth + CGFloat(yardsOnField) * yardSpacing
        let homeEZ = SKShapeNode(rect: CGRect(x: xOffset, y: homeY,
                                               width: fieldWidth, height: endZoneDepth))
        homeEZ.fillColor = skColor(hex: homeColor)
        homeEZ.strokeColor = .white
        homeEZ.lineWidth = 2
        root.addChild(homeEZ)

        let homeLabel = SKLabelNode(text: homeName.uppercased())
        homeLabel.fontName = "Helvetica-Bold"
        homeLabel.fontSize = 26
        homeLabel.fontColor = textColor(for: homeColor)
        homeLabel.position = CGPoint(x: sceneSize.width / 2, y: homeY + endZoneDepth / 2 - 9)
        homeLabel.zPosition = 1
        root.addChild(homeLabel)

        // Midfield logo — circle with team color background + abbreviation.
        // If a URL is provided, swap in the image asynchronously.
        let midY = endZoneDepth + 50 * yardSpacing
        let circle = SKShapeNode(circleOfRadius: 36)
        circle.fillColor = skColor(hex: homeColor).withAlphaComponent(0.35)
        circle.strokeColor = .white
        circle.lineWidth = 2
        circle.position = CGPoint(x: sceneSize.width / 2, y: midY)
        circle.name = "midfield_logo"
        root.addChild(circle)

        let logoInitials = SKLabelNode(text: homeName.uppercased())
        logoInitials.fontName = "Helvetica-Bold"
        logoInitials.fontSize = 20
        logoInitials.fontColor = .white
        logoInitials.position = CGPoint(x: sceneSize.width / 2, y: midY - 6)
        logoInitials.zPosition = 2
        logoInitials.name = "midfield_text"
        root.addChild(logoInitials)

        // Load logo image async if URL provided
        if let urlString = homeLogoURL, let url = URL(string: urlString) {
            Task {
                if let image = await LogoCache.shared.load(url: url),
                   let cgImage = image.cgImage {
                    await MainActor.run {
                        let texture = SKTexture(cgImage: cgImage)
                        let sprite = SKSpriteNode(texture: texture)
                        sprite.size = CGSize(width: 60, height: 60)
                        sprite.position = CGPoint(x: sceneSize.width / 2, y: midY)
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
                                       x: CGFloat, y: CGFloat, rotate: Bool) {
        let label = SKLabelNode(text: "\(yard)")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 22
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.zPosition = 1
        if rotate { label.zRotation = .pi / 2 }
        root.addChild(label)
    }

    // MARK: - Coordinate helpers

    static func yPosition(forYard yard: Int, fieldHeight: CGFloat, sceneSize: CGSize) -> CGFloat {
        endZoneDepth + CGFloat(yard) * yardSpacing
    }

    static func centerX(sceneSize: CGSize) -> CGFloat {
        sceneSize.width / 2
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
