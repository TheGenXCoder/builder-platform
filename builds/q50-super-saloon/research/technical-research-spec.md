# TECHNICAL RESEARCH SPECIFICATION v2.0
## Infiniti Q50 Super Saloon Project

**Confidence Target:** 95%+ on all specs that drive build decisions

**Last Updated:** October 3, 2024

---

## Purpose

This document defines the technical research requirements for the Q50 Super Saloon build. Every specification that could influence build decisions (engine choice, transmission path, component selection) must be verified to 95%+ confidence before proceeding.

**Build Goals:**
- Power: 600-800 hp, emphasis on torque
- Use Case: 80/20 street/track split
- Philosophy: Gentleman's weapon (luxury + capability)
- Approach: Cost-conscious quality

---

## A. VR30DDTT Engine - Complete Technical Profile

### 1. Core Specifications (Ground Truth Required)

| Specification | Data Required | Verification Standard | Source Tier |
|---|---|---|---|
| Displacement | Exact cc/ci | Factory FSM + SAE papers | Tier 1 |
| Bore × Stroke | mm/inches, tolerance specs | Factory FSM | Tier 1 |
| Compression Ratio | Static ratio, effective under boost | Factory FSM + verified dyno analysis | Tier 1/2 |
| Block Material | Alloy composition, casting vs forged | FSM + teardown documentation | Tier 1/2 |
| Cylinder Head Material | Alloy composition | FSM + teardown documentation | Tier 1/2 |
| Head Gasket Type | Multi-layer steel specs, thickness | FSM + known failure analysis | Tier 1/2 |
| **Head Lifting Issue** | Boost threshold, failure mode, root cause | Multiple documented failures + expert analysis | Tier 2 (critical) |
| ARP Stud Solution | Part numbers, torque specs, success rate | Documented fixes + tuner shop data | Tier 2 |
| Deck Height | Measurement, comparison to VR38 | FSM or precision teardown | Tier 1/2 |
| Piston Specs | Material, ring specs, compression height | FSM or OEM parts data | Tier 1 |
| Connecting Rod Specs | Material, length, small/big end dimensions | FSM or OEM parts data | Tier 1 |
| Crankshaft Specs | Material, stroke, journal diameters, forged/cast | FSM or OEM parts data | Tier 1 |
| Rev Limit | Factory ECU limit, safe limit stock, modified safe limit | FSM + tuner consensus | Tier 1/2 |

### 2. Forced Induction System

| Specification | Data Required | Verification Standard | Source Tier |
|---|---|---|---|
| Turbocharger Manufacturer | OEM supplier (IHI, Garrett, BorgWarner?) | FSM or parts documentation | Tier 1 |
| Turbo Model/Trim | Compressor/turbine wheel specs, A/R | FSM or teardown documentation | Tier 1/2 |
| Red Sport 400 Turbo Differences | Exact differences from base 3.0t turbos | Comparative analysis + OEM data | Tier 1/2 |
| Wastegate Type/Size | Internal/external, spring pressure | FSM or parts data | Tier 1 |
| Max Boost (Stock) | Factory boost levels by model | FSM + logs from stock vehicles | Tier 1 |
| Safe Boost Limits (Stock internals) | Community consensus + failure data | Tuner shop data + failure analysis | Tier 2 |
| Intercooler Specs | Core size, efficiency, pressure drop | FSM or OEM specs | Tier 1 |
| Intercooler Limitations | At what power level does it heat soak | Testing data + infrared analysis | Tier 2 |
| Charge Pipe Routing | OEM routing, known restrictions | FSM + aftermarket analysis | Tier 1/2 |

### 3. Fueling System

| Specification | Data Required | Verification Standard | Source Tier |
|---|---|---|---|
| Fuel Injector Size | cc/min or lb/hr rating | FSM or OEM parts data | Tier 1 |
| Fuel Pump Capacity | LPH rating, pressure capability | FSM or OEM parts data | Tier 1 |
| Fuel Rail Pressure | Stock pressure, limits | FSM + tuner data | Tier 1/2 |
| Max Power on Stock Fueling | Community consensus + dyno data | Multiple builds at fueling limit | Tier 2 |
| Upgrade Path: Injectors | Part numbers, sizes, plug-and-play options | Vendor data + proven installs | Tier 2 |
| Upgrade Path: Pumps | In-tank vs external, capacity gains | Vendor data + proven installs | Tier 2 |
| Fuel System Limits by Power | 400hp, 500hp, 600hp, 700hp, 800hp thresholds | Tuner shop data across multiple builds | Tier 2 |

### 4. Engine Management

| Specification | Data Required | Verification Standard | Source Tier |
|---|---|---|---|
| ECU Manufacturer/Model | Hitachi, Denso, Continental? Part number | FSM or OEM data | Tier 1 |
| Tuning Capability | Locked/unlocked, flash vs piggyback | Tuner shop analysis | Tier 2 |
| Available Tuning Solutions | EcuTek, UpRev, HPTuners - what works | Verified tuner tools + shop data | Tier 2 |
| Remote Tune Capability | Which platforms support remote tuning | Tuner shop offerings | Tier 2 |
| Standalone ECU Options | Haltech, AEM, Motec - fitment and support | Proven swaps with documentation | Tier 2 |
| Flex Fuel Capability | E85 tuning, sensor requirements | Proven flex fuel builds | Tier 2 |

### 5. Known Weaknesses & Failure Modes (CRITICAL)

| Issue | Failure Mode | Power/Boost Threshold | Solution | Verification | Source Tier |
|---|---|---|---|---|---|
| **Head Lifting** | Gasket failure, coolant intrusion | [Need data] psi boost / [X] hp | ARP studs, thicker gasket? | Documented failures + fixes | Tier 2 (critical) |
| Turbo Failure | Shaft play, compressor wheel damage | [Need data] - at what mileage/power | Upgrade to [specific turbos] | Failure analysis + replacements | Tier 2 |
| Fuel Pump Failure | Pressure drop under load | [Need data] | Upgrade to [specific pump] | Known failures + upgrades | Tier 2 |
| Carbon Buildup (DI) | Intake valve deposits, performance loss | Mileage-based, not power-based | Walnut blasting, catch can | Known issue + solutions | Tier 2 |
| Ignition Coil Failure | Misfires under boost | Age/mileage related | Upgrade to [specific higher-output coils with part numbers] | Known issue + solutions | Tier 2 |

**Critical Research Questions:**
1. **Head lifting**: At what boost/power does this occur? What's the mechanism? What percentage of builds at X psi experience this failure? What's the proven fix? Cost?
2. **Safe power limits on stock internals**: What's the community consensus with failure data to back it up?
3. **VR30 vs VR38 architecture**: Are they related enough that internals interchange? Block/head bolt patterns same?

---

## B. VR38DETT Swap Feasibility (CRITICAL DECISION POINT)

**This determines if VR38 is even an option. Need 95%+ confidence before considering.**

| Research Item | Data Required | Why It Matters | Source Tier |
|---|---|---|---|
| Engine Dimensions | VR30 vs VR38: length, width, height | Frame rail clearance | Tier 1 |
| Motor Mount Locations | VR30 vs VR38: mounting point geometry | Fabrication feasibility | Tier 1/2 |
| Transmission Compatibility | Does VR38 bolt to Q50 transmissions? | Determines if trans swap also required | Tier 1 |
| Bellhousing Pattern | VR30 vs VR38 comparison | Adapter plate feasibility | Tier 1 |
| Accessory Drive | VR30 vs VR38: alternator, PS, AC locations | Clearance and functionality | Tier 2 |
| Oil Pan/Pickup | VR30 vs VR38: ground clearance impact | Ride height / practicality | Tier 2 |
| Wiring Harness | VR38 standalone harness options | Swap complexity | Tier 2 |
| ECU/Tuning | VR38 ECU + tuning ecosystem | Ongoing support | Tier 2 |
| **Has Anyone Done This?** | Documented VR38 swap into Q50/Q60/V37 chassis | Proof of concept, lessons learned | Tier 2/3 (critical) |
| Cost Analysis | VR38 engine cost + swap parts + labor | ROI vs building VR30 | Tier 2 |
| Power Potential Comparison | VR38 proven power vs VR30 proven power | Is the swap worth it? | Tier 2 |

**Decision Gate Questions:**
1. **Will it fit between the frame rails?** (with or without modification)
2. **Has anyone successfully done this swap in a V37 chassis?**
3. **If no documented swaps exist, why not?** (Physical constraint? Cost? Not worth it?)
4. **What's the all-in cost vs building VR30 to same power level?**
5. **At 600-800hp target, is VR38 swap justified, or is built VR30 smarter?**

---

## C. Transmission Deep-Dive

### C1. 7-Speed Automatic (7AT) - AWD Variant

| Specification | Data Required | Verification Standard | Source Tier |
|---|---|---|---|
| Manufacturer/Model | JATCO JR711E (verify) | FSM or OEM data | Tier 1 |
| Torque Rating (Stock) | lb-ft capacity | FSM or OEM data | Tier 1 |
| Gear Ratios | All 7 gears + final drive | FSM | Tier 1 |
| Clutch Pack Specs | Material, number of plates | FSM or rebuild documentation | Tier 1/2 |
| Valve Body Type | OEM design, electronic control | FSM | Tier 1 |
| Fluid Capacity/Type | Quarts, specific fluid (Nissan Matic-S?) | FSM | Tier 1 |
| **Power Limits (Stock)** | At what power/torque do they fail? | Failure data from community | Tier 2 (critical) |
| Failure Modes | Slipping, shuddering, hard shifts | Documented failures | Tier 2 |
| **Tune Options** | TCU tuning (EcuTek, UpRev) capabilities | Tuner shop data | Tier 2 |
| Shift Speed Improvements | With tune, how much faster? | Before/after data | Tier 2 |
| **Upgraded Clutch Packs** | Who makes them? Cost? Install difficulty? | Parts vendors + shop data | Tier 2 |
| Upgraded Valve Body | Options, improvements, cost | Parts vendors + shop data | Tier 2 |
| Torque Converter Upgrade | Stall speed options, lockup improvements | Parts vendors + proven builds | Tier 2 |
| **Max Reliable Power** | With all upgrades, what's achievable? | Proven builds at high power | Tier 2 (critical) |

### C2. 6-Speed Manual (6MT) - If Factory Option Exists

| Specification | Data Required | Verification Standard | Source Tier |
|---|---|---|---|
| **Q50 Factory 6MT Availability** | Does Q50 come with manual? (Red Sport 400 AWD?) | OEM documentation | Tier 1 (critical) |
| If Yes: Manufacturer/Model | Getrag, Aisin, JATCO? Model number | FSM or OEM data | Tier 1 |
| Gear Ratios | All gears + final drive | FSM | Tier 1 |
| Torque Rating (Stock) | lb-ft capacity | FSM or OEM data | Tier 1 |
| Clutch Specs | Disc size, material, pressure plate | FSM or OEM parts data | Tier 1 |
| **Power Limits (Stock)** | Proven power handling | Community data | Tier 2 |
| Upgraded Clutch Options | Twin-disc, single heavy-duty options | Parts vendors + proven installs | Tier 2 |
| Synchro Durability | Known issues with high torque? | Community reports | Tier 2 |
| Shifter Feel/Quality | Is it good or does it need upgrades? | Owner feedback + aftermarket support | Tier 2/3 |

**Research Note:** Suspect Q50 may not have factory manual option (especially AWD). Need to verify immediately as it affects entire research direction.

### C3. Aftermarket Manual Swap Options

**Critical Question:** If Q50 has no factory manual, what are the swap options?

| Option | Feasibility | Data Required | Source Tier |
|---|---|---|---|
| **G37 6MT Swap** | Has anyone done this? | Documented swaps, parts required | Tier 2/3 |
| Bellhousing Compatibility | Does VR30 bolt to G37 6MT? | Adapter plate or direct fit? | Tier 2 |
| Transmission Tunnel Clearance | Does 6MT fit Q50 tunnel without cutting? | Documented swap or measurements | Tier 2 |
| Shifter Location | Where does it end up in cabin? | Swap documentation | Tier 2 |
| Pedal Assembly | Clutch pedal fabrication required? | Swap documentation | Tier 2 |
| Hydraulics | Clutch master/slave cylinder sourcing | Swap documentation | Tier 2 |
| **AWD Retention** | Can manual swap retain AWD? | Transfer case compatibility | Tier 2 (critical) |
| If AWD Possible: Parts Required | Transfer case, driveshafts, diff controller | Detailed parts list from swaps | Tier 2 |
| If RWD Only: Driveline Changes | What's required to convert to RWD? | Documented conversions | Tier 2 |
| Wiring/ECU | Manual trans signals, reverse lights, etc. | Swap documentation | Tier 2 |
| Cost Estimate | All parts + labor (or DIY time) | Aggregated from swaps | Tier 2 |
| **Is It Worth It?** | Performance benefit vs 7AT tuned | Objective analysis | Tier 2 |

**Pros/Cons Analysis Required:**
- **Manual + AWD:** Control + traction (ideal) - is it possible?
- **Manual RWD only:** Control + purity - lose traction advantage
- **7AT AWD tuned:** Keep traction + ease - lose engagement

---

## D. Driveline Components

### D1. Driveshafts

| Configuration | Data Required | Why It Matters | Source Tier |
|---|---|---|---|
| **Stock AWD Configuration** | Front + rear driveshaft specs | Baseline understanding | Tier 1 |
| Stock Material | Steel, aluminum? | Weight, strength | Tier 1/2 |
| Stock Design | 2-piece vs 1-piece (front and rear) | Vibration, failure points | Tier 1 |
| Stock Diameter | Tube diameter | Strength calculation | Tier 1/2 |
| **Power Limits (Stock)** | At what power/torque do they fail? | Failure data | Tier 2 |
| Failure Mode | Twisting, U-joint failure, center bearing? | Known failures | Tier 2 |

**Aftermarket Options:**

| Material | Pros | Cons | Weight Savings | Cost | Proven Power Handling | Source Tier |
|---|---|---|---|---|---|---|
| **Aluminum** | Lighter, strong enough for most | Can dent, potential vibration | ~[X] lbs | ~$[X] | [X] hp | Tier 2 |
| **Stainless Steel** | Durable, corrosion resistant | Heavier | ~[X] lbs | ~$[X] | [X] hp | Tier 2 |
| **Carbon Fiber** | Lightest, exotic | Expensive, overkill? | ~[X] lbs | ~$[X] | [X] hp | Tier 2 |
| **1-piece vs 2-piece** | Eliminates center bearing | Vibration at certain lengths? | [Analysis] | [Cost delta] | [Pros/cons] | Tier 2 |

**Vendors to Research:**
- Driveshaft Shop
- Inland Empire Driveline
- DSS (Driveshaft Shop)
- Others specific to VR30 platform

### D2. U-Joints

| Type | Serviceable? | Strength | Replacement Availability | Cost | Source Tier |
|---|---|---|---|---|---|
| **Stock U-Joints** | [Yes/No] | [Rating] | OEM part number | ~$[X] | Tier 1 |
| **Upgraded U-Joints** | [Yes/No] | [Rating] | Aftermarket options | ~$[X] | Tier 2 |
| Spicer 5-series (example) | Yes | [Rating] | Widely available | ~$[X] | Tier 2 |
| Greaseable vs Sealed | Serviceability tradeoff | Maintenance impact | N/A | N/A | Tier 2 |

**Research Questions:**
1. Are stock Q50 AWD driveshafts serviceable (can U-joints be replaced)?
2. At 600-800hp, are upgraded driveshafts mandatory or just "nice to have"?
3. What's the weight delta between stock and lightest practical option?
4. Real-world failures at high power levels?

---

## E. Build Decision Matrix (CRITICAL - DRIVES EVERYTHING)

**Power Goal: 600-800 hp, emphasis on torque**
**Use Case: 80/20 street/track, luxury + capability**
**Philosophy: Cost-conscious quality**

### Decision Tree Research Requirements:

**Cost Scale Definition:**
- Lowest: $0-5k | Low: $5-15k | Moderate: $15-30k | High: $30-50k | Highest: $50k+

**Complexity Scale Definition:**
- Low: Bolt-on parts, basic tuning | Moderate: Machine work, custom fabrication | High: Engine/trans swap, extensive fab

**1. VR30 Built vs VR38 Swap**

| Scenario | Cost | Complexity | Power Potential | Reliability | Parts Availability | Decision Confidence |
|---|---|---|---|---|---|---|
| **VR30 Stock Block (500-600hp)** | Lowest ($0-5k) | Low | Moderate (500-650hp) | High (if done right) | Excellent | Need 95%+ |
| **VR30 Built Block (700-800hp)** | Moderate ($15-30k) | Moderate | High (700-900hp) | High (with quality build) | Good | Need 95%+ |
| **VR38 Swap (unlimited)** | Highest ($50k+) | High | Highest (900hp+) | ? | Good | Need 95%+ |

**Research Required:**
- VR30 stock block safe limit (with head studs, proper tune)
- VR30 built motor cost (pistons, rods, machine work, assembly)
- VR38 swap all-in cost
- **Which path delivers 600-800hp most reliably at best value?**

**2. Transmission Decision**

| Option | Control/Engagement | Traction (AWD?) | Reliability | Cost | Decision Confidence |
|---|---|---|---|---|---|
| **7AT Tuned + Upgraded** | Moderate | Yes (AWD) | Good (75-85%) | Moderate ($15-30k) | Need 95%+ |
| **Manual Swap + AWD (if possible)** | Excellent | Yes | Unknown | High ($30-50k) | Need 95%+ |
| **Manual Swap RWD Only** | Excellent | No | Good (75-85%) | High ($30-50k) | Need 95%+ |

**Research Required:**
- 7AT power limits with all upgrades
- Manual + AWD feasibility (is it even possible?)
- Cost difference between options
- **What delivers best experience for 600-800hp, 80/20 street/track?**

**3. Turbo Upgrade Path**

**Reliability Scale Definition:**
- Highest: 95-100% success rate at power level | High: 85-95% | Good: 75-85% | Moderate: 60-75%

| Stage | Modifications | Power Target | Cost | Reliability | Decision Confidence |
|---|---|---|---|---|---|
| **Stock Turbos + Tune** | Tune only | ~400-450hp | Lowest ($0-5k) | Highest (95-100%) | Need 95%+ |
| **Stock Turbos + Bolt-ons + Tune** | DP, exhaust, intake, IC | ~450-500hp | Low ($5-15k) | High (85-95%) | Need 95%+ |
| **Upgraded Turbos (Red Sport spec if applicable)** | RS400 turbos + supporting | ~500-550hp | Moderate ($15-30k) | High (85-95%) | Need 95%+ |
| **Aftermarket Turbos (mid-size)** | Precision, Garrett, BW + supporting | ~600-700hp | High ($30-50k) | Good (75-85%) | Need 95%+ |
| **Aftermarket Turbos (large)** | Big singles or twins + built motor | ~700-800hp+ | Highest ($50k+) | Moderate (60-75%) | Need 95%+ |

**Research Required:**
- What turbos are proven on VR30 at each power level?
- Reliability data for each stage
- Supporting mods required (fueling, cooling, etc.)
- Cost analysis for each stage
- **What's the path to 600-800hp with best reliability/value?**

---

## Research Execution Plan

### Phase 1: Critical Path Research (Week 1)

These answers drive all build decisions - must have 95%+ confidence:

1. **VR30 Technical Deep-Dive**
   - Find Factory Service Manual (FSM) for V37 Q50
   - VR30 complete specs from primary sources
   - Head lifting issue: failure analysis, proven solutions
   - Power limits on stock block (with supporting failure/success data)

2. **VR38 Swap Feasibility**
   - Engine dimensions comparison
   - Has anyone done this? (search all forums, shops, YouTube)
   - If no one has done it, investigate WHY
   - Cost analysis if feasible

3. **Transmission Reality Check**
   - Does Q50 come with manual? (Probably not for AWD)
   - 7AT power limits and upgrade path
   - Manual swap feasibility (has anyone done it?)
   - AWD retention with manual (possible or RWD only?)

4. **Build Decision Matrix**
   - Enough data to choose: VR30 built vs VR38 swap
   - Enough data to choose: 7AT upgraded vs manual swap
   - Enough data to plan turbo/power path to 600-800hp

### Phase 2: Detailed Technical Research (Week 2)

Supporting data for content creation:

5. **Complete VR30 Documentation**
   - Fueling system specs and upgrade path
   - Cooling system specs and upgrade requirements
   - All known failure modes and solutions

6. **Driveline Components**
   - Driveshaft specs and upgrade options
   - U-joint serviceability and upgrade path
   - Proven components at target power level

7. **Modification Ecosystem**
   - Parts vendors for every category
   - Tuner shops specializing in VR30
   - Proven builds with documented results

### Phase 3: Historical & Competitive Research (Week 2-3)

Context for storytelling (see historical-research-spec.md)

---

## Confidence Verification Checklist

Before any spec is considered "95%+ confident":

- [ ] Minimum 2 Tier 1 or Tier 2 sources corroborate
- [ ] If sources conflict, conflict is investigated and documented
- [ ] Critical specs (power limits, failure points) have real-world data supporting
- [ ] Any claims about "what's possible" are backed by documented builds
- [ ] Cost estimates are from multiple sources
- [ ] Failure modes are documented with evidence, not speculation

**Review Gate:** Owner reviews all research, verifies sources, adds expertise, confirms confidence level before any content is created.

---

## Source Tier Definitions

**Tier 1 Sources (Primary - Ground Truth):**
- Factory Service Manuals (Infiniti FSM for V37 chassis)
- OEM Technical Service Bulletins
- Factory performance specifications (published by Infiniti/Nissan)
- Dyno sheets from verified, reputable shops with calibration records
- Patent documents for VR30DDTT and platform systems
- SAE technical papers

**Tier 2 Sources (Secondary - Trusted Industry):**
- Established tuning houses with documented builds (Seb@SpecialtyZ, ESP, RJM Performance, etc.)
- Professional automotive journalists with technical credentials
- Racing sanctioning body specifications (SCCA, NASA, etc.)
- Parts manufacturers with engineering data (Whiteline, KW, BC Racing)

**Tier 3 Sources (Tertiary - Community Validated):**
- Forum builds with photo documentation and dyno results (MyG37, Infiniti Q50 forums)
- YouTube builders with proven track records and verifiable builds
- Multiple corroborating sources for any claim

**Disallowed Sources:**
- Single-source forum claims without verification
- Manufacturer marketing without supporting data
- "Butt dyno" or subjective performance claims
- Anything that can't be traced to verifiable origin

---

**Document Status:** Initial specification complete, pending research execution and validation.
