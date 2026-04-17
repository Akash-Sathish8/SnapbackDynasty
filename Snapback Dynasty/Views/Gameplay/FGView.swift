import SwiftUI

/// Two-tap power+accuracy mini-game for FGs and PATs.
struct FGView: View {
    enum Mode { case fieldGoal, pat }

    let mode: Mode
    let distance: Int   // yards from goal posts (for FG, bigger = harder)
    let kickerOverall: Int  // affects bar speed
    let onComplete: (Bool) -> Void

    @State private var powerPhase: CGFloat = 0
    @State private var powerLocked: CGFloat? = nil
    @State private var accuracyPhase: CGFloat = 0
    @State private var accuracyLocked: CGFloat? = nil
    @State private var resolved: Bool = false
    @State private var timer: Timer? = nil

    private var kickSpeed: Double {
        // Higher overall = slower oscillation = easier
        return 1.4 - Double(kickerOverall) / 150.0
    }

    /// Where the "good" zone is, size depending on distance (PATs wide, long FGs narrow).
    private var goodZoneWidth: CGFloat {
        switch mode {
        case .pat: return 0.35
        case .fieldGoal:
            if distance >= 50 { return 0.12 }
            if distance >= 40 { return 0.18 }
            return 0.26
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(mode == .pat ? "EXTRA POINT" : "FIELD GOAL • \(distance) yds")
                .font(.system(size: 14, weight: .black))
                .kerning(1.5)
                .foregroundStyle(.white)

            goalPosts
                .frame(width: 180, height: 80)

            bar(title: "POWER", phase: powerPhase, locked: powerLocked,
                goodZone: goodZoneWidth)
            bar(title: "ACCURACY", phase: accuracyPhase, locked: accuracyLocked,
                goodZone: goodZoneWidth * 1.1)

            Button {
                tap()
            } label: {
                Text(powerLocked == nil ? "LOCK POWER" :
                     accuracyLocked == nil ? "LOCK ACCURACY" : "KICKED")
                    .font(.system(size: 14, weight: .black))
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Color.white.opacity(0.2),
                                in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
            .disabled(resolved)
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private var goalPosts: some View {
        ZStack {
            // Uprights
            HStack(spacing: 60) {
                Rectangle().fill(.yellow).frame(width: 3, height: 80)
                Rectangle().fill(.yellow).frame(width: 3, height: 80)
            }
            // Crossbar
            Rectangle().fill(.yellow).frame(width: 63, height: 3)
                .offset(y: -10)
        }
    }

    private func bar(title: String, phase: CGFloat, locked: CGFloat?,
                     goodZone: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .kerning(1.2)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    Capsule().fill(.green.opacity(0.5))
                        .frame(width: geo.size.width * goodZone)
                        .offset(x: geo.size.width * (0.5 - goodZone / 2))
                    // Moving marker
                    Rectangle().fill(.white)
                        .frame(width: 3, height: 24)
                        .offset(x: geo.size.width * (locked ?? phase) - 1.5, y: -2)
                }
            }
            .frame(height: 20)
        }
        .frame(width: 220)
    }

    private func tap() {
        if powerLocked == nil {
            powerLocked = powerPhase
        } else if accuracyLocked == nil {
            accuracyLocked = accuracyPhase
            resolve()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            if powerLocked == nil {
                powerPhase = oscillate(CGFloat(Date().timeIntervalSince1970))
            }
            if powerLocked != nil && accuracyLocked == nil {
                accuracyPhase = oscillate(CGFloat(Date().timeIntervalSince1970) * 1.2)
            }
        }
    }

    private func oscillate(_ t: CGFloat) -> CGFloat {
        let speed = CGFloat(kickSpeed)
        return (sin(t * speed * .pi) + 1) / 2
    }

    private func resolve() {
        guard let p = powerLocked, let a = accuracyLocked else { return }
        resolved = true
        timer?.invalidate()
        let powerOK = abs(p - 0.5) < goodZoneWidth / 2
        let accuracyOK = abs(a - 0.5) < (goodZoneWidth * 1.1) / 2
        let made = powerOK && accuracyOK
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete(made)
        }
    }
}
