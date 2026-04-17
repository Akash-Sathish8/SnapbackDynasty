import Foundation

/// 50 recruiting pipelines. Hotbeds (FL, TX, CA, GA) are subdivided.
enum Pipeline: String, Codable, CaseIterable {
    // Florida (3)
    case flNorth = "FL-N", flCentral = "FL-C", flSouth = "FL-S"
    // Texas (3)
    case txEast = "TX-E", txCentral = "TX-C", txWest = "TX-W"
    // California (2)
    case caNorth = "CA-N", caSouth = "CA-S"
    // Georgia (2 — Atlanta metro is its own)
    case gaAtlanta = "GA-ATL", gaRest = "GA"
    // Southeast
    case alabama = "AL", louisiana = "LA", mississippi = "MS", tennessee = "TN"
    case kentucky = "KY", carolinaN = "NC", carolinaS = "SC", virginia = "VA"
    case westVirginia = "WV", arkansas = "AR"
    // Midwest
    case ohio = "OH", michigan = "MI", indiana = "IN", illinois = "IL"
    case wisconsin = "WI", minnesota = "MN", iowa = "IA", missouri = "MO"
    case kansas = "KS", nebraska = "NE"
    // Northeast
    case pennsylvania = "PA", newYork = "NY", newJersey = "NJ", maryland = "MD"
    case massachusetts = "MA", connecticut = "CT"
    // Mountain / West
    case colorado = "CO", utah = "UT", arizona = "AZ", newMexico = "NM"
    case nevada = "NV", oregon = "OR", washington = "WA", idaho = "ID"
    case montana = "MT", wyoming = "WY"
    // South Central
    case oklahoma = "OK"
    // Gulf
    case mississippi2 = "MS2" // placeholder to reach 50
    // Other
    case hawaii = "HI", dcMetro = "DC"
    case internationalPrep = "INTL"

    var displayName: String {
        switch self {
        case .flNorth: return "Florida North"
        case .flCentral: return "Florida Central"
        case .flSouth: return "Florida South"
        case .txEast: return "East Texas"
        case .txCentral: return "Central Texas"
        case .txWest: return "West Texas"
        case .caNorth: return "Northern California"
        case .caSouth: return "Southern California"
        case .gaAtlanta: return "Atlanta Metro"
        case .gaRest: return "Georgia"
        case .alabama: return "Alabama"
        case .louisiana: return "Louisiana"
        case .mississippi: return "Mississippi"
        case .tennessee: return "Tennessee"
        case .kentucky: return "Kentucky"
        case .carolinaN: return "North Carolina"
        case .carolinaS: return "South Carolina"
        case .virginia: return "Virginia"
        case .westVirginia: return "West Virginia"
        case .arkansas: return "Arkansas"
        case .ohio: return "Ohio"
        case .michigan: return "Michigan"
        case .indiana: return "Indiana"
        case .illinois: return "Illinois"
        case .wisconsin: return "Wisconsin"
        case .minnesota: return "Minnesota"
        case .iowa: return "Iowa"
        case .missouri: return "Missouri"
        case .kansas: return "Kansas"
        case .nebraska: return "Nebraska"
        case .pennsylvania: return "Pennsylvania"
        case .newYork: return "New York"
        case .newJersey: return "New Jersey"
        case .maryland: return "Maryland"
        case .massachusetts: return "New England"
        case .connecticut: return "Connecticut"
        case .colorado: return "Colorado"
        case .utah: return "Utah"
        case .arizona: return "Arizona"
        case .newMexico: return "New Mexico"
        case .nevada: return "Nevada"
        case .oregon: return "Oregon"
        case .washington: return "Washington"
        case .idaho: return "Idaho"
        case .montana: return "Montana"
        case .wyoming: return "Wyoming"
        case .oklahoma: return "Oklahoma"
        case .mississippi2: return "Mississippi Delta"
        case .hawaii: return "Hawaii"
        case .dcMetro: return "DC Metro"
        case .internationalPrep: return "International"
        }
    }
}

/// Team pipeline tier: fixed for the dynasty based on historical strength.
enum PipelineTier: Int, Codable, CaseIterable, Comparable {
    case bronze = 1, silver, gold, blue, pink

    static func < (lhs: PipelineTier, rhs: PipelineTier) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Interest-per-hour multiplier vs a neutral (no pipeline) prospect.
    /// Pink/Blue are the power tiers; Gold/Silver/Bronze are modest.
    var interestMultiplier: Double {
        switch self {
        case .bronze: return 1.05
        case .silver: return 1.10
        case .gold:   return 1.20
        case .blue:   return 1.45
        case .pink:   return 1.75
        }
    }

    var label: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold:   return "Gold"
        case .blue:   return "Blue"
        case .pink:   return "Pink"
        }
    }
}
