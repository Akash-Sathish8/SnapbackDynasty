import SpriteKit

class GameplayScene: SKScene {

    // MARK: - Config (set before didMove)
    var homeTeamName: String = "HOME"
    var awayTeamName: String = "AWAY"
    var homeColor: String = "#9E1B32"
    var awayColor: String = "#002b5c"
    var homeLogo: String = ""
    var gameState: GameState!

    // Real roster data for stat-driven outcomes
    var homeRoster: GameplayRoster?
    var awayRoster: GameplayRoster?

    // MARK: - Nodes
    private var cameraNode: SKCameraNode!
    private var offensePlayers: [Formation.SlotRole: PlayerSprite] = [:]
    private var defensePlayers: [PlayerSprite] = []
    private var qbSprite: PlayerSprite?
    private var ballSprite: BallSprite!
    private var dlNodes: [SKNode] { defensePlayers.prefix(4).map { $0 as SKNode } }

    // MARK: - Engines
    private let pressure = PressureEngine()

    // MARK: - Play state
    private var routeStartTime: TimeInterval = 0
    private var sweetSpotFired: [Formation.SlotRole: Bool] = [:]
    private var isDraggingQB = false
    private var isDraggingRB = false
    private var rbSprite: PlayerSprite?
    private var playActive = false
    private var snapTime: TimeInterval = 0

    /// Pass-coverage assignments: defender index → receiver role they cover.
    /// LBs/CBs man up, safeties play deep help.
    private var coverageAssignments: [Int: Formation.SlotRole] = [:]

    /// Last few RB (position, timestamp) samples. Used to compute drag
    /// velocity for swipe-break-tackle detection.
    private var rbRecentSamples: [(pos: CGPoint, t: TimeInterval)] = []

    // MARK: - Aim-and-release passing state (Retro Bowl-style)
    /// True while the user is actively dragging from the QB to aim a throw.
    private var isAimingThrow = false
    /// True while the football is mid-flight after release; camera follows the
    /// ball instead of the QB during this window so the user sees the catch.
    private var isBallInFlight = false
    /// Overlay nodes drawn under the camera so they sit above the field but
    /// move with the zoom. Created on aim-start, removed on release.
    private var aimArcLine: SKShapeNode?
    private var aimTargetRing: SKShapeNode?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.42, blue: 0.15, alpha: 1)
        setupCamera()
        buildField()
        ballSprite = BallSprite()
        addChild(ballSprite)
        ballSprite.isHidden = true
    }

    private func setupCamera() {
        cameraNode = SKCameraNode()
        // Zoom out so receivers running 15-25 yards downfield stay visible.
        // Default viewport shows ~30 yards; 1.6× shows ~48 yards.
        cameraNode.xScale = 1.6
        cameraNode.yScale = 1.6
        addChild(cameraNode)
        camera = cameraNode
    }

    private func buildField() {
        let field = FieldRenderer.build(
            sceneSize: size, homeColor: homeColor, awayColor: awayColor,
            homeName: homeTeamName, awayName: awayTeamName,
            homeLogoURL: homeLogo)
        addChild(field)
    }

    func centerCamera(onYardLine yard: Int) {
        let y = FieldRenderer.yPosition(forYard: yard, fieldHeight: FieldRenderer.fieldHeight, sceneSize: size)
        cameraNode.run(SKAction.move(to: CGPoint(x: size.width / 2, y: y), duration: 0.3))
    }

    // MARK: - Formation setup

    func setupFormation(play: PlayDefinition, offenseColor: String, defenseColor: String) {
        clearPlayers()
        let losY = FieldRenderer.yPosition(
            forYard: gameState.ballYardLine,
            fieldHeight: FieldRenderer.fieldHeight, sceneSize: size)
        let cx = FieldRenderer.centerX(sceneSize: size)

        // Offense jersey = primary color (home), pants = darkened
        let offensePants = darkenHex(homeColor, by: 0.4)
        let defensePants = darkenHex(awayColor, by: 0.4)
        // Away jersey = off-white for contrast
        let awayJersey = "#F5F5F5"

        for slot in play.formation.slots {
            let isQB = slot.role == .qb
            let number = slotJersey(slot.role)
            let sprite = PlayerSprite(
                number: number, primary: offenseColor,
                jerseyColor: offenseColor, pantsColor: offensePants,
                isOffense: true, isQB: isQB
            )
            sprite.position = CGPoint(x: cx + slot.x, y: losY + slot.y)
            sprite.isTapTarget = play.routes[slot.role] != nil && !isQB && slot.role != .rb2
            addChild(sprite)
            offensePlayers[slot.role] = sprite
            if isQB { qbSprite = sprite }
            if slot.role == .rb || slot.role == .rb2 { rbSprite = sprite }
        }

        // Defense — 4-3 positions, wearing away jersey
        let defPositions: [(CGFloat, CGFloat)] = [
            (-36, 14), (-12, 14), (12, 14), (36, 14),
            (-40, 38), (0, 38), (40, 38),
            (-90, 60), (90, 60),
            (-30, 82), (30, 82),
        ]
        for (i, pos) in defPositions.enumerated() {
            let sprite = PlayerSprite(
                number: 50 + i, primary: defenseColor,
                jerseyColor: awayJersey, pantsColor: defensePants,
                isOffense: false
            )
            sprite.position = CGPoint(x: cx + pos.0, y: losY + pos.1)
            addChild(sprite)
            defensePlayers.append(sprite)
        }

        ballSprite.position = qbSprite?.position ?? CGPoint(x: cx, y: losY)
        ballSprite.isHidden = false
        centerCamera(onYardLine: gameState.ballYardLine)

        // Assign man coverage: CBs on outside WRs, LBs on slot/TE/RB,
        // safeties provide deep help over the top.
        coverageAssignments = assignCoverage(play: play)
    }

    /// Match defenders to receivers based on who's actually in the formation.
    /// Roles missing from the play are skipped so a defender doesn't chase a ghost.
    private func assignCoverage(play: PlayDefinition) -> [Int: Formation.SlotRole] {
        var map: [Int: Formation.SlotRole] = [:]
        let has: (Formation.SlotRole) -> Bool = { [weak self] role in
            self?.offensePlayers[role] != nil
        }
        // LB left (4) → slot WR, LB mid (5) → RB, LB right (6) → TE
        if has(.wr3) { map[4] = .wr3 }
        if has(.rb)  { map[5] = .rb }
        if has(.te)  { map[6] = .te }
        // CBs lock the outside WRs
        if has(.wr1) { map[7] = .wr1 }
        if has(.wr2) { map[8] = .wr2 }
        // Safeties shade the top receivers (deep help)
        if has(.wr1) { map[9]  = .wr1 }
        if has(.wr2) { map[10] = .wr2 }
        return map
    }

    private func clearPlayers() {
        offensePlayers.values.forEach { $0.removeFromParent() }
        offensePlayers.removeAll()
        defensePlayers.forEach { $0.removeFromParent() }
        defensePlayers.removeAll()
        qbSprite = nil
        rbSprite = nil
        coverageAssignments = [:]
        rbRecentSamples.removeAll()
    }

    private func slotJersey(_ role: Formation.SlotRole) -> Int {
        switch role {
        case .qb: return 1
        case .rb, .rb2: return 22
        case .wr1: return 11
        case .wr2: return 82
        case .wr3: return 7
        case .te: return 88
        default: return 50 + Int.random(in: 0...9)
        }
    }

    // MARK: - Snap

    func snap() {
        guard let play = gameState.currentPlay, let qb = qbSprite else { return }
        playActive = true
        snapTime = 0
        routeStartTime = 0
        sweetSpotFired = [:]
        pressure.reset()
        // Real stats: our OL strength vs their DL speed
        let myOL = homeRoster?.olStrength ?? 70
        let theirDL = awayRoster?.dlSpeed ?? 70
        pressure.configure(dlSpeed: theirDL, olStrength: myOL,
                           defense: gameState.currentDefense)

        // The new aim-and-release mechanic replaces tap-receiver buttons,
        // so receiverOptions stays empty during the play.
        gameState.receiverOptions = []
        gameState.scrambleMode = false

        if play.isRunPlay {
            gameState.phase = .runningPlay
            animateHandoff(play: play)
        } else {
            gameState.phase = .livePlay
            animateRoutes(play: play)
        }

        ballSprite.position = qb.position
    }

    // MARK: - Route animation

    private func animateRoutes(play: PlayDefinition) {
        for (role, route) in play.routes {
            guard let sprite = offensePlayers[role], route.name != "Block" else { continue }
            // moveBy = relative displacement, so multi-waypoint routes chain
            // naturally instead of snapping back to initial slot each leg.
            var actions: [SKAction] = []
            for wp in route.waypoints {
                let action = SKAction.moveBy(x: wp.dx, y: wp.dy, duration: wp.duration)
                action.timingMode = .easeOut
                actions.append(action)
            }
            sprite.run(SKAction.sequence(actions), withKey: "route")
        }
    }

    // MARK: - Run animation

    private func animateHandoff(play: PlayDefinition) {
        guard let rb = rbSprite, let qb = qbSprite else { return }
        // Handoff: RB moves to QB position, then user drags
        let handoff = SKAction.move(to: qb.position, duration: 0.3)
        rb.run(handoff) { [weak self] in
            self?.isDraggingRB = true
            self?.ballSprite.position = rb.position
        }
    }

    // MARK: - Frame update

    override func update(_ currentTime: TimeInterval) {
        guard playActive else { return }
        // First frame after snap: seed the clock, don't advance.
        if snapTime == 0 { snapTime = currentTime; return }
        // dt = time since *last frame*, not since snap.
        let dt = currentTime - snapTime
        snapTime = currentTime

        routeStartTime += dt

        // Update ball position
        if isDraggingRB, let rb = rbSprite {
            ballSprite.position = rb.position
        } else if !isDraggingQB {
            ballSprite.position = qbSprite?.position ?? ballSprite.position
        }

        // Camera follows the most relevant actor:
        //   ball in flight → ball (so user tracks the catch)
        //   running play  → RB
        //   otherwise     → QB
        let followY: CGFloat? = {
            if isBallInFlight { return ballSprite.position.y }
            if isDraggingRB, let rb = rbSprite { return rb.position.y }
            if let qb = qbSprite { return qb.position.y }
            return nil
        }()
        if let targetY = followY {
            let currentY = cameraNode.position.y
            let smoothed = currentY + (targetY - currentY) * 0.18
            cameraNode.position = CGPoint(x: size.width / 2, y: smoothed)
        }

        // Pressure: only on pass plays
        if gameState.phase == .livePlay {
            let sacked = pressure.update(dt: dt, dlNodes: Array(dlNodes), qbNode: qbSprite ?? SKNode())
            if sacked {
                playActive = false
                gameState.receiverOptions = []
                let result = PlayOutcomeResolver.resolveSack()
                if case .sack(let loss) = result {
                    resolvePlayResult(yards: -loss, text: "SACK!", isPositive: false)
                }
            }

            // Red-tint DL once the pocket starts to break so the user sees
            // pressure coming.
            if pressure.pocketIsCollapsing {
                for dl in defensePlayers.prefix(4) {
                    if !dl.isRushing { dl.isRushing = true }
                }
            }

            // Sweet spot timing windows
            checkSweetSpots()

            // Coverage: non-DL defenders shadow their assigned receiver.
            updateCoverage(dt: dt)
        }

        // Run play: track RB drag velocity, check breakaway, then tackle
        if gameState.phase == .runningPlay, isDraggingRB, let rb = rbSprite {
            sampleRBPosition(rb.position, at: currentTime)

            var tackled = false
            for def in defensePlayers {
                if def.isStunned && currentTime < def.stunnedUntil { continue }
                if def.isStunned && currentTime >= def.stunnedUntil {
                    def.isStunned = false
                }
                let dx = def.position.x - rb.position.x
                let dy = def.position.y - rb.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < 12 {
                    if attemptBreakTackle(rb: rb, defender: def, at: currentTime) {
                        // Tackle broken — defender stunned, RB keeps moving.
                        continue
                    }
                    tackled = true
                    isDraggingRB = false
                    playActive = false
                    let losY = FieldRenderer.yPosition(
                        forYard: gameState.ballYardLine,
                        fieldHeight: FieldRenderer.fieldHeight, sceneSize: size)
                    let yardsGained = Int((rb.position.y - losY) / FieldRenderer.yardSpacing)
                    resolvePlayResult(yards: yardsGained,
                                     text: yardsGained >= 0 ? "TACKLE! +\(yardsGained) yds" : "LOSS! \(yardsGained) yds",
                                     isPositive: yardsGained >= 0)
                    break
                }
            }
            if tackled { return }

            // Defenders converge on RB (skip stunned ones)
            for def in defensePlayers {
                if def.isStunned && currentTime < def.stunnedUntil { continue }
                let dir = CGPoint(x: rb.position.x - def.position.x,
                                   y: rb.position.y - def.position.y)
                let len = sqrt(dir.x * dir.x + dir.y * dir.y)
                guard len > 0 else { continue }
                let speed: CGFloat = 18 * CGFloat(dt)
                def.position.x += (dir.x / len) * speed
                def.position.y += (dir.y / len) * speed
            }
        }
    }

    // MARK: - Breakaway moves

    private func sampleRBPosition(_ pos: CGPoint, at time: TimeInterval) {
        rbRecentSamples.append((pos, time))
        if rbRecentSamples.count > 5 {
            rbRecentSamples.removeFirst(rbRecentSamples.count - 5)
        }
    }

    /// Returns the RB's drag velocity (points/second) over the last ~5 frames,
    /// or zero if there's not enough history.
    private func currentRBVelocity() -> CGPoint {
        guard rbRecentSamples.count >= 2,
              let first = rbRecentSamples.first,
              let last = rbRecentSamples.last,
              last.t > first.t else { return .zero }
        let dt = last.t - first.t
        return CGPoint(
            x: (last.pos.x - first.pos.x) / CGFloat(dt),
            y: (last.pos.y - first.pos.y) / CGFloat(dt)
        )
    }

    /// Attempt to shrug off an incoming defender with a stiff-arm (forward
    /// drag) or juke (lateral drag). Success depends on RB speed/strength.
    /// Returns true if the tackle was broken.
    private func attemptBreakTackle(rb: PlayerSprite, defender: PlayerSprite,
                                    at time: TimeInterval) -> Bool {
        let velocity = currentRBVelocity()
        let rbSpeed = hypot(velocity.x, velocity.y)
        guard rbSpeed > 180 else { return false }

        // Direction from RB to defender — we want the user's drag to be
        // *opposite* of the defender to stiff-arm, or perpendicular to juke.
        let toDef = CGPoint(x: defender.position.x - rb.position.x,
                             y: defender.position.y - rb.position.y)
        let toDefLen = max(0.01, hypot(toDef.x, toDef.y))
        let toDefNorm = CGPoint(x: toDef.x / toDefLen, y: toDef.y / toDefLen)
        let velNorm = CGPoint(x: velocity.x / rbSpeed, y: velocity.y / rbSpeed)
        let dot = velNorm.x * toDefNorm.x + velNorm.y * toDefNorm.y

        let rbStrength = homeRoster?.rbs.first?.strength ?? 70
        let rbSpeedStat = homeRoster?.rbs.first?.speed ?? 70

        let breakChance: Double
        if dot < -0.2 {
            // Stiff arm: moving opposite the defender. Strength-driven.
            breakChance = min(0.40, max(0.0, 0.15 + Double(rbStrength - 70) * 0.006))
        } else if abs(dot) < 0.5 {
            // Juke: moving perpendicular. Speed-driven.
            breakChance = min(0.40, max(0.0, 0.15 + Double(rbSpeedStat - 70) * 0.006))
        } else {
            // Running directly into the defender — no break.
            return false
        }

        guard Double.random(in: 0..<1) < breakChance else { return false }

        // Stun the defender for a moment and float a "BROKEN TACKLE" label.
        defender.isStunned = true
        defender.stunnedUntil = time + 0.6

        let label = SKLabelNode(text: "BROKEN TACKLE!")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 10
        label.fontColor = .yellow
        label.position = CGPoint(x: defender.position.x, y: defender.position.y + 16)
        label.zPosition = 100
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 18, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
            ]),
            SKAction.removeFromParent(),
        ]))
        return true
    }

    // MARK: - Coverage

    /// Move each cover defender toward their assigned receiver.
    /// Stat-driven: CB awareness + LB speed set pursuit rate. Safeties trail
    /// deeper so there's a cushion over the top rather than press coverage.
    private func updateCoverage(dt: TimeInterval) {
        let cbFactor = CGFloat(awayRoster?.cbAwareness ?? 70) / 70.0
        let lbFactor = CGFloat(awayRoster?.lbSpeed ?? 70) / 70.0
        // Base coverage speed. Tuned a hair under typical WR route speed so
        // receivers create separation on breaks but aren't wide open.
        let baseCoverSpeed: CGFloat = 22

        for (defIdx, role) in coverageAssignments {
            guard defIdx < defensePlayers.count,
                  let receiver = offensePlayers[role] else { continue }
            let def = defensePlayers[defIdx]

            // Safeties (9, 10) shade deeper; LBs/CBs trail tight.
            let isSafety = defIdx >= 9
            let isLinebacker = defIdx >= 4 && defIdx <= 6
            let trailY: CGFloat = isSafety ? 34 : 6
            let target = CGPoint(x: receiver.position.x,
                                  y: receiver.position.y + trailY)

            let dx = target.x - def.position.x
            let dy = target.y - def.position.y
            let dist = sqrt(dx * dx + dy * dy)
            guard dist > 1.5 else { continue }

            let factor = isLinebacker ? lbFactor : cbFactor
            let speed = baseCoverSpeed * factor * CGFloat(dt)
            def.position.x += (dx / dist) * speed
            def.position.y += (dy / dist) * speed
        }
    }

    // MARK: - Sweet spots

    private func checkSweetSpots() {
        guard let play = gameState.currentPlay else { return }
        for (role, route) in play.routes {
            guard route.sweetSpotIndex >= 0,
                  sweetSpotFired[role] != true,
                  let sprite = offensePlayers[role] else { continue }

            // Estimate if we've reached the sweet spot segment
            var segmentStart: TimeInterval = 0
            for (i, wp) in route.waypoints.enumerated() {
                if i == route.sweetSpotIndex {
                    let windowStart = segmentStart + wp.duration * 0.4
                    let windowEnd = segmentStart + wp.duration * 0.9
                    if routeStartTime >= windowStart && routeStartTime <= windowEnd {
                        sprite.isSweetSpotActive = true
                        sweetSpotFired[role] = true
                        // Turn off after window
                        let remaining = windowEnd - routeStartTime
                        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                            sprite.isSweetSpotActive = false
                        }
                    }
                    break
                }
                segmentStart += wp.duration
            }
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, playActive else { return }
        let loc = touch.location(in: self)

        if gameState.phase == .livePlay, let qb = qbSprite {
            // Scramble mode: drag moves the QB anywhere; no throw is armed.
            if gameState.scrambleMode {
                isDraggingQB = true
                return
            }
            // Aim-and-release: touch near the QB arms a throw. On release,
            // the ball flies to wherever the finger ended.
            let dx = loc.x - qb.position.x
            let dy = loc.y - qb.position.y
            if sqrt(dx * dx + dy * dy) < 55 {
                beginAiming(at: loc)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        if isAimingThrow {
            updateAim(to: loc)
            return
        }
        if isDraggingQB, let qb = qbSprite {
            qb.position = loc
            ballSprite.position = loc
        }
        if isDraggingRB, let rb = rbSprite {
            rb.position = loc
            ballSprite.position = loc
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isAimingThrow {
            let landing = touches.first?.location(in: self) ?? (qbSprite?.position ?? .zero)
            endAiming(throwingTo: landing)
            return
        }
        isDraggingQB = false
    }

    // MARK: - Aim-and-release

    private func beginAiming(at point: CGPoint) {
        guard qbSprite != nil else { return }
        isAimingThrow = true

        // Dashed arc line from QB to the current aim point.
        let line = SKShapeNode()
        line.strokeColor = SKColor.cyan.withAlphaComponent(0.75)
        line.lineWidth = 2
        line.zPosition = 50
        aimArcLine = line
        addChild(line)

        // Ghost target ring where the ball would land.
        let ring = SKShapeNode(circleOfRadius: 18)
        ring.strokeColor = SKColor.cyan
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.zPosition = 50
        aimTargetRing = ring
        addChild(ring)

        updateAim(to: point)
    }

    private func updateAim(to point: CGPoint) {
        guard isAimingThrow, let qb = qbSprite else { return }
        let target = clampedAimPoint(from: qb.position, to: point)

        // Rebuild the preview arc: same parabola the ball will actually fly.
        let path = CGMutablePath()
        path.move(to: qb.position)
        let midY = (qb.position.y + target.y) / 2 + max(18, sqrt(hypot(target.x - qb.position.x, target.y - qb.position.y)) * 2.5)
        path.addQuadCurve(to: target, control: CGPoint(x: (qb.position.x + target.x) / 2, y: midY))
        aimArcLine?.path = path
        aimTargetRing?.position = target
    }

    /// Keep the aim point on-field and forward of the QB (small buffer lets
    /// short dump-offs still land just behind the LOS).
    private func clampedAimPoint(from qb: CGPoint, to raw: CGPoint) -> CGPoint {
        let maxX = FieldRenderer.centerX(sceneSize: size) + FieldRenderer.fieldWidth / 2 - 10
        let minX = FieldRenderer.centerX(sceneSize: size) - FieldRenderer.fieldWidth / 2 + 10
        let minY = qb.y - 40
        return CGPoint(
            x: min(maxX, max(minX, raw.x)),
            y: max(minY, raw.y)
        )
    }

    private func endAiming(throwingTo rawPoint: CGPoint) {
        guard let qb = qbSprite else { return }
        isAimingThrow = false
        aimArcLine?.removeFromParent(); aimArcLine = nil
        aimTargetRing?.removeFromParent(); aimTargetRing = nil

        let landing = clampedAimPoint(from: qb.position, to: rawPoint)
        throwToPoint(landing)
    }

    // MARK: - Throw

    /// Throw the ball to an aimed point on the field. Outcome is resolved
    /// when the ball arrives, based on who's actually nearest the spot.
    private func throwToPoint(_ landing: CGPoint) {
        guard playActive, let qb = qbSprite else { return }
        playActive = false
        isDraggingQB = false
        gameState.receiverOptions = []
        isBallInFlight = true

        // Stop all receiver routes — the ball is the only thing that matters
        // from here until it arrives.
        for sprite in offensePlayers.values {
            sprite.removeAction(forKey: "route")
        }

        // Throw duration scales with distance so short throws snap fast and
        // deep throws hang long enough for receivers to track them.
        ballSprite.position = qb.position
        let distance = hypot(landing.x - qb.position.x, landing.y - qb.position.y)
        let duration = min(1.4, 0.3 + Double(distance) / 600.0)

        ballSprite.fly(to: landing, duration: duration) { [weak self] in
            guard let self else { return }
            self.isBallInFlight = false
            self.resolveLandingSpot(landing)
        }
    }

    /// Walk every player near the landing point and ask the resolver who wins
    /// the catch. Feeds the result into the existing play-result pipeline.
    private func resolveLandingSpot(_ landing: CGPoint) {
        // Build the offense candidate list from live sprite positions —
        // whoever broke off their route closest to the landing spot.
        let offense: [PlayOutcomeResolver.CatchCandidate] = offensePlayers.compactMap { (role, sprite) in
            // OL blockers aren't eligible receivers.
            if role == .ol1 || role == .ol2 || role == .ol3 || role == .ol4 || role == .ol5 {
                return nil
            }
            return PlayOutcomeResolver.CatchCandidate(
                pos: sprite.position,
                speed: receiverSpeed(for: role),
                awareness: homeRoster?.qb.awareness ?? 70,
                overall: receiverOverall(for: role)
            )
        }

        // Defense: every defender is a potential interceptor/deflector.
        let defense: [PlayOutcomeResolver.CatchCandidate] = defensePlayers.enumerated().map { (idx, sprite) in
            let awareness = idx >= 7 ? (awayRoster?.cbAwareness ?? 70) : 70
            return PlayOutcomeResolver.CatchCandidate(
                pos: sprite.position,
                speed: 70,
                awareness: awareness,
                overall: awareness
            )
        }

        let depthYards = Int((landing.y - (qbSprite?.position.y ?? landing.y)) / FieldRenderer.yardSpacing)

        let outcome = PlayOutcomeResolver.resolveContestedCatch(
            landing: landing,
            offense: offense,
            defense: defense,
            routeDepthYards: max(0, depthYards),
            defensePlay: gameState.currentDefense
        )

        switch outcome {
        case .complete(let yards):
            resolvePlayResult(yards: yards,
                              text: "COMPLETE! +\(yards) yds",
                              isPositive: true)
        case .incomplete:
            resolvePlayResult(yards: 0, text: "INCOMPLETE",
                              isPositive: false, wasIncomplete: true)
        case .interception:
            resolvePlayResult(yards: 0, text: "INTERCEPTED!",
                              isPositive: false, isTurnover: true)
        default:
            resolvePlayResult(yards: 0, text: "INCOMPLETE",
                              isPositive: false, wasIncomplete: true)
        }
    }

    private func receiverSpeed(for role: Formation.SlotRole) -> Int {
        guard let home = homeRoster else { return 70 }
        switch role {
        case .wr1: return home.wrs.first?.speed ?? 70
        case .wr2: return home.wrs.count > 1 ? home.wrs[1].speed : 70
        case .wr3: return home.wrs.count > 2 ? home.wrs[2].speed : 70
        case .te:  return home.te.speed
        case .rb, .rb2: return home.rbs.first?.speed ?? 70
        case .qb:  return home.qb.speed
        default:   return 70
        }
    }

    private func receiverOverall(for role: Formation.SlotRole) -> Int {
        guard let home = homeRoster else { return 70 }
        switch role {
        case .wr1: return home.wrs.first?.overall ?? 70
        case .wr2: return home.wrs.count > 1 ? home.wrs[1].overall : 70
        case .wr3: return home.wrs.count > 2 ? home.wrs[2].overall : 70
        case .te:  return home.te.overall
        case .rb, .rb2: return home.rbs.first?.overall ?? 70
        case .qb:  return home.qb.overall
        default:   return 70
        }
    }

    // MARK: - Result resolution

    private func resolvePlayResult(yards: Int, text: String, isPositive: Bool,
                                    isTurnover: Bool = false,
                                    wasIncomplete: Bool = false) {
        // Burn clock — incompletions stop it, scores stop it.
        let willScore = gameState.ballYardLine + yards >= 100
        let clockStops = wasIncomplete || isTurnover || willScore
        let timeUsed: Double = gameState.currentPlay?.isRunPlay == true ? 22 : 15
        let quarterEnded = gameState.burnClock(seconds: timeUsed, clockStops: clockStops)

        if isTurnover {
            gameState.resultText = text
            gameState.resultDetail = "Turnover — opponent ball"
            gameState.resultIsPositive = false
            gameState.phase = .playResult
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.gameState.flipPossession()
                self?.clearPlayers()
                self?.checkQuarterAndContinue(quarterEnded: quarterEnded)
            }
            return
        }

        gameState.advanceDown(yardsGained: yards)

        // TD check → trigger PAT mini-game
        if gameState.ballYardLine >= 100 {
            gameState.scoreTDPoints()
            gameState.resultText = "TOUCHDOWN!"
            gameState.resultDetail = "\(gameState.homeTeamName) \(gameState.homeScore) - \(gameState.awayTeamName) \(gameState.awayScore)"
            gameState.resultIsPositive = true
            gameState.phase = .playResult
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                guard let self else { return }
                self.clearPlayers()
                // PAT mini-game only if user's TD; AI auto-makes PAT
                if self.gameState.userHasBall {
                    self.gameState.phase = .patAttempt
                } else {
                    self.gameState.scorePATPoints()
                    self.gameState.flipPossession()
                    self.checkQuarterAndContinue(quarterEnded: quarterEnded)
                }
            }
            return
        }

        // 4th down: auto-punt or auto-FG based on field position
        if gameState.down > 4 {
            if gameState.ballYardLine >= 60 {
                // FG range — trigger mini-game (user only; AI auto-sims)
                if gameState.userHasBall {
                    gameState.phase = .fgAttempt
                    gameState.resultText = ""
                    gameState.resultDetail = ""
                    return
                } else {
                    // AI FG — 75% chance
                    if Double.random(in: 0..<1) < 0.75 {
                        gameState.scoreFG()
                        gameState.resultText = "FG GOOD!"
                    } else {
                        gameState.resultText = "FG MISSED"
                    }
                    gameState.resultDetail = ""
                    gameState.resultIsPositive = false
                    gameState.phase = .playResult
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        self?.gameState.flipPossession()
                        self?.clearPlayers()
                        self?.checkQuarterAndContinue(quarterEnded: quarterEnded)
                    }
                    return
                }
            } else {
                gameState.resultText = "TURNOVER ON DOWNS"
                gameState.resultDetail = ""
                gameState.resultIsPositive = false
                gameState.phase = .playResult
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.gameState.flipPossession()
                    self?.clearPlayers()
                    self?.checkQuarterAndContinue(quarterEnded: quarterEnded)
                }
                return
            }
        }

        gameState.resultText = text
        gameState.resultDetail = "\(gameState.downText) at \(gameState.ballYardLine)"
        gameState.resultIsPositive = isPositive
        gameState.phase = .playResult

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.clearPlayers()
            self?.checkQuarterAndContinue(quarterEnded: quarterEnded)
        }
    }

    /// After any play, check if the quarter ended and transition phases.
    private func checkQuarterAndContinue(quarterEnded: Bool) {
        if quarterEnded {
            // Show end-of-quarter flash, then advance
            let wasQ = gameState.quarter
            if wasQ == 2 {
                gameState.resultText = "HALFTIME"
                gameState.resultDetail = "\(gameState.homeTeamName) \(gameState.homeScore) — \(gameState.awayTeamName) \(gameState.awayScore)"
                gameState.resultIsPositive = true
                gameState.phase = .halftime
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    _ = self?.gameState.advanceQuarter()
                    self?.resumeAfterBreak()
                }
            } else {
                gameState.resultText = "END OF Q\(wasQ)"
                gameState.resultDetail = ""
                gameState.resultIsPositive = true
                gameState.phase = .playResult
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    let gameOver = self?.gameState.advanceQuarter() ?? false
                    if gameOver {
                        self?.gameState.phase = .gameOver
                    } else {
                        self?.resumeAfterBreak()
                    }
                }
            }
            return
        }
        // Normal continue
        gameState.phase = gameState.userHasBall ? .playCalling : .defPlayCalling
    }

    private func resumeAfterBreak() {
        gameState.phase = gameState.userHasBall ? .playCalling : .defPlayCalling
    }

    /// Called after PAT mini-game resolves.
    func resolvePAT(made: Bool) {
        if made { gameState.scorePATPoints() }
        gameState.resultText = made ? "PAT GOOD" : "PAT MISSED"
        gameState.resultDetail = ""
        gameState.resultIsPositive = made
        gameState.phase = .playResult
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.gameState.flipPossession()
            self?.clearPlayers()
            self?.checkQuarterAndContinue(quarterEnded: self?.gameState.clockSeconds == 0)
        }
    }

    /// Called after FG mini-game resolves.
    func resolveFG(made: Bool) {
        if made { gameState.scoreFG() }
        gameState.resultText = made ? "FG GOOD!" : "FG MISSED"
        gameState.resultDetail = ""
        gameState.resultIsPositive = made
        gameState.phase = .playResult
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.gameState.flipPossession()
            self?.clearPlayers()
            self?.checkQuarterAndContinue(quarterEnded: self?.gameState.clockSeconds == 0)
        }
    }

    // MARK: - Defensive auto-sim

    func autoSimDefensiveDrive() {
        let possibleResults: [(String, String, Int)] = [
            ("Opponent punts", "3 and out", 0),
            ("Opponent FG", "Field goal is GOOD", 3),
            ("Opponent TD", "Touchdown!", 7),
            ("Opponent punt", "Gain of 22, then punt", 0),
            ("PICK!", "Your defense intercepts!", 0),
        ]
        let weights = [35.0, 15.0, 20.0, 20.0, 10.0]
        let roll = Double.random(in: 0..<weights.reduce(0, +))
        var cumulative = 0.0
        var pick = possibleResults[0]
        for (i, w) in weights.enumerated() {
            cumulative += w
            if roll < cumulative { pick = possibleResults[i]; break }
        }

        if pick.2 > 0 {
            if gameState.isHomePossession { gameState.homeScore += pick.2 }
            else { gameState.awayScore += pick.2 }
        }

        // Opponent drives burn ~90 game seconds
        let quarterEnded = gameState.burnClock(seconds: 90, clockStops: false)

        gameState.resultText = pick.0
        gameState.resultDetail = pick.1
        gameState.resultIsPositive = pick.2 == 0
        gameState.phase = .playResult

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.gameState.flipPossession()
            self?.checkQuarterAndContinue(quarterEnded: quarterEnded)
        }
    }
}
