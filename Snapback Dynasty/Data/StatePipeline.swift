import Foundation

/// Map a recruit's home state to a regional pipeline. Hotbeds are
/// subdivided probabilistically.
enum StatePipeline {
    /// Weighted state pool for recruit generation. Totals to 100%.
    static let stateWeights: [(state: String, weight: Double)] = [
        ("FL", 12), ("TX", 14), ("CA", 9), ("GA", 8),
        ("OH", 6), ("AL", 5), ("LA", 4), ("PA", 4),
        ("NC", 3), ("SC", 3), ("VA", 3), ("MI", 3),
        ("TN", 2), ("MS", 2), ("IL", 2), ("NJ", 2),
        ("MD", 2), ("IN", 2), ("MO", 1), ("KY", 1),
        ("AR", 1), ("OK", 2), ("CO", 1), ("AZ", 1),
        ("NV", 1), ("UT", 1), ("OR", 1), ("WA", 1),
        ("MN", 1), ("IA", 1), ("WI", 1), ("NE", 1),
        ("KS", 1), ("NY", 1), ("MA", 0.5), ("CT", 0.5),
    ]

    static func randomState() -> String {
        let total = stateWeights.reduce(0) { $0 + $1.weight }
        var r = Double.random(in: 0..<total)
        for entry in stateWeights {
            if r < entry.weight { return entry.state }
            r -= entry.weight
        }
        return "TX"
    }

    static func pipeline(for state: String) -> Pipeline {
        switch state {
        case "FL":
            return [Pipeline.flNorth, .flCentral, .flSouth].randomElement()!
        case "TX":
            return [Pipeline.txEast, .txCentral, .txWest].randomElement()!
        case "CA":
            return [Pipeline.caNorth, .caSouth].randomElement()!
        case "GA":
            return Double.random(in: 0..<1) < 0.65 ? .gaAtlanta : .gaRest
        case "AL": return .alabama
        case "LA": return .louisiana
        case "MS": return .mississippi
        case "TN": return .tennessee
        case "KY": return .kentucky
        case "NC": return .carolinaN
        case "SC": return .carolinaS
        case "VA": return .virginia
        case "WV": return .westVirginia
        case "AR": return .arkansas
        case "OH": return .ohio
        case "MI": return .michigan
        case "IN": return .indiana
        case "IL": return .illinois
        case "WI": return .wisconsin
        case "MN": return .minnesota
        case "IA": return .iowa
        case "MO": return .missouri
        case "KS": return .kansas
        case "NE": return .nebraska
        case "PA": return .pennsylvania
        case "NY": return .newYork
        case "NJ": return .newJersey
        case "MD": return .maryland
        case "MA": return .massachusetts
        case "CT": return .connecticut
        case "CO": return .colorado
        case "UT": return .utah
        case "AZ": return .arizona
        case "NM": return .newMexico
        case "NV": return .nevada
        case "OR": return .oregon
        case "WA": return .washington
        case "OK": return .oklahoma
        case "HI": return .hawaii
        default:   return .gaRest
        }
    }
}
