import Foundation
import SwiftData

/// Computes and seeds each team's 14 LegacyCategory grades.
/// Grades are recomputed weekly/season-end for dynamic categories.
enum SchoolGradeEngine {

    /// Seed initial grades for every team.
    static func seedAll(teams: [Team], context: ModelContext) {
        for team in teams {
            seed(for: team, context: context)
        }
    }

    static func seed(for team: Team, context: ModelContext) {
        // Wipe existing grades first so reseeding is idempotent.
        for g in team.schoolGrades { context.delete(g) }
        for cat in LegacyCategory.allCases {
            let numeric = compute(team: team, category: cat)
            let grade = SchoolGrade(team: team, category: cat,
                                    grade: LetterGrade.from(numeric: numeric))
            context.insert(grade)
        }
    }

    /// Update only the dynamic grades for a team (called weekly).
    static func refreshDynamic(for team: Team, allTeams: [Team], context: ModelContext) {
        for cat in LegacyCategory.allCases where cat.isDynamic {
            let numeric = compute(team: team, category: cat)
            if let existing = team.schoolGrades.first(where: { $0.category == cat }) {
                existing.numeric = numeric
            } else {
                let grade = SchoolGrade(team: team, category: cat,
                                        grade: LetterGrade.from(numeric: numeric))
                context.insert(grade)
            }
        }
    }

    // MARK: - Computation

    /// Returns a numeric grade (1 = F … 13 = A+).
    private static func compute(team: Team, category: LegacyCategory) -> Int {
        switch category {
        case .playingTime:
            // Thin roster at top positions → better Playing Time grade.
            let qbCount = team.players.filter { $0.position == .QB }.count
            let base = qbCount <= 2 ? 9 : (qbCount <= 3 ? 7 : 5)
            return base + legacyBump(team.legacy, scale: 1)

        case .playingStyle:
            // Proxy via offense rating + defense rating balance.
            let off = Int(team.offenseRating / 10)
            return 3 + off  // 3–12

        case .titleContender:
            return scaledByLegacy(team.legacy, min: 2, max: 13)

        case .tradition:
            return scaledByLegacy(team.legacy, min: 3, max: 13)

        case .campusLife:
            // Static — seed modestly around team legacy.
            return 5 + Int(Double(team.legacy) / 100.0 * 5)

        case .gameDay:
            // Big programs pack stadiums.
            return scaledByLegacy(team.legacy, min: 4, max: 13)

        case .nflTrack:
            return scaledByLegacy(team.legacy, min: 2, max: 13)

        case .nationalSpotlight:
            // Power conferences tilt higher by default.
            let conf = team.conference?.name ?? ""
            let confBump = ["SEC", "Big Ten", "Big 12", "ACC"].contains(conf) ? 3 : 0
            return scaledByLegacy(team.legacy, min: 1, max: 10) + confBump

        case .academics:
            // Static-ish; academic names handled as a small whitelist.
            let elite: Set<String> = ["Notre Dame", "Stanford", "Northwestern", "Vanderbilt",
                                      "Duke", "Rice", "Wake Forest", "Virginia", "Michigan",
                                      "UCLA", "California", "North Carolina"]
            return elite.contains(team.name) ? 12 : 7 + (team.legacy > 80 ? 2 : 0)

        case .conferenceStrength:
            let conf = team.conference?.name ?? ""
            switch conf {
            case "SEC": return 13
            case "Big Ten": return 12
            case "Big 12": return 11
            case "ACC": return 10
            case "Pac-12": return 10
            case "Independents": return 7
            default: return 6
            }

        case .coachReputation:
            return scaledByLegacy(team.legacy, min: 4, max: 13)

        case .coachStability:
            // No tenure data yet — seed mid and let engine update later.
            return 8

        case .facilities:
            return scaledByLegacy(team.legacy, min: 4, max: 13)

        case .proximity:
            // Per-team baseline; recruit-specific bonus applied at interest time.
            return 7
        }
    }

    private static func scaledByLegacy(_ legacy: Int, min minG: Int, max maxG: Int) -> Int {
        let pct = Double(max(0, min(100, legacy))) / 100.0
        return minG + Int((Double(maxG - minG) * pct).rounded())
    }

    private static func legacyBump(_ legacy: Int, scale: Int) -> Int {
        if legacy >= 90 { return 3 * scale }
        if legacy >= 80 { return 2 * scale }
        if legacy >= 70 { return 1 * scale }
        return 0
    }
}
