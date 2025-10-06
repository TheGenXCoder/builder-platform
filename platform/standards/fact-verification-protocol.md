# FACT VERIFICATION PROTOCOL v1.0

**The Builder Platform - Quality Assurance Standard**

**Last Updated:** October 4, 2024

---

## Core Principle

**If you wouldn't stake your reputation on it, don't state it.**

Every claim made in conversation, research, or content must be verifiable, quantifiable, or explicitly acknowledged as unverified. No exceptions.

**95%+ confidence required for any claim that drives build decisions, costs money, or establishes credibility.**

---

## The Violation That Created This Protocol

**What happened:**
- Claimed B7 RS4 was "wagon-only" in US market (FALSE - sedans were primary)
- Stated pricing at "$55-75k" (FALSE - actual market $25-40k, off by 100%)
- Used word "rare" without quantification (IMPRECISE - meaningless without data)

**Impact:**
- Destroyed credibility in real-time
- Violated 95%+ confidence standard
- Demonstrated need for enforced verification workflow

**Lesson:**
Guidelines without enforcement fail. This protocol ENFORCES verification before claims are made.

---

## Source Tier System

**(Reference: See technical-research-spec.md and historical-research-spec.md for complete definitions)**

### Tier 1 Sources (Primary - Ground Truth)
- Factory Service Manuals
- OEM Technical Service Bulletins
- Factory specifications (published by manufacturer)
- Verified dyno sheets from calibrated equipment
- Patent documents
- SAE technical papers

### Tier 2 Sources (Secondary - Trusted Industry)
- Established tuning houses with documented builds
- Professional automotive journalists (Car & Driver, Road & Track, Motor Trend)
- Racing sanctioning bodies (SCCA, NASA)
- Parts manufacturers with engineering data
- Industry analysts and verified experts

### Tier 3 Sources (Tertiary - Community Validated)
- Forum builds with photo documentation and results
- YouTube builders with proven track records
- Multiple corroborating community sources
- Owner experiences (for perception, not technical facts)

### Disallowed Sources
- Single-source forum claims without verification
- Manufacturer marketing without supporting data
- Subjective claims ("butt dyno," "feels faster")
- Anything that can't be traced to verifiable origin

---

## Verification Workflow

### Step 1: Formulate Precise Research Question

**NOT acceptable:**
- "Are RS4 cabriolets rare?"
- "How much do they cost?"
- "Is it fast?"

**ACCEPTABLE:**
- "What were the US import quantities for B7 RS4 sedan vs cabriolet, 2007-2008?"
- "What is the current used market price range for B7 RS4 sedans with 70,000-90,000 miles as of October 2024?"
- "What is the manufacturer-claimed 0-60 mph time for the B7 RS4, and what did independent testing verify?"

**Key difference:** Specific, quantifiable, answerable with data

### Step 2: Research With Quantification Goals

**Look for:**
- Exact numbers (units, percentages, measurements)
- Date ranges (when, how long, what years)
- Verifiable specifications (dimensions, power, weight, torque)
- Documented occurrences (frequency, sample size, methodology)
- Price data (currency, timeframe, source, sample size)

**Avoid:**
- Subjective assessments ("rare," "common," "good," "bad")
- Vague quantities ("many," "few," "most," "some")
- Unattributed claims ("people say," "generally known")
- Assumptions filling gaps ("probably," "seems like")

### Step 3: Document Sources & Data

**Required format for EVERY research finding:**

```markdown
**Research Question:** [Specific question being answered]

**Source 1:** [Full name/URL]
- Tier: [1/2/3]
- Date Accessed: YYYY-MM-DD
- Data Found: [Exact quote or specific data]
- Relevance: [How it answers the question]
- Confidence in Source: [High/Medium/Low - why?]

**Source 2:** [Full name/URL]
- Tier: [1/2/3]
- Date Accessed: YYYY-MM-DD
- Data Found: [Exact quote or specific data]
- Relevance: [How it answers the question]
- Confidence in Source: [High/Medium/Low - why?]

**Conflicts:** [Any disagreements between sources - explain]
**Gaps:** [What data is still missing]
**Confidence Level:** [Overall confidence in findings - see scoring below]
```

### Step 4: Score Confidence Level

| Confidence | Criteria | Action |
|---|---|---|
| **95%+** | 2+ Tier 1 sources agree, OR 1 Tier 1 + 2 Tier 2 sources agree | State as fact with sources cited |
| **80-94%** | 2+ Tier 2 sources agree, OR 1 Tier 1 source only | State with qualifier: "Based on [source]..." |
| **60-79%** | Mix of Tier 2/3 sources, some agreement | State as "Unverified: Evidence suggests..." |
| **<60%** | Single source, Tier 3, or contradictory data | Do NOT state as fact. Note as "[Requires verification]" |

### Step 5: Write The Verified Claim

**Format depends on confidence level:**

#### 95%+ Confidence - State as Fact
```markdown
**VERIFIED CLAIM (95%+):**
"The B7 RS4 was imported to the US market in sedan and cabriolet body styles from 2007-2008. Approximately 2,000 units were imported, with sedans representing approximately 90% of imports based on current market distribution analysis."

**Sources:**
- CarGurus listing analysis (50 active listings, 2024-10-04): 90% sedan, 10% cabriolet
- AudiWorld B7 RS4 Registry (community data, 2015-2024): Similar proportion
- Estimated total imports from dealer allocation data (unverified official figures)

**Confidence:** 85% (strong market data, official import figures unavailable)
**Limitations:** Exact OEM import quantities not published; estimate based on proxy data
```

#### 80-94% Confidence - State with Qualifier
```markdown
**CLAIM (85% confidence):**
"Based on current market analysis (CarGurus, 50 listings, 2024-10-04), B7 RS4 sedans represent approximately 90% of available inventory vs 10% cabriolets, suggesting sedan was the more common body style. Official import figures are not currently available to confirm exact proportions."

**Sources:** [List]
**Limitations:** [Explain]
```

#### <80% Confidence - Do Not State as Fact
```markdown
**UNVERIFIED:**
"B7 RS4 import quantities by body style require verification from manufacturer or import records. Market data suggests sedan predominance but lacks official confirmation."

**Research Status:** In progress
**Next Steps:** Attempt to obtain official Audi USA import data
```

---

## Language Precision Requirements

**(See writing-style-guide.md Language Precision Standards section for complete rules)**

### Banned Without Quantification
- "rare", "common", "many", "few", "most", "often", "popular", "expensive", "cheap"
- "fast", "slow", "reliable", "unreliable"
- "better", "worse" (without specific metric)

### Required Format

| Banned Vague Term | Required Precise Replacement |
|---|---|
| "rare" | "X units produced" or "Y% of total" |
| "expensive" | "$X-$Y (source, date)" |
| "fast" | "X.X seconds 0-60" |
| "many" | "X instances" or "Y%" |
| "often" | "X% of cases" or "every Y miles" |
| "reliable" | "Failure rate: X per Y units" or "MTBF: Z hours" |

### The Absolutes Rule

**Only use "always", "never", "all", "none", "can't", "impossible" when:**
- Physically/mechanically provable (100% or 0% occurrence)
- Can be verified across ALL instances
- No exceptions exist or could exist

**Examples:**
- ✅ "All RS4 models include Quattro AWD" (defining feature, no exceptions)
- ❌ "This modification never causes problems" (absence of evidence ≠ evidence of absence)

---

## Handling Data Gaps

### When You Can't Find Exact Data

**Option 1: State What You Know, Acknowledge What You Don't**
```markdown
"The B7 RS4 was available as sedan and cabriolet in the US market (2007-2008). Exact import quantities by body style are not currently available from manufacturer sources."
```

**Option 2: Use Proxy Data With Clear Limitations**
```markdown
"Based on 50 current market listings (CarGurus, 2024-10-04), sedans represent 90% of available inventory vs 10% cabriolets. While this suggests sedans were more common, official import data is required to confirm the actual production split."
```

**Option 3: Mark as Research Gap**
```markdown
"B7 RS4 body style import quantities: [REQUIRES VERIFICATION - Official Audi USA import data not yet located]"
```

### What NOT To Do

❌ Fill gaps with vague qualifiers ("probably rare," "seems common")
❌ State assumptions as facts
❌ Use hedging to imply certainty ("likely," "appears to be")
❌ Make educated guesses without labeling them as such

---

## Real-Time Citation Requirements

### In Conversation

**Before stating ANY factual claim:**

1. **Can I cite a source right now?**
   - YES → State the claim with inline citation
   - NO → Say "I need to verify this - let me research"

2. **Have I verified this with my own research?**
   - YES → Provide source details
   - NO → Do not state as fact

3. **Is my confidence level 95%+?**
   - YES → State as fact with sources
   - NO → Use appropriate qualifier or mark as unverified

**Example of proper real-time citation:**
```
"The B7 RS4 produces 420 hp @ 7,800 rpm and 317 lb-ft @ 5,500 rpm (Audi USA specification sheet, verified by Car & Driver testing 2007)."
```

**NOT:**
```
"The RS4 makes around 420 horsepower."
```

### In Written Content

**Every factual claim requires:**
- Inline citation or footnote
- Source must be traceable (URL, document name, publication)
- Date accessed for online sources
- Specific page/section for documents

---

## Conflict Resolution

### When Sources Disagree

**Step 1: Document the conflict**
```markdown
**Conflict Identified:**
- Source A (Tier 1): Claims 420 hp
- Source B (Tier 2): Claims 414 hp
- Discrepancy: 6 hp difference
```

**Step 2: Investigate the discrepancy**
- Different testing standards? (SAE net vs gross, DIN vs SAE)
- Different model years? (specification changes)
- Different markets? (US vs EU specs)
- Measurement error or methodology difference?

**Step 3: Resolve or acknowledge**

**If resolvable:**
```markdown
"The B7 RS4 produces 420 hp (SAE net) per Audi USA specifications. European specifications list 414 hp (DIN), representing a difference in testing methodology rather than actual output variance."
```

**If unresolvable:**
```markdown
"Reported power output ranges from 414-420 hp depending on source and testing methodology. Audi USA official specification: 420 hp (SAE net)."
```

### Source Priority in Conflicts

1. Tier 1 beats Tier 2
2. Tier 2 beats Tier 3
3. Within same tier: More recent data beats older
4. Within same tier and date: Official manufacturer beats third-party
5. When equal: Document both, note discrepancy

---

## Verification Checklist

**Before making ANY factual claim, verify:**

### Research Quality
- [ ] Research question is specific and quantifiable
- [ ] Minimum 2 sources consulted (or 1 Tier 1 + documentation of thoroughness)
- [ ] Sources documented with tier, date, exact data found
- [ ] Confidence level scored honestly
- [ ] Conflicts identified and investigated

### Language Precision
- [ ] No banned vague qualifiers used without quantification
- [ ] No inappropriate absolutes used
- [ ] All comparatives include specific metrics
- [ ] Quantifiable claims are quantified
- [ ] Data gaps acknowledged explicitly

### Citation Standards
- [ ] Sources citeable and traceable
- [ ] Dates included for time-sensitive data (prices, market conditions)
- [ ] Testing conditions noted where relevant (SAE, ambient temp, etc.)
- [ ] Sample sizes included for statistical claims

### Confidence Alignment
- [ ] Confidence score matches source quality and agreement
- [ ] Claims stated with appropriate qualifiers for confidence level
- [ ] Gaps acknowledged rather than filled with assumptions
- [ ] If <95% confidence, claim is qualified or marked unverified

---

## Examples: Proper Verification Workflow

### Example 1: Verifying Production Numbers

**Research Question:**
"What were the US import quantities for B7 RS4 by body style, 2007-2008?"

**Research Process:**
1. Searched Audi USA press releases (2006-2008) - No specific import data found
2. Searched NHTSA import database - General import categories, not model-specific
3. Analyzed CarGurus active listings (2024-10-04):
   - Sample: 50 B7 RS4 listings
   - Result: 45 sedans (90%), 5 cabriolets (10%)
4. Cross-referenced AudiWorld B7 RS4 Registry:
   - 143 registered vehicles
   - 128 sedans (89.5%), 15 cabriolets (10.5%)
5. Contacted Audi USA media relations - No response (as of 2024-10-04)

**Sources:**
- CarGurus market analysis (Tier 2, current data)
- AudiWorld registry (Tier 3, community data)
- Official sources: Not available

**Conflicts:** None - both sources agree on ~90/10 split
**Gaps:** Official OEM import figures not published
**Confidence:** 85% (strong proxy data, lacks official confirmation)

**Verified Claim:**
"Based on current market analysis of 50 active listings (CarGurus, 2024-10-04) and AudiWorld registry data (143 vehicles), B7 RS4 sedans represent approximately 90% of the US-market population vs 10% cabriolets. This suggests sedans were the predominant body style, though official Audi USA import figures are not currently available to confirm exact quantities."

### Example 2: Verifying Performance Specifications

**Research Question:**
"What is the 0-60 mph time for the 2007 Audi RS4?"

**Research Process:**
1. Audi USA press kit (2006 model announcement):
   - Claimed: 4.8 seconds (manufacturer estimate)
   - Source: Official press release
   - Tier: 1
2. Car & Driver testing (August 2007 issue):
   - Tested: 4.6 seconds
   - Conditions: 70°F, sea level, 1/4 tank fuel
   - Tier: 2
3. Motor Trend testing (July 2007):
   - Tested: 4.7 seconds
   - Conditions: Not specified
   - Tier: 2

**Sources:**
- Audi USA (Tier 1): 4.8s claimed
- Car & Driver (Tier 2): 4.6s tested
- Motor Trend (Tier 2): 4.7s tested

**Conflicts:** 0.2s variance (manufacturer claim vs tested)
**Analysis:** Manufacturer claims are typically conservative; professional testing shows slightly faster times
**Confidence:** 95%+ (multiple verified sources, minor variance explained by testing conditions)

**Verified Claim:**
"The 2007 Audi RS4 achieves 0-60 mph in 4.6-4.8 seconds. Audi USA claims 4.8 seconds (manufacturer estimate), while independent testing verified 4.6 seconds (Car & Driver, August 2007) and 4.7 seconds (Motor Trend, July 2007) under professional test conditions."

### Example 3: Handling Unavailable Data

**Research Question:**
"What is the failure rate for B7 RS4 carbon buildup issues?"

**Research Process:**
1. Searched for official Audi TSBs - Found: TSB references carbon cleaning procedure, no failure rate data
2. Searched AudiWorld forums - Found: 147 owner reports mentioning carbon buildup (2015-2024)
   - Of those: 89 reported cleaning performed
   - Mileage range when cleaned: 28k-65k miles
   - Average: ~42k miles
3. Contacted Audi USA - No official failure rate data provided
4. Searched NHTSA complaints - Found: 12 complaints mentioning performance issues attributed to carbon

**Sources:**
- Owner reports (Tier 3, anecdotal but numerous)
- TSB existence (Tier 1, confirms issue exists)
- Official failure rate: NOT AVAILABLE

**Confidence:** 70% (pattern evident, but no statistical rigor)

**Verified Claim:**
"Carbon buildup is a documented issue on B7 RS4 engines (Audi TSB reference 2013-01). Based on 89 owner-reported cleaning instances documented on AudiWorld forums (2015-2024), cleaning is typically performed between 28,000-65,000 miles (average ~42,000 miles). Official failure rate data is not available from Audi. As with all direct-injection engines, periodic carbon cleaning is recommended preventive maintenance."

**Note:** Avoided saying "common problem" (vague) and instead provided actual data with clear limitations.

---

## Enforcement

**This protocol is MANDATORY for:**
- All research documentation
- All content creation (articles, videos, scripts)
- All conversations where facts are stated
- All competitive analysis
- All technical specifications

**Violations of this protocol:**
- Undermine platform credibility
- Risk reputation damage
- Violate 95%+ confidence standard
- Are unacceptable

**When in doubt:**
- Research before claiming
- Cite sources in real-time
- Acknowledge gaps honestly
- Mark unverified as "[REQUIRES VERIFICATION]"

---

## Version History

**v1.0** (2024-10-04): Initial protocol created in response to RS4 research failures. Establishes mandatory verification workflow, language precision requirements, and enforcement standards.

---

**Remember: If you wouldn't stake your reputation on it, don't state it.**

**The fuel stays in the can until the process is bulletproof.**
