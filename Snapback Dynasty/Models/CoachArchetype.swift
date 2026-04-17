import Foundation

/// Coach archetype tree. Base → Elite → Hybrid → Capstone.
enum CoachArchetype: String, Codable, CaseIterable {
    // Base (pick at start)
    case recruiter  = "Recruiter"
    case motivator  = "Motivator"
    case tactician  = "Tactician"
    // Elite (level up base)
    case masterRecruiter = "Master Recruiter"
    case masterMotivator = "Master Motivator"
    case schemeGuru      = "Scheme Guru"
    // Hybrid
    case strategist       = "Strategist"        // Tactician + Recruiter
    case architect        = "Architect"         // Tactician + Motivator
    case talentDeveloper  = "Talent Developer"  // Motivator + Recruiter
    // Capstone
    case programHead      = "Program Head"      // CEO analog
    case programBuilder   = "Program Builder"
}

/// Coach abilities unlocked through archetype progression.
enum CoachAbility: String, Codable, CaseIterable {
    // Recruiter tree
    case onTheTrail        = "On The Trail"         // per-recruit hour cap 50 → 70
    case persuasiveCharm   = "Persuasive Charm"     // Reframe odds buff
    // Strategist
    case scoutsEye         = "Scout's Eye"          // reveal dev trait during scouting
    case flexStandards     = "Flex Standards"       // dealbreaker threshold -1 letter
    // Talent Developer
    case draftDividends    = "Draft Dividends"      // +3000 coach XP per draft pick
    // Program Head (CEO)
    case destinyPick       = "Destiny Pick"         // instant-commit buff at #1 interest
    case openHouse         = "Open House"           // visit cap 4 → 8
    case marqueeBonus      = "Marquee Bonus"        // +XP on CFP wins
    case gainzGetter       = "Gainz Getter"         // training boost
    // Program Builder (retention)
    case silverTongue      = "Silver Tongue"        // +1 portal retention attempt
    case lockdown          = "Lockdown"             // higher retention success rate
    case secondChance      = "Second Chance"        // retry failed retention
    case brotherhood       = "Brotherhood"          // reduce baseline transfer risk
    case lifer             = "Lifer"                // coordinator retention
    case topShelf          = "Top Shelf"            // better coordinator hiring pool
    case closer            = "Closer"               // your coach offers more likely accepted
}
