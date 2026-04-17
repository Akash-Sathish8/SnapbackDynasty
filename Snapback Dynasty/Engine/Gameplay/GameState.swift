import Foundation
import Observation

/// Shared game state observed by both SpriteKit scene and SwiftUI overlays.
@Observable
final class GameState {
    // MARK: - Score
    var homeScore: Int = 0
    var awayScore: Int = 0
    var homeTeamName: String = "HOME"
    var awayTeamName: String = "AWAY"

    // MARK: - Clock
    var quarter: Int = 1
    var clockSeconds: Double = 0  // game clock (counts down)
    var quarterLengthSeconds: Double = 90  // Short=45, Med=90, Long=120

    // MARK: - Down & distance
    var down: Int = 1
    var yardsToGo: Int = 10
    var ballYardLine: Int = 25   // own 0-100 (0=own goal, 100=opp goal)
    var firstDownMarker: Int = 35

    // MARK: - Possession
    var userHasBall: Bool = true
    var isHomePossession: Bool = true  // home team has ball

    // MARK: - Phase
    enum Phase: String {
        case playCalling
        case defPlayCalling
        case preSnap
        case livePlay
        case runningPlay
        case playResult
        case scoring
        case fgAttempt
        case patAttempt
        case halftime
        case gameOver
    }
    var phase: Phase = .playCalling

    // MARK: - Current play
    var currentPlay: PlayDefinition?
    var currentDefense: DefensivePlay?
    var resultText: String = ""
    var resultDetail: String = ""
    var resultIsPositive: Bool = true

    // MARK: - Live throw targets
    /// Throwable receivers for the current pass play. Populated on snap,
    /// cleared when the play ends. Drives the THROW buttons in the HUD.
    struct ReceiverOption: Identifiable, Equatable {
        let id: String      // Formation.SlotRole.rawValue
        let label: String   // X / Z / SLOT / TE / RB
        let jersey: Int
    }
    var receiverOptions: [ReceiverOption] = []

    // MARK: - Computed
    var downText: String {
        let suffix: String
        switch down {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
        return "\(down)\(suffix) & \(yardsToGo)"
    }

    var clockText: String {
        let min = Int(clockSeconds) / 60
        let sec = Int(clockSeconds) % 60
        return String(format: "Q%d %d:%02d", quarter, min, sec)
    }

    var possessionTeamName: String {
        isHomePossession ? homeTeamName : awayTeamName
    }

    // MARK: - Advance

    func advanceDown(yardsGained: Int) {
        ballYardLine += yardsGained
        if ballYardLine >= firstDownMarker {
            down = 1
            yardsToGo = min(10, 100 - ballYardLine)
            firstDownMarker = min(100, ballYardLine + 10)
        } else {
            down += 1
            yardsToGo = firstDownMarker - ballYardLine
        }
    }

    func flipPossession() {
        isHomePossession.toggle()
        userHasBall.toggle()
        ballYardLine = 25
        down = 1
        yardsToGo = 10
        firstDownMarker = 35
    }

    /// Adds 6 for TD, PAT handled separately.
    func scoreTDPoints() {
        if isHomePossession { homeScore += 6 } else { awayScore += 6 }
    }

    func scorePATPoints() {
        if isHomePossession { homeScore += 1 } else { awayScore += 1 }
    }

    func scoreFG() {
        if isHomePossession { homeScore += 3 } else { awayScore += 3 }
    }

    // MARK: - Clock

    /// Burn game-time seconds for a play.
    /// Returns true if the quarter just ended.
    @discardableResult
    func burnClock(seconds: Double, clockStops: Bool) -> Bool {
        if clockStops { return false }
        clockSeconds = max(0, clockSeconds - seconds)
        return clockSeconds <= 0
    }

    /// Advance to next quarter. Returns true if game is over.
    @discardableResult
    func advanceQuarter() -> Bool {
        quarter += 1
        if quarter > 4 {
            phase = .gameOver
            return true
        }
        clockSeconds = quarterLengthSeconds
        // Halftime at Q2 → Q3, swap possession (other team gets kickoff)
        if quarter == 3 {
            isHomePossession.toggle()
            userHasBall.toggle()
            ballYardLine = 25
            down = 1
            yardsToGo = 10
            firstDownMarker = 35
        }
        return false
    }

    var winner: String {
        if homeScore > awayScore { return homeTeamName }
        if awayScore > homeScore { return awayTeamName }
        return "TIE"
    }
}
