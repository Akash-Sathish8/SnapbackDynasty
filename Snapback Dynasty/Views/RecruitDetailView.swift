import SwiftUI
import SwiftData

struct RecruitDetailView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var allTeams: [Team]
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]

    @Bindable var recruit: Recruit

    @State private var lastMessage: String?
    @State private var lastDelta: Double = 0
    @State private var showBoardFull = false

    private var playerTeam: Team? { allTeams.first { $0.name == playerTeamName } }
    private var season: Season? { seasons.first }
    private var interest: RecruitInterest? {
        playerTeam?.recruitInterests.first { $0.recruit === recruit }
    }
    private var isOnBoard: Bool {
        playerTeam.map { RecruitingEngine.isOnBoard(team: $0, recruit: recruit) } ?? false
    }
    private var engine: RecruitingEngine { RecruitingEngine(context: context) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerCard
                statusCard
                attributeCard
                motivationsCard
                interestCard
                actionsCard
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .navigationBarTitleDisplayMode(.inline)
        .alert("Board Full", isPresented: $showBoardFull) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your board is at the 35-recruit cap. Remove someone before adding new prospects.")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                PositionBadge(position: recruit.positionRaw, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(recruit.fullName)
                        .font(.playfair(22))
                    HStack(spacing: 8) {
                        StarRating(stars: recruit.stars, size: 13)
                        Text("• \(recruit.archetype)")
                            .font(.lora(11))
                            .foregroundStyle(.secondary)
                    }
                    Text("\(recruit.homeState) • \(recruit.pipeline.displayName)")
                        .font(.lora(10))
                        .foregroundStyle(.secondary)
                    if recruit.gemTag == .gem {
                        Badge(text: "GEM", color: .white, bg: Color(hex: "#15803D"))
                    } else if recruit.gemTag == .overrated && recruit.scoutingTier >= 1 {
                        Badge(text: "OVERRATED", color: .white, bg: Color(hex: "#B91C1C"))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(recruit.revealsOverall ? "\(recruit.overall)" : "??")
                        .font(.playfair(32))
                        .foregroundStyle(Color(hex: playerTeam?.primaryColor ?? "#1C1917"))
                    Text("OVR").font(.lora(8, weight: .semibold))
                        .kerning(1.2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Status

    private var statusCard: some View {
        Card {
            SectionLabel("Status")
            HStack {
                Text("Phase").font(.lora(11)).foregroundStyle(.secondary)
                Spacer()
                Text(recruit.phase.rawValue).font(.lora(12, weight: .bold))
            }
            .padding(.top, 4)

            if let committed = recruit.isCommittedToTeamId {
                HStack {
                    Text("Commit").font(.lora(11)).foregroundStyle(.secondary)
                    Spacer()
                    Text(committed).font(.lora(12, weight: .bold))
                        .foregroundStyle(committed == playerTeam?.abbreviation ?
                                          Color(hex: "#15803D") : .primary)
                }
                .padding(.top, 4)
            }

            HStack {
                Text("Scouting").font(.lora(11)).foregroundStyle(.secondary)
                Spacer()
                Text("Tier \(recruit.scoutingTier) of 4")
                    .font(.lora(12, weight: .bold))
            }
            .padding(.top, 4)

            HStack {
                Text("Board").font(.lora(11)).foregroundStyle(.secondary)
                Spacer()
                Button {
                    guard let team = playerTeam else { return }
                    if isOnBoard {
                        engine.removeFromBoard(team: team, recruit: recruit)
                    } else {
                        if !engine.addToBoard(team: team, recruit: recruit) {
                            showBoardFull = true
                        }
                    }
                } label: {
                    Text(isOnBoard ? "Remove" : "Add")
                        .font(.lora(11, weight: .bold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(
                            isOnBoard ? Color(hex: "#B91C1C") :
                                         Color(hex: playerTeam?.primaryColor ?? "#15803D"),
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Attributes

    private var attributeCard: some View {
        Card {
            SectionLabel("Attributes")
            if recruit.revealsAttributes {
                VStack(spacing: 10) {
                    AttributeBar(label: "Speed", value: recruit.speed,
                                 potential: recruit.revealsPotential ? recruit.potential : nil)
                    AttributeBar(label: "Strength", value: recruit.strength,
                                 potential: recruit.revealsPotential ? recruit.potential : nil)
                    AttributeBar(label: "Awareness", value: recruit.awareness,
                                 potential: recruit.revealsPotential ? recruit.potential : nil)
                }
                .padding(.top, 6)
                if recruit.revealsDevTrait {
                    HStack {
                        Text("Dev Trait").font(.lora(11)).foregroundStyle(.secondary)
                        Spacer()
                        Text(recruit.devTrait.rawValue)
                            .font(.lora(12, weight: .bold))
                            .foregroundStyle(Color(hex: "#15803D"))
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Scout this recruit to reveal attributes.")
                    .font(.lora(11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Motivations

    private var motivationsCard: some View {
        Card {
            SectionLabel("Motivations")
            if recruit.scoutingTier >= 1 {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recruit.motivations, id: \.rawValue) { motivation in
                        let grade = playerTeam?.grade(for: motivation) ?? .C
                        HStack {
                            Text(motivation.rawValue).font(.lora(12))
                            Spacer()
                            Text(grade.label)
                                .font(.playfair(14))
                                .foregroundStyle(gradeColor(grade))
                        }
                    }
                }
                .padding(.top, 6)

                if let playerTeam {
                    let fit = RecruitingEngine.motivationFitScore(team: playerTeam, recruit: recruit)
                    HStack {
                        Text("Fit Score")
                            .font(.lora(10, weight: .semibold))
                            .kerning(1.2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(fit) / 39")
                            .font(.lora(12, weight: .bold))
                            .foregroundStyle(fit >= 19 ? Color(hex: "#15803D") : .secondary)
                    }
                    .padding(.top, 8)
                    if fit >= 19 {
                        Text("Full Pitch is +EV (Rule of 19)")
                            .font(.lora(9, weight: .semibold))
                            .foregroundStyle(Color(hex: "#15803D"))
                    } else {
                        Text("Full Pitch is risky — fit too low")
                            .font(.lora(9))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Scout this recruit to reveal motivations.")
                    .font(.lora(11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            if recruit.revealsDealbreaker {
                Divider().padding(.vertical, 8)
                HStack {
                    Text("Dealbreaker").font(.lora(10, weight: .semibold))
                        .kerning(1.2).foregroundStyle(.secondary)
                    Spacer()
                    let threshold = LetterGrade(rawValue: recruit.dealbreakerThreshold) ?? .C
                    Text("\(recruit.dealbreaker.rawValue) ≥ \(threshold.label)")
                        .font(.lora(11, weight: .bold))
                }
            }
        }
    }

    private func gradeColor(_ g: LetterGrade) -> Color {
        if g >= .Aminus { return Color(hex: "#15803D") }
        if g >= .Bminus { return Color(hex: "#1C1917") }
        if g >= .Cminus { return Color(hex: "#B45309") }
        return Color(hex: "#B91C1C")
    }

    // MARK: - Interest

    private var interestCard: some View {
        Card {
            SectionLabel("Interest")
            if let yours = interest {
                HStack {
                    Text("Your interest")
                        .font(.lora(11)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(yours.interestLevel))%")
                        .font(.playfair(18))
                        .foregroundStyle(Color(hex: playerTeam?.primaryColor ?? "#1C1917"))
                }
                InterestBar(value: yours.interestLevel / 100).padding(.vertical, 4)

                HStack(spacing: 8) {
                    if yours.hasOffered {
                        Badge(text: "OFFERED", color: .white, bg: Color(hex: "#15803D"))
                    }
                    if yours.visitWeek != nil {
                        Badge(text: "VISIT W\(yours.visitWeek!)", color: .white, bg: Color(hex: "#B45309"))
                    }
                    Badge(text: slotLabel(yours.topSlot),
                          color: Color(hex: "#1C1917"), bg: Color(hex: "#F5F3F0"))
                }
                .padding(.top, 4)
            } else {
                Text("Not on your board.")
                    .font(.lora(11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            if recruit.interests.count > 1 {
                Divider().padding(.vertical, 8)
                Text("Top Competitors")
                    .font(.lora(10, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)

                let top = recruit.interests
                    .filter { $0.team !== playerTeam }
                    .sorted { $0.interestLevel > $1.interestLevel }
                    .prefix(3)
                ForEach(Array(top), id: \.persistentModelID) { comp in
                    HStack {
                        Text(comp.team?.abbreviation ?? "—")
                            .font(.lora(12, weight: .bold))
                        Spacer()
                        Text("\(Int(comp.interestLevel))%")
                            .font(.lora(11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        InterestBar(value: comp.interestLevel / 100).frame(width: 80)
                    }
                    .padding(.vertical, 2)
                }
            }

            if let msg = lastMessage {
                Divider().padding(.vertical, 8)
                Text(msg)
                    .font(.lora(10, weight: .semibold))
                    .foregroundStyle(lastDelta >= 0 ? Color(hex: "#15803D") : Color(hex: "#B91C1C"))
            }
        }
    }

    private func slotLabel(_ slot: TopListSlot) -> String {
        switch slot {
        case .notOnList: return "OFF LIST"
        case .top10:     return "TOP 10"
        case .top8:      return "TOP 8"
        case .top5:      return "TOP 5"
        case .top3:      return "TOP 3"
        case .leader:    return "LEADER"
        }
    }

    // MARK: - Actions

    private var actionsCard: some View {
        Card {
            SectionLabel("Actions")
            Text("Week hours: \(season?.recruitingHoursRemaining ?? 0)")
                .font(.lora(10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(RecruitingAction.allCases, id: \.self) { action in
                    actionButton(action)
                }
            }
        }
    }

    private func actionButton(_ action: RecruitingAction) -> some View {
        let disabled: Bool = {
            guard let season else { return true }
            if season.recruitingHoursRemaining < action.hourCost { return true }
            if let i = interest, action.requiresTop5 {
                if i.topSlot.rawValue == 0 || i.topSlot.rawValue > 5 { return true }
            } else if interest == nil && action.requiresTop5 { return true }
            return false
        }()

        return Button {
            performAction(action)
        } label: {
            VStack(spacing: 2) {
                Text(action.rawValue)
                    .font(.lora(11, weight: .bold))
                Text("\(action.hourCost) hrs")
                    .font(.lora(9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Color(hex: playerTeam?.primaryColor ?? "#1C1917").opacity(disabled ? 0.1 : 0.08),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#E7E5E4"), lineWidth: 1)
            )
            .foregroundStyle(disabled ? .secondary : Color(hex: playerTeam?.primaryColor ?? "#1C1917"))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func performAction(_ action: RecruitingAction) {
        guard let team = playerTeam, let season else { return }
        let result = engine.perform(action: action, team: team, recruit: recruit, season: season)
        switch result {
        case .ok(let delta, let msg):
            lastDelta = delta
            lastMessage = "\(action.rawValue): \(msg)"
        case .insufficientHours:
            lastDelta = 0
            lastMessage = "Not enough hours."
        case .gated(let reason):
            lastDelta = 0
            lastMessage = reason
        case .dealbreakerBlocked:
            lastDelta = -1
            lastMessage = "Dealbreaker: \(recruit.dealbreaker.rawValue) grade too low."
        }
    }
}
