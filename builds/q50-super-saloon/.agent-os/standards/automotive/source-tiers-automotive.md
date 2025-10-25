# Automotive Domain Source Tiers

**Inherits From:**
- System: `~/.agent-os/profiles/default/standards/global/fact-verification.md`
- Project: `~/personal/builder-platform/agent-os/standards/builder-platform/fact-verification.md`
- Project Source: `~/personal/builder-platform/platform/standards/fact-verification-protocol.md`

**Spec Level:** Subproject (Q50 Super Saloon - Automotive Domain)
**Last Updated:** 2025-10-15
**Status:** Active

---

## Inherited Standards

This specification **extends** system and project fact verification standards with **automotive domain-specific source tier examples**.

**Parent Standards Provide:**
- Universal 3-tier source hierarchy (Tier 1/2/3)
- 95%+ confidence requirements
- Source priority in conflicts
- Verification workflow

**This Subproject Extension Adds:**
- Automotive-specific source examples for each tier
- VR30/Q50-specific authoritative sources
- Performance testing source classification
- Automotive forum/community source evaluation

---

## Automotive Domain Source Tiers

### Tier 1 Sources (Primary - Ground Truth)

**Definition (from parent):** Primary authoritative sources, manufacturer documentation, peer-reviewed research

**Automotive-Specific Examples:**

#### Factory Documentation
- **Infiniti/Nissan Factory Service Manual (FSM)** for Q50/VR30
- **OEM Technical Service Bulletins (TSBs)**
- **Factory specifications** (power, torque, dimensions, weights)
- **Parts diagrams and part numbers** (official OEM catalogs)
- **Warranty documentation** (coverage, limitations, exclusions)

#### Engineering & Research
- **SAE (Society of Automotive Engineers) technical papers**
- **Patent documents** (turbo design, engine technology, drivetrain systems)
- **NHTSA (National Highway Traffic Safety Administration) data**
  - Crash test results
  - Safety recalls
  - Defect investigations

#### Verified Testing
- **Manufacturer dyno sheets** (official power curves)
- **EPA fuel economy testing** (official numbers)
- **Emissions certification** data

**Examples for VR30/Q50:**
- Infiniti Q50 Factory Service Manual (2014-2024 model years)
- Nissan Technical Service Bulletin ITB14-078a (VR30DDTT oil consumption)
- SAE Paper 2016-01-0674: "Development of VR30DDTT Twin-Turbo V6"
- Infiniti Press Kit specifications (when citing official claims)

---

### Tier 2 Sources (Secondary - Trusted Industry)

**Definition (from parent):** Established industry experts, professional journalists, verified practitioners

**Automotive-Specific Examples:**

#### Established Tuning Houses
- **SpecialtyZ** (Nissan/Infiniti focus, documented VR30 builds)
- **ESP (Engine Systems Performance)** (performance calibration specialists)
- **AAM Competition** (established aftermarket performance)
- **Cobb Tuning** (calibration and tuning platforms)

**Requirements for Tier 2 tuner classification:**
- 5+ years documented history
- Multiple completed builds with results
- Dyno testing with published sheets (SAE corrected)
- Reputation in enthusiast community

#### Professional Automotive Media
- **Car & Driver** (professional testing, standardized methodology)
- **Motor Trend** (professional testing, track data)
- **Road & Track** (professional testing, technical analysis)
- **Autoweek** (industry news, professional perspective)

**NOT Tier 2:**
- Clickbait automotive YouTube channels
- Manufacturer-sponsored "reviews"
- Advertorial content disguised as journalism

#### Parts Manufacturers with Engineering Data
- **KW Suspension** (coilover specifications, spring rates, damping curves)
- **Whiteline** (suspension geometry data, bushing specifications)
- **HKS, GReddy, Tomei** (performance parts with engineering data)

**Requirements for Tier 2 parts manufacturer:**
- Published engineering specifications
- Testing data for products
- Technical support documentation
- Established reputation (not unknown brands)

#### Racing Organizations
- **SCCA (Sports Car Club of America)** competition data
- **NASA (National Auto Sport Association)** lap times and results
- **Time Attack** series results (where applicable)

---

### Tier 3 Sources (Tertiary - Community Validated)

**Definition (from parent):** Community sources with documentation, multiple corroborating sources

**Automotive-Specific Examples:**

#### Forums with Documentation
- **G37Driver.com / Q50-Q60.com** (platform-specific community)
  - Build threads with photo documentation
  - Dyno results from multiple users
  - Parts reviews with before/after data

- **NICOclub** (Nissan/Infiniti general community)
  - Long-established community (credibility through longevity)
  - Technical sub-forums with knowledgeable contributors

- **MyG37.com** (Q50/G37 platform overlap)
  - Documented builds
  - Transmission/drivetrain discussions

**Requirements for Tier 3 forum classification:**
- Photo documentation of build
- Receipts or invoices (when discussing costs)
- Dyno sheets (when claiming power numbers)
- Multiple data points (not single user claim)

#### YouTube Builders (with proven track records)
- **The Smoking Tire (Matt Farah)** - When discussing VR30/Q50 specifically
- **Savagegeese** - In-depth technical reviews
- **Engineering Explained** - Technical concepts (not specific to Q50)

**Requirements for Tier 3 YouTube classification:**
- 3+ years channel history
- Technical expertise demonstrated
- Data-driven content (not opinion pieces)
- Transparent about testing methodology

**NOT Tier 3:**
- Channels with <1 year history
- "Reaction" or "commentary" content
- Clickbait titles without substance
- Unverified claims without supporting data

#### Owner Experiences (Limited Use)
- **Use for subjective assessments ONLY**
  - Ride quality perceptions
  - Noise level experiences
  - Daily drivability opinions

- **NOT for technical facts**
  - Power numbers (without dyno)
  - Performance limits (without testing)
  - Reliability claims (without statistical sample)

---

### Disallowed Sources (Do Not Use)

**Never acceptable for fact verification:**

- **Single forum post** without corroboration
- **Social media claims** (Instagram, Facebook, TikTok) without verification
- **"Butt dyno"** or subjective feel
- **Manufacturer marketing** without supporting data
- **ChatGPT/AI-generated content** without source verification
- **Wikipedia** (use Wikipedia's cited sources instead)
- **Anonymous sources** ("someone told me...")
- **Hearsay** ("people say...")

---

## VR30/Q50-Specific Source Authority

### For VR30DDTT Engine Specifications

**Tier 1 (use these):**
- Infiniti Q50 Factory Service Manual
- Infiniti Press Kit (official manufacturer claims)
- SAE papers on VR30 development

**Tier 2 (use these with appropriate confidence):**
- SpecialtyZ dyno testing and build documentation
- ESP calibration data and experience
- Professional media testing (Car & Driver, Motor Trend)

**Tier 3 (corroborate with multiple sources):**
- Q50/G37 forum builds with dyno sheets
- YouTube builders with documented VR30 work
- Owner experiences for subjective assessments only

### For 7-Speed Automatic Transmission (7AT/RE7R01A)

**Tier 1:**
- Factory Service Manual transmission section
- OEM TSBs related to transmission
- JATCO (manufacturer) technical documentation if available

**Tier 2:**
- Tuning shops with documented 7AT high-power builds
- Transmission specialist shops (Level 10, etc.)
- Professional media testing of transmission performance

**Tier 3:**
- Forum discussions of transmission behavior with multiple data points
- Owner experiences with high-power builds (mileage, reliability)

### For AWD System (ATTESA-based)

**Tier 1:**
- Factory Service Manual AWD system documentation
- Nissan/Infiniti AWD technical whitepapers

**Tier 2:**
- Professional testing of AWD performance distribution
- Tuning shops with AWD dyno testing experience

**Tier 3:**
- Owner experiences with AWD behavior in various conditions
- Forum discussions of AWD characteristics

---

## Source Conflict Resolution (Automotive-Specific Examples)

### Example 1: Power Output Claims

**Scenario:** Factory claims 400 hp, aftermarket dyno shows 360 whp (wheel horsepower)

**Analysis:**
- NOT a conflict - different measurement points
- Factory: Crank horsepower (engine output)
- Dyno: Wheel horsepower (after drivetrain loss)
- Approximately 10-15% drivetrain loss expected for AWD

**Proper statement:**
"VR30DDTT produces 400 hp @ 6,400 rpm (manufacturer spec, crank horsepower / SAE net). Wheel horsepower typically measures 360-370 whp on AWD dyno accounting for ~10% drivetrain loss."

### Example 2: Boost Pressure Limits

**Scenario:**
- Source A (Tier 2 tuner): "Safe to 18 psi on stock engine"
- Source B (Tier 2 tuner): "20 psi is the limit with head studs"

**Analysis:**
- Conflicting recommendations from equal-tier sources
- Different assumptions (stock block vs head studs)
- Both may be accurate within their stated conditions

**Proper statement:**
"Boost limits vary based on supporting modifications. SpecialtyZ documents safe operation to 18 psi on stock VR30 internals with proper tuning. ESP recommends 20 psi maximum with ARP head studs and upgraded intercooler. Conservative approach: 18 psi stock, 20 psi with studs and supporting mods."

**Confidence:** 85% (equal-tier sources, conservative approach stated)

---

## Usage Guidelines

**When verifying automotive facts:**

1. **Identify fact type**
   - Specification (power, torque, dimensions) → Require Tier 1
   - Performance claim (0-60, lap time) → Tier 1 or 2+ Tier 2 sources
   - Modification result (dyno gain) → Tier 2 with documentation
   - Subjective assessment (ride quality) → Tier 3 acceptable, mark as subjective

2. **Classify sources using automotive tier examples**
3. **Apply 95%+ confidence requirement** (from parent spec)
4. **Document sources** with tier classification
5. **Resolve conflicts** using automotive examples as guidance

---

## No Overrides

This spec provides **automotive-specific examples** for the parent source tier system.

It does NOT change:
- The 3-tier hierarchy structure
- The 95%+ confidence requirement
- Source priority rules in conflicts
- Verification workflow

It ADDS:
- Automotive source examples for each tier
- VR30/Q50-specific authoritative sources
- Domain-specific conflict resolution examples

---

**Automotive domain requires same rigor as all Builder Platform work. Source tier examples help ensure we cite appropriate authorities for automotive facts.**
