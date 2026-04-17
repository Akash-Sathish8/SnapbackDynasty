import SwiftUI
import SwiftData

struct RecruitBoardView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var recruits: [Recruit]
    @Query private var allTeams: [Team]
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]

    enum Filter: String, CaseIterable { case onBoard = "Board", pool = "Pool", committed = "Commits" }
    enum Sort: String, CaseIterable { case stars = "★", interest = "Interest", overall = "OVR", position = "Pos" }

    @State private var filter: Filter = .onBoard
    @State private var sort: Sort = .interest
    @State private var positionFilter: Position? = nil
    @State private var searchText = ""

    private var playerTeam: Team? { allTeams.first { $0.name == playerTeamName } }
    private var season: Season? { seasons.first }

    private var boardInterests: [RecruitInterest] {
        playerTeam?.recruitInterests ?? []
    }

    private var displayed: [Recruit] {
        let pool: [Recruit] = {
            switch filter {
            case .onBoard:
                return boardInterests.compactMap { $0.recruit }
            case .pool:
                return recruits.filter { !$0.isSigned && $0.isCommittedToTeamId == nil }
            case .committed:
                return recruits.filter { $0.isCommittedToTeamId != nil }
            }
        }()

        let filtered = pool.filter { r in
            let posMatch = positionFilter == nil || r.position == positionFilter
            let searchMatch = searchText.isEmpty ||
                r.fullName.localizedCaseInsensitiveContains(searchText) ||
                r.homeState.localizedCaseInsensitiveContains(searchText)
            return posMatch && searchMatch
        }

        let sorted = filtered.sorted { a, b in
            switch sort {
            case .stars:    return a.stars > b.stars
            case .overall:  return a.overall > b.overall
            case .position: return a.positionRaw < b.positionRaw
            case .interest:
                guard let team = playerTeam else { return a.stars > b.stars }
                let ai = team.recruitInterests.first { $0.recruit === a }?.interestLevel ?? 0
                let bi = team.recruitInterests.first { $0.recruit === b }?.interestLevel ?? 0
                if ai != bi { return ai > bi }
                return a.stars > b.stars
            }
        }
        return Array(sorted.prefix(250))  // cap rendering
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerCard
                filterBar
                listCard
            }
            .padding(16)
        }
        .background(Color(hex: "#FAF8F4"))
        .searchable(text: $searchText, prompt: "Search recruits")
        .onAppear(perform: bootstrapHoursIfNeeded)
    }

    // MARK: - Sections

    private var headerCard: some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel("Class of \(String((season?.year ?? 2026) + 1))")
                    Text("\(recruits.count) prospects • \(boardInterests.count)/\(RecruitingEngine.boardCap) on board")
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(season?.recruitingHoursRemaining ?? 0)")
                        .font(.playfair(22))
                        .foregroundStyle(Color(hex: playerTeam?.primaryColor ?? "#B45309"))
                    Text("HOURS")
                        .font(.lora(8, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            Picker("Filter", selection: $filter) {
                ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Picker("Sort", selection: $sort) {
                    ForEach(Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)

                Menu {
                    Button("All") { positionFilter = nil }
                    ForEach(Position.allCases, id: \.rawValue) { pos in
                        Button(pos.rawValue) { positionFilter = pos }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(positionFilter?.rawValue ?? "All")
                            .font(.lora(11, weight: .bold))
                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(hex: "#F5F3F0"), in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(Color(hex: "#1C1917"))
                }
            }
        }
    }

    private var listCard: some View {
        VStack(spacing: 0) {
            if displayed.isEmpty {
                Card {
                    Text(emptyMessage)
                        .font(.lora(12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            } else {
                ForEach(displayed, id: \.persistentModelID) { recruit in
                    NavigationLink {
                        RecruitDetailView(recruit: recruit)
                    } label: {
                        row(recruit: recruit)
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color(hex: "#F5F3F0"))
                }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    private var emptyMessage: String {
        switch filter {
        case .onBoard:   return "No prospects on board yet. Tap Pool to add up to 35."
        case .pool:      return "No prospects match your filters."
        case .committed: return "No commits yet this cycle."
        }
    }

    // MARK: - Row

    private func row(recruit: Recruit) -> some View {
        let interest = playerTeam.flatMap { team in
            team.recruitInterests.first { $0.recruit === recruit }
        }
        let revealOverall = recruit.revealsOverall
        return HStack(spacing: 10) {
            PositionBadge(position: recruit.positionRaw, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(recruit.fullName)
                        .font(.lora(12, weight: .bold))
                        .foregroundStyle(Color(hex: "#1C1917"))
                    if recruit.gemTag == .gem {
                        Text("GEM").font(.lora(8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color(hex: "#15803D"), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(.white)
                    } else if recruit.gemTag == .overrated && recruit.scoutingTier >= 1 {
                        Text("BUST").font(.lora(8, weight: .bold))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color(hex: "#B91C1C"), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 6) {
                    StarRating(stars: recruit.stars, size: 9)
                    Text("• \(recruit.homeState) • \(recruit.archetype)")
                        .font(.lora(9))
                        .foregroundStyle(.secondary)
                }
                if let interest {
                    HStack(spacing: 6) {
                        InterestBar(value: interest.interestLevel / 100).frame(width: 80)
                        Text("\(Int(interest.interestLevel))%")
                            .font(.lora(9, weight: .semibold))
                            .foregroundStyle(.secondary)
                        if let committed = recruit.isCommittedToTeamId {
                            Text(committed == playerTeam?.abbreviation ? "COMMITTED TO YOU" : "COMMITTED: \(committed)")
                                .font(.lora(8, weight: .bold))
                                .kerning(0.5)
                                .foregroundStyle(committed == playerTeam?.abbreviation ? Color(hex: "#15803D") : .secondary)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(revealOverall ? "\(recruit.overall)" : "??")
                    .font(.playfair(18))
                    .foregroundStyle(Color(hex: playerTeam?.primaryColor ?? "#1C1917"))
                if recruit.revealsPotential {
                    Text("POT \(recruit.potential)")
                        .font(.lora(8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 44)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Bootstrap

    private func bootstrapHoursIfNeeded() {
        guard let season, let team = playerTeam else { return }
        if season.recruitingHoursRemaining == 0 && season.currentWeek == 0 {
            season.recruitingHoursRemaining = RecruitingEngine.weeklyHours(
                for: team, staff: team.coachingStaff)
        }
    }
}
