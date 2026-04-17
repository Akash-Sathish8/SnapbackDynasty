import Foundation
import SwiftData

@Model
final class Conference {
    var name: String
    var fullName: String
    @Relationship(deleteRule: .cascade, inverse: \Team.conference)
    var teams: [Team] = []

    init(name: String, fullName: String) {
        self.name = name
        self.fullName = fullName
    }
}
