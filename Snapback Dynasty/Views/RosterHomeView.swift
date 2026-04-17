import SwiftUI
import SwiftData

struct RosterHomeView: View {
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var allTeams: [Team]

    enum Segment: String, CaseIterable { case roster = "Roster", recruiting = "Recruiting", portal = "Portal" }
    @State private var segment: Segment = .roster

    private var team: Team? { allTeams.first { $0.name == playerTeamName } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    switch segment {
                    case .roster:
                        if let team { RosterView(team: team) }
                        else { Text("No team selected").foregroundStyle(.secondary) }
                    case .recruiting:
                        RecruitBoardView()
                    case .portal:
                        TransferPortalView()
                    }
                }
            }
            .navigationTitle(segment.rawValue)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
