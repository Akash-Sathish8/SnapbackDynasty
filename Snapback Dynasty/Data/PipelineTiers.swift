import Foundation

/// Static lookup of a team's tier in each of the 50 pipelines.
/// Keyed by team abbreviation. Missing entries default to .bronze.
///
/// This is a first pass — tiers were seeded by a mix of historical recruiting
/// data and proximity. Tweak freely as we tune the recruiting feel.
enum PipelineTiers {

    /// Core table. Only non-.bronze tiers are listed; everything else defaults.
    static let table: [String: [Pipeline: PipelineTier]] = [
        // --- SEC ---
        "ALA": [.alabama: .pink, .gaAtlanta: .blue, .flNorth: .blue, .flCentral: .gold, .louisiana: .gold, .mississippi: .gold, .tennessee: .silver, .gaRest: .gold],
        "UGA": [.gaAtlanta: .pink, .gaRest: .pink, .flNorth: .blue, .flCentral: .blue, .carolinaS: .gold, .alabama: .silver, .tennessee: .silver],
        "LSU": [.louisiana: .pink, .txEast: .blue, .mississippi: .blue, .alabama: .gold, .flSouth: .silver, .arkansas: .silver],
        "TEN": [.tennessee: .pink, .gaAtlanta: .gold, .kentucky: .gold, .alabama: .silver, .carolinaN: .silver],
        "TAM": [.txEast: .pink, .txCentral: .blue, .louisiana: .blue, .oklahoma: .gold, .arkansas: .gold],
        "FLA": [.flNorth: .pink, .flCentral: .blue, .flSouth: .blue, .gaAtlanta: .gold, .gaRest: .silver],
        "AUB": [.alabama: .blue, .gaAtlanta: .blue, .flNorth: .gold, .louisiana: .silver, .gaRest: .silver],
        "UK":  [.kentucky: .pink, .ohio: .silver, .tennessee: .silver, .virginia: .silver],
        // --- Big Ten ---
        "OSU": [.ohio: .pink, .michigan: .gold, .pennsylvania: .blue, .newJersey: .gold, .maryland: .silver, .flCentral: .silver],
        "MICH": [.michigan: .pink, .ohio: .silver, .indiana: .gold, .pennsylvania: .gold, .flSouth: .silver],
        "PSU": [.pennsylvania: .pink, .newJersey: .blue, .newYork: .gold, .maryland: .gold, .ohio: .silver],
        "WIS": [.wisconsin: .pink, .illinois: .gold, .minnesota: .gold, .iowa: .silver],
        "IOW": [.iowa: .pink, .illinois: .silver, .minnesota: .gold, .missouri: .silver, .nebraska: .silver],
        "MSU": [.michigan: .blue, .ohio: .silver, .indiana: .silver],
        "NEB": [.nebraska: .pink, .iowa: .silver, .kansas: .gold, .colorado: .silver],
        // --- Big 12 ---
        "TEX": [.txCentral: .pink, .txEast: .blue, .txWest: .blue, .oklahoma: .gold, .louisiana: .silver, .arkansas: .silver],
        "OKL": [.oklahoma: .pink, .txEast: .blue, .txCentral: .blue, .kansas: .gold, .arkansas: .silver],
        "OKS": [.oklahoma: .blue, .txEast: .gold, .txCentral: .silver, .kansas: .silver],
        "BAY": [.txCentral: .blue, .txEast: .gold, .oklahoma: .silver],
        "TCU": [.txEast: .pink, .txCentral: .blue, .oklahoma: .gold, .louisiana: .silver],
        // --- ACC ---
        "UNC": [.carolinaN: .pink, .virginia: .gold, .gaAtlanta: .silver, .carolinaS: .gold, .dcMetro: .silver, .maryland: .silver],
        "CLEM": [.carolinaS: .pink, .carolinaN: .blue, .gaAtlanta: .gold, .gaRest: .gold, .flNorth: .silver],
        "FSU": [.flNorth: .pink, .flCentral: .pink, .flSouth: .blue, .gaAtlanta: .gold, .gaRest: .silver, .alabama: .silver],
        "MIA": [.flSouth: .pink, .flCentral: .blue, .flNorth: .gold, .gaAtlanta: .silver],
        "VT":  [.virginia: .pink, .dcMetro: .gold, .carolinaN: .silver, .maryland: .silver, .westVirginia: .silver],
        "NCST": [.carolinaN: .blue, .virginia: .silver, .carolinaS: .silver],
        "LOU": [.kentucky: .blue, .ohio: .silver, .gaAtlanta: .silver, .flCentral: .silver],
        // --- Pac-12 / West ---
        "USC": [.caSouth: .pink, .caNorth: .blue, .nevada: .gold, .arizona: .gold, .hawaii: .silver],
        "UCLA": [.caSouth: .pink, .caNorth: .blue, .arizona: .silver, .hawaii: .silver],
        "UW":  [.washington: .pink, .oregon: .blue, .caNorth: .gold, .idaho: .silver, .hawaii: .silver],
        "ORE": [.oregon: .pink, .washington: .blue, .caNorth: .gold, .caSouth: .gold, .hawaii: .silver],
        "UTAH": [.utah: .pink, .nevada: .gold, .colorado: .gold, .arizona: .silver, .caSouth: .silver],
        "ASU": [.arizona: .pink, .caSouth: .blue, .nevada: .silver, .newMexico: .silver],
        // --- Independents ---
        "ND":  [.indiana: .pink, .illinois: .gold, .ohio: .gold, .michigan: .silver, .pennsylvania: .gold, .newJersey: .gold, .caSouth: .silver, .flSouth: .silver],
        "BYU": [.utah: .pink, .idaho: .silver, .nevada: .silver, .arizona: .silver],
    ]

    static func tier(team abbreviation: String, pipeline: Pipeline) -> PipelineTier {
        table[abbreviation]?[pipeline] ?? .bronze
    }
}
