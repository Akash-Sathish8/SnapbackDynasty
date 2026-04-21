import Foundation

/// Offensive formations. Each defines player positions relative to ball (center of OL).
/// X offsets: negative = left, positive = right.
/// Y offsets: positive = toward line of scrimmage (upfield for offense).
enum Formation: String, CaseIterable, Codable {
    case shotgun    = "Shotgun"
    case iForm      = "I-Form"
    case spread     = "Spread"
    case pistol     = "Pistol"
    case singleback = "Singleback"

    /// Offensive player slots. Positions are in field-relative points.
    /// QB is always at (0, -qbDepth). OL is on the line.
    struct Slot {
        let role: SlotRole
        let x: CGFloat
        let y: CGFloat  // relative to LOS; negative = behind LOS
    }

    enum SlotRole: String {
        case qb, rb, rb2, wr1, wr2, wr3, te, ol1, ol2, ol3, ol4, ol5
    }

    var slots: [Slot] {
        let fw: CGFloat = 190  // half field width — matches FieldRenderer.fieldWidth / 2 - 10pt margin
        switch self {
        case .shotgun:
            return [
                Slot(role: .qb,  x: 0,    y: -40),
                Slot(role: .rb,  x: 15,   y: -38),
                Slot(role: .wr1, x: -fw + 10, y: 2),
                Slot(role: .wr2, x: fw - 10,  y: 2),
                Slot(role: .wr3, x: -fw + 40, y: 2),
                Slot(role: .te,  x: fw - 40,  y: 2),
                Slot(role: .ol1, x: -24, y: 0),
                Slot(role: .ol2, x: -12, y: 0),
                Slot(role: .ol3, x: 0,   y: 0),
                Slot(role: .ol4, x: 12,  y: 0),
                Slot(role: .ol5, x: 24,  y: 0),
            ]
        case .iForm:
            return [
                Slot(role: .qb,  x: 0,    y: -14),
                Slot(role: .rb,  x: 0,    y: -36),
                Slot(role: .rb2, x: 0,    y: -24),
                Slot(role: .wr1, x: -fw + 10, y: 2),
                Slot(role: .wr2, x: fw - 10,  y: 2),
                Slot(role: .te,  x: fw - 40,  y: 2),
                Slot(role: .ol1, x: -24, y: 0),
                Slot(role: .ol2, x: -12, y: 0),
                Slot(role: .ol3, x: 0,   y: 0),
                Slot(role: .ol4, x: 12,  y: 0),
                Slot(role: .ol5, x: 24,  y: 0),
            ]
        case .spread:
            return [
                Slot(role: .qb,  x: 0,    y: -40),
                Slot(role: .rb,  x: -15,  y: -38),
                Slot(role: .wr1, x: -fw + 10, y: 2),
                Slot(role: .wr2, x: fw - 10,  y: 2),
                Slot(role: .wr3, x: -fw + 40, y: 2),
                Slot(role: .te,  x: fw - 40,  y: 2),
                Slot(role: .ol1, x: -24, y: 0),
                Slot(role: .ol2, x: -12, y: 0),
                Slot(role: .ol3, x: 0,   y: 0),
                Slot(role: .ol4, x: 12,  y: 0),
                Slot(role: .ol5, x: 24,  y: 0),
            ]
        case .pistol:
            return [
                Slot(role: .qb,  x: 0,    y: -20),
                Slot(role: .rb,  x: 0,    y: -38),
                Slot(role: .wr1, x: -fw + 10, y: 2),
                Slot(role: .wr2, x: fw - 10,  y: 2),
                Slot(role: .wr3, x: -fw + 40, y: 2),
                Slot(role: .te,  x: fw - 40,  y: 2),
                Slot(role: .ol1, x: -24, y: 0),
                Slot(role: .ol2, x: -12, y: 0),
                Slot(role: .ol3, x: 0,   y: 0),
                Slot(role: .ol4, x: 12,  y: 0),
                Slot(role: .ol5, x: 24,  y: 0),
            ]
        case .singleback:
            return [
                Slot(role: .qb,  x: 0,    y: -14),
                Slot(role: .rb,  x: 0,    y: -30),
                Slot(role: .wr1, x: -fw + 10, y: 2),
                Slot(role: .wr2, x: fw - 10,  y: 2),
                Slot(role: .wr3, x: -fw + 40, y: 2),
                Slot(role: .te,  x: fw - 40,  y: 2),
                Slot(role: .ol1, x: -24, y: 0),
                Slot(role: .ol2, x: -12, y: 0),
                Slot(role: .ol3, x: 0,   y: 0),
                Slot(role: .ol4, x: 12,  y: 0),
                Slot(role: .ol5, x: 24,  y: 0),
            ]
        }
    }
}
