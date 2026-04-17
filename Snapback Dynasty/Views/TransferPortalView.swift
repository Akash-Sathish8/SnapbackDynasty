import SwiftUI
import SwiftData

struct TransferPortalView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var allTeams: [Team]
    @Query private var allEntries: [TransferEntry]
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]

    @State private var tab: Tab = .retain
    @State private var positionFilter: Position? = nil
    @State private var actionMessage: String? = nil

    enum Tab: String, CaseIterable {
        case retain = "Retain"
        case recruit = "Recruit"
        case history = "History"
    }

    private var playerTeam: Team? { allTeams.first { $0.name == playerTeamName } }
    private var season: Season? { seasons.first }
    private var primary: Color { Color(hex: playerTeam?.primaryColor ?? "#B45309") }

    private var currentYear: Int { season?.year ?? 2026 }

    private var myPortalPlayers: [TransferEntry] {
        allEntries.filter {
            $0.seasonYear == currentYear &&
            $0.fromTeam?.name == playerTeamName &&
            $0.status == .available
        }.sorted { $0.overallAtEntry > $1.overallAtEntry }
    }

    private var availableToRecruit: [TransferEntry] {
        allEntries.filter { entry in
            entry.seasonYear == currentYear &&
            entry.fromTeam?.name != playerTeamName &&
            entry.status == .available &&
            (positionFilter == nil || entry.position == positionFilter)
        }.sorted { $0.overallAtEntry > $1.overallAtEntry }
    }

    private var boardEntries: [TransferEntry] {
        allEntries.filter { $0.isOnPlayerBoard && $0.seasonYear == currentYear }
    }

    private var historyEntries: [TransferEntry] {
        allEntries.filter { $0.seasonYear < currentYear }
            .sorted { $0.seasonYear > $1.seasonYear }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerCard
                tabPicker
                ScrollView {
                    VStack(spacing: 0) {
                        switch tab {
                        case .retain:  retainTab
                        case .recruit: recruitTab
                        case .history: historyTab
                        }
                    }
                    .padding(16)
                }
                if tab == .retain || tab == .recruit {
                    closePortalButton
                }
            }
            .background(Color(hex: "#FAF8F4"))
            .navigationTitle("Transfer Portal")
            .navigationBarTitleDisplayMode(.inline)
        }
        .overlay(alignment: .bottom) {
            if let msg = actionMessage {
                Text(msg)
                    .font(.lora(12, weight: .semibold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color(hex: "#1C1917"), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { actionMessage = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SectionLabel("Transfer Portal")
                    Text("Season \(currentYear) window")
                        .font(.lora(11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    statChip(label: "RETAIN", value: "\(season?.portalRetentionOffersRemaining ?? 0)")
                    statChip(label: "HOURS", value: "\(season?.portalHoursRemaining ?? 0)")
                    statChip(label: "BOARD", value: "\(boardEntries.count)/\(RecruitingConfig.Portal.portalBoardCap)")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func statChip(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.playfair(16)).foregroundStyle(primary)
            Text(label).font(.lora(7, weight: .semibold)).kerning(0.8).foregroundStyle(.secondary)
        }
    }

    // MARK: - Tab picker

    private var tabPicker: some View {
        Picker("Tab", selection: $tab) {
            ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Retain tab

    @ViewBuilder
    private var retainTab: some View {
        if myPortalPlayers.isEmpty {
            emptyCard("None of your players entered the portal.")
        } else {
            VStack(spacing: 0) {
                ForEach(myPortalPlayers, id: \.persistentModelID) { entry in
                    retainRow(entry: entry)
                    Divider().background(Color(hex: "#F5F3F0"))
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
        }
    }

    private func retainRow(entry: TransferEntry) -> some View {
        HStack(spacing: 10) {
            PositionBadge(position: entry.positionRaw, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fullName).font(.lora(12, weight: .bold))
                HStack(spacing: 4) {
                    StarRating(stars: entry.starsAtEntry, size: 9)
                    Text("• \(entry.position.rawValue)").font(.lora(9)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(entry.overallAtEntry)").font(.playfair(18)).foregroundStyle(primary)
            Button {
                guard let team = playerTeam, let s = season else { return }
                let kept = TransferPortalEngine.retain(entry: entry, playerTeam: team, season: s)
                withAnimation { actionMessage = kept ? "✓ Retained \(entry.fullName)" : "\(entry.firstName) chose to transfer" }
                try? context.save()
            } label: {
                Text("Retain")
                    .font(.lora(10, weight: .bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(
                        (season?.portalRetentionOffersRemaining ?? 0) > 0 ? primary : Color(hex: "#E7E5E4"),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .foregroundStyle(
                        (season?.portalRetentionOffersRemaining ?? 0) > 0
                            ? (isLightHex(playerTeam?.primaryColor ?? "#B45309") ? Color.black : Color.white)
                            : Color(hex: "#78716C")
                    )
            }
            .buttonStyle(.plain)
            .disabled((season?.portalRetentionOffersRemaining ?? 0) <= 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - Recruit tab

    @ViewBuilder
    private var recruitTab: some View {
        VStack(spacing: 10) {
            positionFilterBar
            if availableToRecruit.isEmpty && boardEntries.filter({ $0.fromTeam?.name != playerTeamName }).isEmpty {
                emptyCard("No available transfers match your filters.")
            } else {
                if !boardEntries.filter({ $0.fromTeam?.name != playerTeamName }).isEmpty {
                    Card {
                        SectionLabel("On Your Board")
                        ForEach(boardEntries.filter { $0.fromTeam?.name != playerTeamName },
                                id: \.persistentModelID) { entry in
                            recruitBoardRow(entry: entry)
                            Divider().background(Color(hex: "#F5F3F0"))
                        }
                    }
                }
                VStack(spacing: 0) {
                    ForEach(availableToRecruit.prefix(100), id: \.persistentModelID) { entry in
                        recruitPoolRow(entry: entry)
                        Divider().background(Color(hex: "#F5F3F0"))
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
            }
        }
    }

    private var positionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", selected: positionFilter == nil) { positionFilter = nil }
                ForEach(Position.allCases, id: \.rawValue) { pos in
                    filterChip(label: pos.rawValue, selected: positionFilter == pos) {
                        positionFilter = positionFilter == pos ? nil : pos
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.lora(10, weight: .bold))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(selected ? primary : Color(hex: "#F5F3F0"),
                            in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(selected
                    ? (isLightHex(playerTeam?.primaryColor ?? "#B45309") ? Color.black : Color.white)
                    : Color(hex: "#1C1917"))
        }
        .buttonStyle(.plain)
    }

    private func recruitPoolRow(entry: TransferEntry) -> some View {
        HStack(spacing: 10) {
            PositionBadge(position: entry.positionRaw, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fullName).font(.lora(12, weight: .bold))
                HStack(spacing: 4) {
                    StarRating(stars: entry.starsAtEntry, size: 9)
                    Text("• \(entry.fromTeam?.abbreviation ?? "?")").font(.lora(9)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(entry.overallAtEntry)").font(.playfair(18)).foregroundStyle(primary)
            Button {
                guard let entries = try? context.fetch(FetchDescriptor<TransferEntry>()),
                      let team = playerTeam else { return }
                let added = TransferPortalEngine.addToBoard(entry: entry, playerTeam: team, allEntries: entries)
                withAnimation { actionMessage = added ? "Added \(entry.firstName) to board" : "Board full (15 max)" }
                try? context.save()
            } label: {
                Text(entry.isOnPlayerBoard ? "On Board" : "+ Board")
                    .font(.lora(10, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(entry.isOnPlayerBoard ? Color(hex: "#F5F3F0") : primary,
                                in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(entry.isOnPlayerBoard ? Color(hex: "#78716C")
                        : (isLightHex(playerTeam?.primaryColor ?? "#B45309") ? Color.black : Color.white))
            }
            .buttonStyle(.plain)
            .disabled(entry.isOnPlayerBoard)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private func recruitBoardRow(entry: TransferEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                PositionBadge(position: entry.positionRaw, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.fullName).font(.lora(12, weight: .bold))
                    Text("from \(entry.fromTeam?.name ?? "?") • OVR \(entry.overallAtEntry)")
                        .font(.lora(9)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(entry.portalInterestLevel))%").font(.playfair(16)).foregroundStyle(primary)
            }
            InterestBar(value: entry.portalInterestLevel / 100).frame(height: 4)
            HStack(spacing: 8) {
                portalActionButton(label: "DM", cost: "10h") {
                    guard let s = season else { return }
                    let r = TransferPortalEngine.dm(entry: entry, season: s)
                    if case .ok(_, let msg) = r { withAnimation { actionMessage = msg } }
                    else if case .insufficientHours = r { withAnimation { actionMessage = "Not enough hours" } }
                    try? context.save()
                }
                portalActionButton(label: "All In", cost: "50h") {
                    guard let s = season else { return }
                    let r = TransferPortalEngine.allIn(entry: entry, season: s)
                    if case .ok(_, let msg) = r { withAnimation { actionMessage = msg } }
                    else if case .insufficientHours = r { withAnimation { actionMessage = "Not enough hours" } }
                    try? context.save()
                }
                portalActionButton(label: "Offer", cost: "5h", accent: true) {
                    guard let team = playerTeam, let s = season else { return }
                    let r = TransferPortalEngine.offer(entry: entry, playerTeam: team,
                                                       allTeams: allTeams, season: s)
                    switch r {
                    case .ok(_, let msg): withAnimation { actionMessage = msg }
                    case .gated(let reason): withAnimation { actionMessage = reason }
                    case .insufficientHours: withAnimation { actionMessage = "Not enough hours" }
                    case .dealbreakerBlocked: break
                    }
                    try? context.save()
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private func portalActionButton(label: String, cost: String,
                                     accent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(label).font(.lora(10, weight: .bold))
                Text(cost).font(.lora(8)).opacity(0.7)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(accent ? primary : Color(hex: "#F5F3F0"),
                        in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(accent
                ? (isLightHex(playerTeam?.primaryColor ?? "#B45309") ? Color.black : Color.white)
                : Color(hex: "#1C1917"))
        }
        .buttonStyle(.plain)
    }

    // MARK: - History tab

    @ViewBuilder
    private var historyTab: some View {
        if historyEntries.isEmpty {
            emptyCard("No portal history yet.")
        } else {
            VStack(spacing: 0) {
                ForEach(historyEntries.prefix(200), id: \.persistentModelID) { entry in
                    historyRow(entry: entry)
                    Divider().background(Color(hex: "#F5F3F0"))
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E7E5E4"), lineWidth: 1))
        }
    }

    private func historyRow(entry: TransferEntry) -> some View {
        HStack(spacing: 10) {
            PositionBadge(position: entry.positionRaw, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fullName).font(.lora(11, weight: .bold))
                Text("\(entry.fromTeam?.abbreviation ?? "?") → \(entry.toTeam?.abbreviation ?? "—")")
                    .font(.lora(9)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(entry.status.rawValue)
                    .font(.lora(9, weight: .semibold))
                    .foregroundStyle(entry.status == .retained ? Color(hex: "#15803D") : .secondary)
                Text("'\(String(entry.seasonYear).suffix(2))")
                    .font(.lora(8)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    // MARK: - Close portal button

    private var closePortalButton: some View {
        Button {
            guard let s = season else { return }
            OffseasonManager.runOffseasonPhaseB(
                currentSeason: s,
                allTeams: allTeams,
                playerTeam: playerTeam,
                context: context
            )
        } label: {
            Text("Close Portal & Advance Season →")
                .font(.lora(13, weight: .bold))
                .kerning(0.3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(primary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(isLightHex(playerTeam?.primaryColor ?? "#B45309") ? .black : .white)
        }
        .buttonStyle(.plain)
        .padding(16)
    }

    // MARK: - Helpers

    private func emptyCard(_ message: String) -> some View {
        Card {
            Text(message)
                .font(.lora(12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
    }
}
