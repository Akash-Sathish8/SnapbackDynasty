import SwiftUI
import SwiftData

@main
struct SnapbackDynastyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Team.self,
            Conference.self,
            Player.self,
            Season.self,
            Game.self,
            CoachingStaff.self,
            Recruit.self,
            RecruitInterest.self,
            SchoolGrade.self,
            PlayerGameStats.self,
            PlayerSeasonStats.self,
            DynastyHistory.self,
            Award.self,
            TransferEntry.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
