import Foundation
import SwiftData

/// A team's grade in one of the 14 LegacyCategory dimensions.
/// Grades change dynamically for most categories (see LegacyCategory.isDynamic).
@Model
final class SchoolGrade {
    var team: Team?
    var categoryRaw: String
    var numeric: Int  // 1 (F) … 13 (A+)

    init(team: Team, category: LegacyCategory, grade: LetterGrade) {
        self.team = team
        self.categoryRaw = category.rawValue
        self.numeric = grade.rawValue
    }

    var category: LegacyCategory {
        LegacyCategory(rawValue: categoryRaw) ?? .playingTime
    }

    var letter: LetterGrade { LetterGrade.from(numeric: numeric) }
}
