# Snapback Dynasty — CFB 25/26 Recruiting Reference

Porting reference compiled from EA Deep Dives, Operation Sports, Reddit r/NCAAFBseries, and community reverse-engineering. Confidence tags: **[confirmed]** (EA or widely documented), **[community]** (reverse-engineered / guide consensus), **[unknown]** (not surfaced).

---

## 1. Recruit pool generation

- **Pool size**
  - CFB 25: **3,500 HS recruits / class** [confirmed]
  - CFB 26: **~4,100 HS recruits / class** [confirmed]
- **Star distribution** [community] — pyramid shaped (more 2–3★ than 4–5★); 400-ish 4★, 30–40 true 5★ per class. EA does not publish exact counts.
- **Geographic**: 50 regional pipelines — FL split N/C/S, metro Atlanta own pipeline, TX and CA subdivided, smaller states 1 pipeline each [confirmed]
- **Attributes**:
  - Position + archetype (e.g., QB: Field General / Improviser / Scrambler / Backfield Creator / Pocket Passer)
  - Hidden OVR + 10 archetype attributes revealed through 4 scouting tiers (~10 hrs/tier) [confirmed]
  - Development trait hidden until after NSD unless **Mind Reader** ability unlocked [confirmed]
- **Development traits**: **Normal / Impact / Star / Elite** — XP multiplier on stats; CFB 26 allows dynamic upgrade during career [confirmed]
- **Gem / Bust**: visible probability tag on recruit card; gems skew toward Impact/Star/Elite dev traits. Common on 2–3★ (low floor, high ceiling) [confirmed, probabilities unpublished]

---

## 2. Motivations & dealbreakers

- **14 motivation categories** — same set as school grades [confirmed]:
  Playing Time · Playing Style · Championship Contender · Program Tradition · Campus Lifestyle · Stadium Atmosphere · Pro Potential · Brand Exposure (NIL proxy) · Academic Prestige · Conference Prestige · Coach Prestige · Coach Stability · Athletic Facilities · Proximity to Home
- **Count per recruit**: **3 motivations** (the "ideal pitch") [confirmed]
- **Dealbreaker**: ≥1 hidden category; if school's grade < threshold → recruit won't engage [confirmed]
- **CFB 26 Dynamic Dealbreakers**: threshold scales with recruit's current OVR/star — a 3★ may accept C, when they grow to 92 OVR they want A [confirmed]
- **Star-weighted motivation skew** [community]:
  - 5★: Championship Contender, Brand Exposure, Pro Potential
  - 2★: Academic Prestige, Coach Stability, Proximity to Home
  - Glamor positions (QB/RB/WR/CB/Edge) weight Brand Exposure heavier in CFB 26

---

## 3. School grades

- **14 categories** (same set as motivations) [confirmed]
- **Scale**: 13-point letter grades `F → D- → D → D+ → C- → C → C+ → B- → B → B+ → A- → A → A+` (numeric 1–13) [confirmed]
- **Computation** [confirmed / community]:
  - Playing Time: depth chart + OVR projection vs recruit's projected OVR. **CFB 26: actual snaps played**
  - Playing Style: archetype-specific stat links. CFB 26 rebalanced toward team-level stats
  - Championship Contender: top-25 ranking + **Blue Chip Ratio**
  - Program Tradition: titles/wins/awards (slow)
  - Campus Lifestyle: **static** — never changes
  - Stadium Atmosphere: stadium capacity + attendance
  - Pro Potential: CFB 25 = total draft picks; **CFB 26 = last 4 seasons of draft by position group**
  - Brand Exposure: primetime games, national exposure (NIL proxy)
  - Academic Prestige: **static**
  - Conference Prestige: conference strength
  - Coach Prestige: weighted staff — HC heaviest, coordinators stack
  - Coach Stability: tenure + staying probability
  - Athletic Facilities: facility quality (slow; also boosts progression)
  - Proximity to Home: distance from recruit's pipeline region
- **Dynamic**: Playing Time, Championship Contender, Coach Prestige/Stability, Brand Exposure update weekly/seasonally. Tradition, Facilities, Campus, Academic update yearly or never.
- CFB 26: more D–C clustering → bigger "haves vs have-nots" gap [confirmed]

---

## 4. Pipelines

- 50 regional pipelines, state-based with hotbeds subdivided [confirmed]
- Every school has tier per pipeline, **5 tiers**: Bronze(1) → Silver(2) → Gold(3) → Blue(4) → Pink(5) [confirmed]
- Tiers are **fixed for the dynasty** — based on 10-yr historical data [confirmed]
- Effect: higher tier = more interest-per-hour, better action odds, proximity grade bump. Pink/Blue are dramatically stronger than Gold/Silver/Bronze [community]
- **Coach primary pipeline** stacks additively with school pipeline — a matching coach hire is the only way to "improve" pipeline effect [confirmed]

---

## 5. Weekly recruiting cycle

### Hours per week (regular season) [community, widely cited]

| Legacy | Hours |
|---|---|
| 1.0★ | 350 |
| 1.5★ | 400 |
| 2.0★ | 450 |
| 2.5★ | 500 |
| 3.0★ | 600 |
| 3.5★ | 700 |
| 4.0★ | 800 |
| 4.5★ | 900 |
| 5.0★ | 1,000 |

- **Preseason/offseason**: ~25% higher initial block [community]
- **Top-25 / conf champ**: up to **+5 weekly hours** [community]
- **Per-recruit cap**: **50 hrs/week**; **Always Be Crootin'** (Recruiter T3) raises to 70 [confirmed]
- **No carryover** — unused hours lost weekly [confirmed]
- **Recruiting board cap**: **35 active prospects** [confirmed]
- **Weekly visits cap**: **4 recruits** (CFB 26 "More the Merrier" CEO → 8) [confirmed]

### Action list

| Action | Hrs | Stage | Effect |
|---|---|---|---|
| Offer Scholarship | 5 | Always | +5 interest, signals pursuit, weekly chip damage |
| Search Social Media | 5 | Always | Small influence + minor info |
| DM Player | 10 | Always | 2-arrow influence |
| Scout | 10 | Always | Advances 1 scouting tier (3 sessions = full scout) |
| Contact Friends & Family | 25 | Always | 3-arrow influence |
| Send The House | 50 | Always | 5-arrow influence (max per week) |
| Schedule Visit | 40 | Top 5 + offered | Game-day visit; does NOT count vs 50-hr cap |
| Soft Sell | 20 | Top 5 (Pitch/Close) | Matched-motivation pitch, small lift |
| Hard Sell | 40 | Top 5 | Big lift if grades align; big penalty if not |
| Sway | 30 | Top 5 | Attempts to add secondary motivation |

EA does not publish interest points per hour. Arrows (2/3/5) are ordinal signals only.

---

## 6. Recruiting phases

- **Three phases**: **Discovery → Pitch → Close** [confirmed]
- **Top-list narrowing**: Open → Top 10 → Top 8 → Top 5 → Top 3 → Commit
- **Top 5 unlocks** Pitch actions (Soft/Hard/Sway) + Visits
- **Top 3 unlocks** Close with heavier pitch weighting
- **Weekly reevaluation**: interest + grade alignment determines advances / drops
- **Instant commit** possible only if recruit has your school #1 with gap over #2 — tested ~6% success rate at Penn State across 31 trials [community]
- **Recruiting Battle** [CFB 26 only]: when two schools hit threshold ~simultaneously, new higher threshold + short window; first to cross wins [confirmed]

### Hard Sell "Rule of 19" [community]

Convert 3 pitch grades to points (A+=13, A=12, A-=11, B+=10, B=9, B-=8, C+=7, C=6, C-=5, D+=4, D=3, D-=2, F=1). Sum of 3 motivation grades:
- **≥19** → Hard Sell is +EV
- **<19** → stay on Send The House; Hard Sell risks negative swing

---

## 7. Visits & game-day recruiting

- **Unlock**: Top 5 + scholarship offered [confirmed]
- **Cost**: CFB 25 = flat 40 hrs; **CFB 26 = 10–40 hrs by distance** [confirmed]
- **14 campus activities** matched to grades — align with recruit's motivations → multiplier [confirmed]
- **Co-visit synergies** [confirmed]:
  - Complementary positions (QB+WR+HB+OL) → mutual bonus
  - Same-position co-visits (2 CBs) → penalty
- **Game-day outcome effects**:
  - Ranked win: large + swing
  - Blowout loss: large − swing
  - Close game vs heavy favorite (even in loss): modest +
  - Bye-week visits: smaller max upside, no game variance

---

## 8. Coach system

**Staff**: HC + OC + DC (+ position coaches in CFB 26, 300+ real coaches) [confirmed]. Each has archetype, primary pipeline, ability tree.

### Archetypes

- **Base** (choose at start): **Recruiter · Motivator · Tactician**
- **Elite** (level up base): Elite Recruiter · Master Motivator · Scheme Guru
- **Hybrid** (cross-tree):
  - **Strategist** = Tactician + Recruiter → **Mind Reader**, **Lower the Bar** (CFB 26: -1 letter grade on dealbreaker)
  - **Architect** = Tactician + Motivator
  - **Talent Developer** = Motivator + Recruiter → **Draft Dividends** (+3000 XP/drafted player CFB 26)
- **Capstone**:
  - **CEO** (2 natties + 200 pts) → **Dream School** (instant commit buff), **More the Merrier** (visit cap 4→8), **Big Game Bonus** (+12,500 XP/CFP win)
  - **Program Builder** (5 CFP wins + 125 pts) → retention (**Gift of Gab**, **Roster Retainer**, **Full Refund**, **Family Atmosphere**, **Forever Home**, **Deal Sweetener**, **Cream of the Crop**)

### Key recruiting abilities

- **Always Be Crootin'** — per-recruit cap 50→70
- **Mind Reader** — reveals dev trait (CFB 25: at visits, CFB 26: during scouting)
- **Dream School** — meaningful instant-commit buff
- **Lower the Bar** — drops dealbreaker threshold by up to 1 letter
- **Persuasive Personality** — Sway odds buff
- **Draft Dividends / Big Game Bonus** — XP multipliers

### Coach XP & level

- CFB 25: max level 50 (~500 pts)
- CFB 26: max level **100**; Elite archetypes earn 2x XP, Capstone up to 10x

---

## 9. Signing milestones

- **Early Signing Day** — early December in-game. Committed recruits sign + lock [confirmed]
- Transfer portal opens right after ESD [confirmed]
- **National Signing Day** — ~first Wednesday of February (~7 in-game weeks after National Championship) [confirmed]
- **Verbal commits** (pre-ESD) are soft — can flip
- **Post-ESD** commits are hard — cannot flip
- **Flip triggers**: competitor crosses threshold, coaching change, grade slips below rising threshold, losing streak / ranking drop

---

## 10. Transfer portal

- **Pool**: CFB 25 ~2,000; **CFB 26 up to 3,500** [confirmed]
- **Windows**: ~4-week post-season window; CFB 26 adds compressed spring window
- **Who enters** [confirmed]:
  - Dealbreakers breaking (esp. playing time dropping below threshold)
  - NFL draft projection
  - Coaching change
- **CFB 26 Playing Time trigger**: actual snaps played, not depth chart alone
- **Star ratings**: CFB 25 derived from OVR; **CFB 26 factors position + class year**
- **4★/5★ transfers** only engage top 5 schools [confirmed]
- Each transfer gets new ideal pitch + motivations including the dealbreaker that caused transfer
- **Retention abilities** (Program Builder): Gift of Gab, Roster Retainer, Full Refund, Family Atmosphere
- **CFB 26 settings**: max transfers per team 0–30 slider; user/CPU transfer probability sliders

---

## 11. Class composition

- **85 scholarship cap** — must return to 85 each offseason [confirmed]
- **Class size**: governed by open slots (85 − returners). No explicit hard per-year cap documented
- **Board cap**: 35 active recruits [confirmed]
- **No walk-ons / greyshirts / preferred walk-ons** — not modeled [confirmed]
- **Cut logic**: mandatory offseason roster trim
- **CFB 26 redshirts**: postseason games don't count vs eligibility; partial depth chart reset on redshirt

---

## 12. Feedback loops

- **Winning → grades**: Championship Contender + Coach Prestige + Brand Exposure all lift with wins
- **Winning → hours**: top-25 / conf champ = up to +5 weekly hrs
- **Heisman / All-American**: lift Program Tradition, Brand Exposure, position-group Pro Potential
- **NFL draft**: CFB 26 Pro Potential = last 4 yrs by position — sending a QB to NFL specifically boosts Pro Potential for future QB recruits
- **Facilities grade**: CFB 26 adds % bonus to offseason player development
- **Static grades**: Academic Prestige + Campus Lifestyle never move

---

## 13. Coaching carousel

- End-of-season: HCs at top programs get external offers. Coordinators can be poached year-round
- HC departure → commits with Coach Prestige/Stability dealbreakers at flip risk
- New HC's pipeline/archetype swaps the coach-pipeline buff (school pipeline tiers stay fixed)
- CFB 26 abilities: Forever Home (coord retention), Deal Sweetener (accept offers), Cream of the Crop (better coord pool)

---

## 14. Hidden / community-confirmed

- **Hard Sell Rule of 19** — documented formula
- **Scholarship chip damage** — each week after offer adds small recurring interest; offer all 35 scholarships week 1
- **Instant commit ~6%** at #1 interest (OpSports-tested)
- **Pipeline multipliers** ordinal-only (Pink/Blue strong, Gold/Silver/Bronze modest)
- **Blue Chip Ratio** drives Championship Contender grade
- EA does not publish per-action interest points. Arrows are ordinal.

---

## Key deltas CFB 25 → CFB 26

- Recruit pool 3,500 → ~4,100
- Visit cost flat 40 → 10–40 by distance
- Transfer portal 2,000 → up to 3,500; star ratings factor position + class year; conference-prestige dealbreaker added
- Dealbreakers static → **Dynamic** (scale with OVR)
- Playing Time grade: depth chart → **actual snaps played**
- Pro Potential: total draft picks → **last 4 yrs by position**
- Playing Style: individual stat → team stat (esp. defense)
- Dev traits: static → dynamic upgrade/downgrade
- Mind Reader: visits → scouting
- Coach level cap 50 → 100; Elite 2x, Capstone up to 10x
- Recruiting Battles (new)
- Red-dot notifications, trend arrows, advanced filters, favorites (QoL)
- More the Merrier: visit cap 4 → 8
- 300+ real coaches with archetypes/pipelines
- Redshirt rules: postseason exempt

---

## Open questions

Items EA has not published and community has not cracked:
- Exact interest points per action
- Exact 5★/4★/3★/2★/1★ count per class
- Position distribution ratios in generation
- Gem/bust probability tables
- Dev trait base probabilities (e.g., % of Green Gems → Elite)
- Preseason hour multiplier exact value
- Pipeline tier multipliers (e.g., Pink = +X%)
- Flip probability formula
- Commit interest threshold values
- Soft Sell / Sway success formulas
- Exact coach XP amounts (only a few spot-confirmed)

---

## Sources

- EA CFB 26 Dynasty & Team Builder Deep Dive — ea.com
- EA CFB 26 Dynamic Dealbreakers & Dev Traits — ea.com
- EA CFB 25 Dynasty Deep Dive — ea.com
- EA CFB 25 Recruiting Tips — ea.com
- Operation Sports: All-In-One Recruiting Guide; Instant Commits; Hours Calculation; Gems/Busts thread; Coaching Trees tier list
- 18 Stripes: CFB 25 Dynasty Deep Dive
- CollegeFootball.gg: Hard Sell Science; Coach Skills CFB 26
- GamesRadar+: CFB 25 Recruiting Guide
- Uproxx: How Recruiting Works
- T4G Sports: Hours per Legacy Table
- Pro Football Network: CFB 26 coverage
- Turtle Beach: School Attributes
- Sportskeeda: Pipelines
- Dexerto: Coach Archetypes
- Gamer Rant: Pipelines Explained
- Prima Games: Dev Traits
- Escapist: Transfer Portal

---

## How this changes our Phase E plan

The current plan (Python port) has lighter recruiting than EA. To match CFB 25/26 more closely, Phase E should expand to:

1. **14 school grade categories** (not a handful) — full list above
2. **13-point grade scale** (A+ to F, numeric 1–13) — plus the "Rule of 19" Hard Sell heuristic
3. **50 regional pipelines** with 5 tiers (Bronze → Pink), fixed per school, coach-pipeline stacking
4. **Recruit pool 3,500–4,100 per class** (not 300)
5. **Dev traits**: Normal/Impact/Star/Elite + Gem/Bust tags
6. **3 motivations + dynamic dealbreaker** per recruit (scales with OVR)
7. **Weekly hours scaled by legacy** (350 at 1.0★ → 1,000 at 5.0★)
8. **Per-recruit cap** 50 hrs, **board cap** 35 recruits
9. **Phase state machine**: Discovery → Pitch → Close with Top 10 → Top 5 → Top 3 narrowing
10. **Full action list** with exact hour costs (Scout 10, DM 10, Contact 25, Send House 50, Offer 5, Visit 40, Soft Sell 20, Hard Sell 40, Sway 30)
11. **Visit system** with co-visit synergies, game outcome effects, 14 campus activity categories
12. **Coach archetype tree** (Recruiter/Motivator/Tactician → Elite → Hybrid → Capstone) with recruiting abilities
13. **Dual signing days** — ESD + NSD — with commit locking
14. **Transfer portal** with window + snaps-played dealbreaker triggers + 4★/5★ top-5 restriction
15. **Dynamic school grade updates** throughout the season, with feedback from wins/awards/drafts

This is ~2-3× the Python scope we'd originally planned. Worth flagging and scoping before Phase E starts.
