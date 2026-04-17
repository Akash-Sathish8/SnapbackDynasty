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

        if play.isRunPlay {
            gameState.phase = .runningPlay
            gameState.receiverOptions = []
            animateHandoff(play: play)
        } else {
            gameState.phase = .livePlay
            gameState.receiverOptions = buildReceiverOptions(play: play)
            animateRoutes(play: play)
        }

        ballSprite.position = qb.position
    }

    /// Build the throwable-receiver list that drives the THROW buttons.
    private func buildReceiverOptions(play: PlayDefinition) -> [GameState.ReceiverOption] {
        play.routes.compactMap { (role, route) in
            guard route.name != "Block", role != .qb, role != .rb2 else { return nil }
            return GameState.ReceiverOption(
                id: role.rawValue,
                label: receiverLabel(role),
                jersey: slotJersey(role)
            )
        }
        .sorted { $0.label < $1.label }
    }

    private func receiverLabel(_ role: Formation.SlotRole) -> String {
        switch role {
        case .wr1: return "X"
        case .wr2: return "Z"
        case .wr3: return "SLOT"
        case .te:  return "TE"
        case .rb, .rb2: return "RB"
        default:   return role.rawValue.uppercased()
        }
    }

    /// Public entry point for SwiftUI throw buttons.
    func throwToRoleID(_ id: String) {
        guard playActive,
              gameState.phase == .livePlay,
              let role = Formation.SlotRole(rawValue: id),
              let sprite = offensePlayers[role] else { return }
        throwTo(role: role, sprite: sprite)
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

        // Camera follows ball carrier (QB on pass, RB on run).
        let followY: CGFloat? = {
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

            // Sweet spot timing windows
            checkSweetSpots()

            // Coverage: non-DL defenders shadow their assigned receiver.
            updateCoverage(dt: dt)
        }

        // Run play: check tackle
        if gameState.phase == .runningPlay, isDraggingRB, let rb = rbSprite {
            for def in defensePlayers {
                let dx = def.position.x - rb.position.x
                let dy = def.position.y - rb.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < 12 {
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
            // Defenders converge on RB
            for def in defensePlayers {
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

        // On pass plays, tapping anywhere near a receiver throws to them.
        // Use a big hit radius (50pt) since sprites are tiny.
        if gameState.phase == .livePlay {
            // Pick the closest eligible receiver within range, not first match.
            var closest: (role: Formation.SlotRole, sprite: PlayerSprite, dist: CGFloat)?
            for (role, sprite) in offensePlayers {
                guard sprite.isTapTarget else { continue }
                let dx = loc.x - sprite.position.x
                let dy = loc.y - sprite.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < 55 {
                    if closest == nil || dist < closest!.dist {
                        closest = (role, sprite, dist)
                    }
                }
            }
            if let c = closest {
                throwTo(role: c.role, sprite: c.sprite)
                return
            }
            // Otherwise, start dragging QB.
            if let qb = qbSprite {
                let dx = loc.x - qb.position.x
                let dy = loc.y - qb.position.y
                if sqrt(dx * dx + dy * dy) < 55 {
                    isDraggingQB = true
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
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
        isDraggingQB = false
    }

    // MARK: - Throw

    private func throwTo(role: Formation.SlotRole, sprite: PlayerSprite) {
        guard playActive else { return }
        playActive = false
        isDraggingQB = false
        gameState.receiverOptions = []
        sprite.removeAction(forKey: "route")

        let timing = sprite.isSweetSpotActive ? 0.0 : (routeStartTime > 1.5 ? 0.4 : 0.2)
        sprite.isSweetSpotActive = false

        let routeDepth: CGFloat = {
            guard let play = gameState.currentPlay, let route = play.routes[role] else { return 30 }
            return route.waypoints.reduce(0) { $0 + abs($1.dy) }
        }()

        // Real stats from rosters
        let qbAwareness = homeRoster?.qb.awareness ?? 70
        let wrSpeed: Int = {
            guard let home = homeRoster else { return 70 }
            switch role {
            case .wr1: return home.wrs.first?.speed ?? 70
            case .wr2: return home.wrs.count > 1 ? home.wrs[1].speed : 70
            case .wr3: return home.wrs.count > 2 ? home.wrs[2].speed : 70
            case .te:  return home.te.speed
            case .rb, .rb2: return home.rbs.first?.speed ?? 70
            default:   return 70
            }
        }()
        let cbAwareness = awayRoster?.cbAwareness ?? 70

        ballSprite.fly(to: sprite.position, duration: 0.4) { [weak self] in
            guard let self else { return }
            let outcome = PlayOutcomeResolver.resolvePass(
                timing: timing, qbAwareness: qbAwareness, wrSpeed: wrSpeed,
                cbAwareness: cbAwareness, defense: self.gameState.currentDefense,
                routeDepth: routeDepth
            )
            switch outcome {
            case .complete(let yards):
                self.resolvePlayResult(yards: yards,
                                       text: "COMPLETE! +\(yards) yds",
                                       isPositive: true)
            case .incomplete:
                self.resolvePlayResult(yards: 0, text: "INCOMPLETE",
                                       isPositive: false,
                                       wasIncomplete: true)
            case .interception:
                self.resolvePlayResult(yards: 0, text: "INTERCEPTED!",
                                       isPositive: false, isTurnover: true)
            default: break
            }
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
