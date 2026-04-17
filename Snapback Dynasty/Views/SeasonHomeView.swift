import SwiftUI
import SwiftData

struct SeasonHomeView: View {
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var allTeams: [Team]
    @Query(filter: #Predicate<Season> { $0.isActive }) private var seasons: [Season]

    enum Segment: String, CaseIterable { case schedule = "Schedule", rankings = "Rankings", standings = "Standings" }
    @State private var segment: Segment = .schedule

    private var team: Team? { allTeams.first { $0.name == playerTeamName } }
    private var season: Season? { seasons.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    switch segment {
                    case .schedule:
                        if let team, let season { ScheduleView(team: team, season: season) }
                        else { Text("Loading…").foregroundStyle(.secondary) }
                    case .rankings:
                        RankingsView()
                    case .standings:
                        StandingsView()
                    }
                }
            }
            .navigationTitle(segment.rawValue)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
