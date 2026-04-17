import SwiftUI

@Observable
final class ThemeManager {
    var theme: Theme = .fallback

    func update(for team: Team?) {
        guard let team else {
            theme = .fallback
            return
        }
        theme = .from(primaryHex: team.primaryColor)
    }
}
