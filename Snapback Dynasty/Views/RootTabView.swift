import SwiftUI
import SwiftData

struct RootTabView: View {
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var allTeams: [Team]

    private var playerTeam: Team? { allTeams.first { $0.name == playerTeamName } }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            RosterHomeView()
                .tabItem { Label("Roster", systemImage: "person.3.fill") }

            SeasonHomeView()
                .tabItem { Label("Season", systemImage: "calendar") }

            DynastyHomeView()
                .tabItem { Label("Dynasty", systemImage: "trophy.fill") }
        }
        .tint(playerTeam.map { Color(hex: $0.primaryColor) } ?? .accentColor)
    }
}
