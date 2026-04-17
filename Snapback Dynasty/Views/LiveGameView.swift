import SwiftUI

struct LiveGameView: View {
    let homeTeam: TeamSnap
    let awayTeam: TeamSnap
    let result: GameResult
    let onDismiss: () -> Void

    @State private var visiblePlays = 0
    @State private var playSpeed: Double = 0.3
    @State private var isPlaying = true
    @State private var homeAnimScore = 0
    @State private var awayAnimScore = 0

    private let speeds: [(String, Double)] = [
        ("Slow", 1.0), ("Normal", 0.5), ("Fast", 0.2), ("Turbo", 0.08), ("Instant", 0.0)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scoreboard
                speedControl
                playByPlayList
            }
            .navigationTitle("Game Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
            .onAppear { startPlayback() }
        }
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        HStack {
            teamScore(name: awayTeam.abbreviation, color: awayTeam.primaryColor, score: awayAnimScore)
            Spacer()
            VStack(spacing: 2) {
                Text("FINAL").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                if visiblePlays >= result.plays.count {
                    Text("\(result.homeScore > result.awayScore ? homeTeam.abbreviation : awayTeam.abbreviation) WINS")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.green)
                }
            }
            Spacer()
            teamScore(name: homeTeam.abbreviation, color: homeTeam.primaryColor, score: homeAnimScore)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func teamScore(name: String, color: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.caption.weight(.bold))
            Text("\(score)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(width: 80)
    }

    // MARK: - Speed control

    private var speedControl: some View {
        HStack(spacing: 8) {
            ForEach(speeds, id: \.0) { name, speed in
                Button(name) { playSpeed = speed }
                    .font(.caption2.weight(playSpeed == speed ? .bold : .regular))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(playSpeed == speed ? Color.accentColor.opacity(0.2) : .clear,
                                in: Capsule())
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Play list

    private var playByPlayList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<min(visiblePlays, result.plays.count), id: \.self) { i in
                        playRow(result.plays[i], index: i)
                            .id(i)
                    }
                }
                .padding()
            }
            .onChange(of: visiblePlays) { _, newVal in
                withAnimation { proxy.scrollTo(newVal - 1, anchor: .bottom) }
            }
        }
    }

    private func playRow(_ play: PlayResult, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconFor(play))
                .font(.caption)
                .foregroundStyle(colorFor(play))
                .frame(width: 20)

            Text(play.description)
                .font(.caption)
                .foregroundStyle(play.isTouchdown ? .green : play.isTurnover ? .red : .primary)
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(play.isTouchdown ? Color.green.opacity(0.08) :
                     play.isTurnover ? Color.red.opacity(0.08) : .clear,
                     in: RoundedRectangle(cornerRadius: 6))
    }

    private func iconFor(_ play: PlayResult) -> String {
        switch play.type {
        case "pass": return play.isComplete ? "football.fill" : "xmark.circle"
        case "run", "scramble": return "figure.run"
        case "sack": return "exclamationmark.triangle.fill"
        case "punt": return "arrow.up.forward"
        case "fg": return "target"
        default: return "circle"
        }
    }

    private func colorFor(_ play: PlayResult) -> Color {
        if play.isTouchdown { return .green }
        if play.isTurnover { return .red }
        switch play.type {
        case "sack": return .orange
        case "punt", "fg": return .blue
        default: return .primary
        }
    }

    // MARK: - Playback

    private func startPlayback() {
        guard isPlaying else { return }
        if playSpeed == 0 {
            withAnimation { visiblePlays = result.plays.count }
            homeAnimScore = result.homeScore
            awayAnimScore = result.awayScore
            return
        }

        func showNext() {
            guard visiblePlays < result.plays.count else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                visiblePlays += 1
            }
            // Update animated scores based on drives
            recalcScores()
            DispatchQueue.main.asyncAfter(deadline: .now() + playSpeed) {
                showNext()
            }
        }
        showNext()
    }

    private func recalcScores() {
        // Rough: count TDs and FGs from visible plays
        var hs = 0, as_ = 0
        var currentTeamIsHome = true // first drive is home
        var driveIdx = 0
        for i in 0..<min(visiblePlays, result.plays.count) {
            let play = result.plays[i]
            if play.isTouchdown {
                if driveIdx % 2 == 0 { hs += 7 } else { as_ += 7 }
            }
            if play.type == "fg" && play.scoringPlayerName != nil {
                if driveIdx % 2 == 0 { hs += 3 } else { as_ += 3 }
            }
            // Rough drive boundary detection: after punt/turnover/TD/fg/end
            if ["punt", "fg"].contains(play.type) || play.isTouchdown || play.isTurnover {
                driveIdx += 1
            }
        }
        withAnimation { homeAnimScore = hs; awayAnimScore = as_ }
    }
}
