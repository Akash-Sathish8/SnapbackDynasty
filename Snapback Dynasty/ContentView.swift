import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("playerTeamName") private var playerTeamName: String = ""
    @Query private var teams: [Team]

    var body: some View {
        if playerTeamName.isEmpty || teams.isEmpty {
            TeamPickerView()
        } else {
            RootTabView()
        }
    }
}
