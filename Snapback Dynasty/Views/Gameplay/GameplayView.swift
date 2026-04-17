import SwiftUI
import SpriteKit

struct GameplayView: View {
    let homeTeamName: String
    let awayTeamName: String
    let homeColor: String
    let awayColor: String
    let homeLogo: String
    var homeRoster: GameplayRoster? = nil
    var awayRoster: GameplayRoster? = nil
    /// Returns (home score, away score) when the game completes; nil if user exits early.
    let onComplete: (Int, Int) -> Void

    @AppStorage("quarterLengthChoice") private var quarterLengthChoice: String = "medium"
    @State private var scene: GameplayScene?
    @State private var gameState = GameState()

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    hudBar
                    Spacer()
                }

                overlays
            } else {
                Color.black
                ProgressView("Loading…").foregroundStyle(.white)
            }
        }
        .onAppear { buildScene() }
        .statusBarHidden()
    }

    // MARK: - HUD

    private var hudBar: some View {
        HStack(spacing: 12) {
            Text(gameState.homeTeamName)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
            Text("\(gameState.homeScore)")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
            Text("—").foregroundStyle(.white.opacity(0.4))
            Text("\(gameState.awayScore)")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
            Text(gameState.awayTeamName)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
            Spacer()
            Text(gameState.clockText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(gameState.downText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Button {
                onComplete(gameState.homeScore, gameState.awayScore)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.black.opacity(0.65))
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlays: some View {
        switch gameState.phase {
        case .playCalling:
            PlayCallView(teamColor: homeColor) { play in
                gameState.currentPlay = play
                scene?.setupFormation(play: play,
                                       offenseColor: homeColor,
                                       defenseColor: awayColor)
                gameState.phase = .preSnap
            }

        case .defPlayCalling:
            DefPlayCallView { defense in
                gameState.currentDefense = defense
                scene?.autoSimDefensiveDrive()
            }

        case .preSnap:
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    if let alt = gameState.currentPlay?.audibleAlt,
                       let altPlay = Playbook.all.first(where: { $0.name == alt }) {
                        Button {
                            gameState.currentPlay = altPlay
                            scene?.setupFormation(play: altPlay,
                                                   offenseColor: homeColor,
                                                   defenseColor: awayColor)
                        } label: {
                            Text("AUDIBLE")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        gameState.currentDefense = DefensivePlaybook.all.randomElement()
                        scene?.snap()
                    } label: {
                        Text("SNAP")
                            .font(.system(size: 14, weight: .black))
                            .padding(.horizontal, 24).padding(.vertical, 12)
                            .background(Color(hex: homeColor), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 24)
            }

        case .livePlay:
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    ForEach(gameState.receiverOptions) { opt in
                        Button {
                            scene?.throwToRoleID(opt.id)
                        } label: {
                            VStack(spacing: 2) {
                                Text("#\(opt.jersey)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                Text(opt.label)
                                    .font(.system(size: 12, weight: .black))
                            }
                            .frame(width: 60, height: 48)
                            .background(Color(hex: homeColor),
                                        in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 24)
            }

        case .playResult, .halftime:
            ResultFlashView(
                text: gameState.resultText,
                detail: gameState.resultDetail,
                isPositive: gameState.resultIsPositive
            )

        case .patAttempt:
            FGView(mode: .pat, distance: 20, kickerOverall: 75) { made in
                scene?.resolvePAT(made: made)
            }

        case .fgAttempt:
            FGView(mode: .fieldGoal,
                   distance: 100 - gameState.ballYardLine + 17,
                   kickerOverall: 75) { made in
                scene?.resolveFG(made: made)
            }

        case .gameOver:
            PostGameView(
                homeName: gameState.homeTeamName,
                awayName: gameState.awayTeamName,
                homeScore: gameState.homeScore,
                awayScore: gameState.awayScore,
                homeColor: homeColor
            ) {
                onComplete(gameState.homeScore, gameState.awayScore)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Setup

    private func buildScene() {
        gameState.homeTeamName = homeTeamName
        gameState.awayTeamName = awayTeamName
        let seconds: Double = {
            switch quarterLengthChoice {
            case "short": return 60
            case "long": return 180
            default: return 120
            }
        }()
        gameState.quarterLengthSeconds = seconds
        gameState.clockSeconds = seconds

        let s = GameplayScene(size: CGSize(width: 800, height: 400))
        s.scaleMode = .aspectFill
        s.homeTeamName = homeTeamName
        s.awayTeamName = awayTeamName
        s.homeColor = homeColor
        s.awayColor = awayColor
        s.homeLogo = homeLogo
        s.homeRoster = homeRoster
        s.awayRoster = awayRoster
        s.gameState = gameState
        scene = s
    }
}
