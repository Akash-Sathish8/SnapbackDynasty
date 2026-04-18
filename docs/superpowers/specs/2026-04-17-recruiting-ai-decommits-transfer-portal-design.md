# Recruiting AI, Decommits & Transfer Portal — Design Spec
**Date:** 2026-04-17  
**Branch:** ahmed/improvements  
**Status:** Approved, ready for implementation

---

## Overview

Three interconnected recruiting improvements built as surgical patches on the existing `RecruitingEngine`, plus a new `TransferPortalEngine` and updated `TransferPortalView`. All tuning numbers live in a new `RecruitingConfig` enum. No structural changes to `Season`, `Recruit`, or `RecruitInterest` models beyond adding a `loyalty` field to `RecruitInterest` and a new `TransferEntry` model.

---

## Section 1 — AI Recruiting (Hybrid Pressure)

### Goal
AI teams feel like real competing programs — invisible internally, but their effects are visible in interest bars, late swoops, and realistic positional targeting.

### Changes to `RecruitingEngine.applyAIPressure`

**1. Positional need scoring**  
Before applying interest, each AI team computes a need multiplier for the recruit's position:
```
need = (rosterCount - currentPlayersAtPosition) / rosterCount
needMultiplier = lerp(RecruitingConfig.needMultipliers.full,
                      RecruitingConfig.needMultipliers.empty,
                      need)
```
- Full position (at or above `rosterCount`): multiplier = 0.3 — AI barely recruits this position
- Empty position: multiplier = 2.0 — AI aggressively targets this position
- AI teams stop actively pursuing a position once their committed recruits at that position fill the need

**2. Phase-aware aggression**  
Weekly interest gain is multiplied by phase:
- Discovery: ×1.0
- Pitch: ×1.3
- Close: ×1.8

**3. Late swoops (visible effect)**  
Each week, for every AI team with legacy ≥ 80 that is competing for a recruit already committed to another team: 4% chance of a "swoop" — a burst of 10–15 interest points applied in one tick. This creates visible late competition in the recruit's interest bar and feeds into the decommit system.

---

## Section 2 — Decommit Mechanics

### Goal
Committed recruits can flip under sustained rival pressure or specific negative events, with 4★/5★ recruits harder to lose.

### New field on `RecruitInterest`
```swift
var loyalty: Double = 20.0  // starts at 20 for all new commits
```

### New method: `RecruitingEngine.checkDecommit`
Runs in `advanceWeek` after `checkCommit`, only on committed recruits.

**Passive drift**  
If any competing team's interest is within `RecruitingConfig.decommit.rivalGapThreshold` (15 pts) of the committed team's interest:
- Loyalty drops by 1–3 points per week (random within `passiveDriftRange`)
- 4★/5★ recruits have a loyalty floor of 5 — passive drift cannot take them below this

**Event triggers** (applied immediately when event occurs):

| Event | Loyalty Hit | Scope |
|-------|------------|-------|
| Player's team loses by 21+ points | −8 | All committed recruits with `titleContender` or `tradition` motivation |
| Player's team has ≥ 3 committed at recruit's position | −12 | Committed recruits at that position |
| AI swoop lands on a committed recruit | −10 | That recruit only |

**Decommit resolution**  
When loyalty ≤ 0: recruit decommits — `isCommittedToTeamId = nil`, `phaseRaw = RecruitPhase.close.rawValue`, `loyalty` resets to 20.

**Player response — Reassure action**  
New `RecruitingAction.reassure` (cost: 30 hrs, not gated by Top-5):
- Available only when recruit is committed to your team AND loyalty < 10
- Adds `RecruitingConfig.decommit.reassureLoyaltyGain` (6) to loyalty
- `RecruitDetailView` shows a warning badge when loyalty < 10

---

## Section 3 — Transfer Portal

### Timeline
`OffseasonManager.runOffseason` is split into two methods called from `DashboardView`:

- **`runOffseasonPhaseA`** — triggered by the existing "Advance to Offseason" button. Runs: awards, dynasty history snapshots, NSD signing, portal entry generation. Returns immediately after setting `season.portalIsOpen = true`. The UI then shows `TransferPortalView` prominently.
- **`runOffseasonPhaseB`** — triggered by the "Close Portal & Advance" button inside `TransferPortalView`. Runs: portal finalization, graduation, development, legacy recompute, stat wipe, record reset, new season + recruit class generation.

`Season` gets a new `portalIsOpen: Bool = false` field so the UI knows which phase it's in. `DashboardView` shows the portal CTA when `portalIsOpen == true` instead of the normal "Advance to Offseason" button.

### New model: `TransferEntry`
```swift
@Model final class TransferEntry {
    var firstName: String
    var lastName: String
    var positionRaw: String
    var overallAtEntry: Int
    var starsAtEntry: Int
    var fromTeam: Team?
    var toTeam: Team?
    var player: Player?
    var seasonYear: Int
    var statusRaw: String  // available / retained / committed / aiClaimed
}
```
Names are duplicated from `Player` so display works after roster changes.

### Portal entry rates (no per-team cap)

| Condition | Base Rate |
|-----------|----------|
| Starter FR | 3% |
| Starter SO | 6% |
| Starter JR/SR | 10% |
| Non-starter FR | 12% |
| Non-starter SO | 25% |
| Non-starter JR/SR | 38% |
| Starter with 2+ higher-OVR at same position | +15% |
| Team finished below .500 | +12% |
| Team missed bowl / lost conf championship | +8% |
| Player OVR ≥ 85 | +5% |
| Player OVR ≤ 60 | +8% |

Global pool cap: 300 entries across all teams. No cap on entries from any single team.

### Retention phase
Player sees their own players who entered the portal first. Limited **4 retention offers** per offseason (+2 with `silverTongue` ability). One tap = immediate resolution:
- Starter: 75% success base
- Non-starter: 50% success base
- `lockdown` ability: +15% to both

Retained players stay on roster. Unretained players remain in the portal as `.available`.

### Portal recruiting (active mini-season)
- Separate **portal board** capped at 15 players
- Weekly hour budget = 60% of normal recruiting budget
- Two compressed phases: **Evaluating** (interest < 50) and **Deciding** (interest ≥ 50)
- Available actions: Scout (10 hrs), DM (10 hrs), All In (50 hrs), Offer (5 hrs)
- No visits, Full Pitch, Nudge, or Reframe — portal moves faster
- AI teams compete using need-scoring from Section 1
- **4★/5★ restriction**: only teams with legacy ranking in top 25 can offer. Returns `.gated` result with message otherwise.
- A player commits when interest ≥ 70 AND your legacy score beats competing AI teams' scores

### Portal close
`TransferPortalEngine.resolveAndFinalize()`:
1. AI teams claim unclaimed entries by positional need (highest legacy teams pick first)
2. All committed portal players execute `player.team = entry.toTeam`
3. `TransferEntry` records persist in SwiftData for history display

### `TransferPortalView` layout
Three tabs:
- **Retain** — your players who entered, retention offer button, remaining offers shown in header
- **Recruit** — available portal players, filterable by position, sorted by OVR
- **History** — past seasons' portal activity

---

## Section 4 — RecruitingConfig

New `enum RecruitingConfig` (no instances, pure static constants). All engine files reference this instead of inline magic numbers.

```swift
enum RecruitingConfig {
    enum AI {
        static let baseWeeklyGainRange: (Double, Double) = (1.2, 3.0)
        static let phaseMultipliers: [RecruitPhase: Double] = [
            .discovery: 1.0, .pitch: 1.3, .close: 1.8
        ]
        static let swoopChance: Double = 0.04
        static let swoopGainRange: (Double, Double) = (10.0, 15.0)
        static let needMultiplierFull: Double = 0.3
        static let needMultiplierEmpty: Double = 2.0
    }
    enum Decommit {
        static let startingLoyalty: Double = 20.0
        static let loyaltyFloor4And5Star: Double = 5.0
        static let passiveDriftRange: (Double, Double) = (1.0, 3.0)
        static let rivalGapThreshold: Double = 15.0
        static let eventHitBigLoss: Double = -8.0
        static let eventHitOversign: Double = -12.0
        static let eventHitSwoop: Double = -10.0
        static let reassureHourCost: Int = 30
        static let reassureLoyaltyGain: Double = 6.0
        static let loyaltyWarningThreshold: Double = 10.0
    }
    enum Portal {
        // Entry rates
        static let starterFR: Double = 0.03
        static let starterSO: Double = 0.06
        static let starterJRSR: Double = 0.10
        static let nonStarterFR: Double = 0.12
        static let nonStarterSO: Double = 0.25
        static let nonStarterJRSR: Double = 0.38
        static let starterPushedOut: Double = 0.15
        static let belowFiveHundred: Double = 0.12
        static let missedBowl: Double = 0.08
        static let highOVRBonus: Double = 0.05   // OVR >= 85
        static let lowOVRBonus: Double = 0.08    // OVR <= 60
        // Portal mechanics
        static let globalPoolCap: Int = 300
        static let portalBoardCap: Int = 15
        static let portalHourBudgetFraction: Double = 0.6
        static let baseRetentionOffers: Int = 4
        static let silverTongueBonus: Int = 2
        static let retentionSuccessStarter: Double = 0.75
        static let retentionSuccessNonStarter: Double = 0.50
        static let lockdownBonus: Double = 0.15
        static let offerInterestThreshold: Double = 70.0
        static let fourStarLegacyMinRank: Int = 25
    }
}
```

---

## Files Created / Modified

### New files
- `Engine/Recruiting/TransferPortalEngine.swift`
- `Models/TransferEntry.swift`
- `Engine/Recruiting/RecruitingConfig.swift`
- `docs/superpowers/specs/2026-04-17-recruiting-ai-decommits-transfer-portal-design.md`

### Modified files
- `Models/RecruitInterest.swift` — add `loyalty: Double = 20.0`
- `Models/RecruitingAction.swift` — add `.reassure` case
- `Engine/Recruiting/RecruitingEngine.swift` — rewrite `applyAIPressure`, add `checkDecommit`, add reassure case in `perform`
- `Engine/Progression/OffseasonManager.swift` — split `runOffseason` into `runOffseasonPhaseA` / `runOffseasonPhaseB`, call `TransferPortalEngine.openPortal` in Phase A
- `Models/Season.swift` — add `portalIsOpen: Bool = false`
- `Views/DashboardView.swift` — show portal CTA when `season.portalIsOpen == true`
- `Views/TransferPortalView.swift` — full implementation (3-tab layout)
- `SnapbackDynastyApp.swift` — register `TransferEntry` in schema

---

## Out of Scope (future work)
- Coach changes as a decommit trigger (no coach tenure tracking yet)
- NIL as a separate mechanic
- Portal players appearing in standings/awards history
- Multi-year portal history UI beyond current season
