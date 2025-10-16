# Precision Language Standards

**Universal Communication Quality Standard**

**Last Updated:** 2025-10-13
**Status:** Core Standard
**Applies To:** All documentation, specifications, code comments, and technical communication

---

## Core Principle

**Words matter. Facts must support your words.**

Every claim must be quantifiable, verifiable, or explicitly acknowledged as unverified. Subjective qualifiers without supporting data destroy credibility.

**Standard:** If you wouldn't stake your reputation on it, don't state it.

---

## Subjective Qualifiers - Banned Without Quantification

**These words are PROHIBITED unless accompanied by specific data:**

| Banned Word | Why It Fails | Required Replacement |
|---|---|---|
| **"rare"** | Subjective, context-dependent | "X units produced" or "Y% of total" |
| **"common"** | Meaningless without baseline | "Z units sold" or "represents W% of market" |
| **"many"** | Vague, unquantified | Actual number or percentage |
| **"few"** | Equally vague | Actual number or percentage |
| **"most"** | Implies majority without proof | "X% of..." or "Y out of Z cases" |
| **"often"** | Frequency unclear | "In X% of cases" or "Y documented instances" |
| **"popular"** | Perception, not fact | Usage statistics, adoption metrics |
| **"expensive"** | Relative to what? | Price range with currency and date |
| **"cheap"** | Same problem | Exact price or price comparison |
| **"fast"** | Compared to what? | Specific time or performance measurement |
| **"slow"** | Equally useless | Specific time or performance measurement |
| **"reliable"** | Subjective | Failure rate data, MTBF, uptime percentage |
| **"unreliable"** | Same issue | Documented failure modes and frequency |

### Examples of Precision

❌ **Wrong:** "This library is popular."
✅ **Right:** "This library has 45,000 GitHub stars and 2.3M weekly npm downloads (October 2025)."

❌ **Wrong:** "The service is expensive."
✅ **Right:** "The service costs $199/month for the standard tier (October 2025 pricing)."

❌ **Wrong:** "This approach is fast."
✅ **Right:** "This approach completes in 45ms average (benchmarked across 1000 iterations)."

---

## Context Rule

**Relative terms require context.**

Always provide frame of reference:

✅ "150 units vs 1,850 units (7.5% of total)"
✅ "Limited to 500 units globally vs 50,000 total production (1% variant)"

**NOT:**
❌ "Rare variant"
❌ "Limited production"
❌ "Uncommon configuration"

---

## Absolutes - Only When Provable

**Use ONLY when you can prove 100% (or 0%) occurrence:**

| Absolute | When Acceptable | When Prohibited |
|---|---|---|
| **"always"** | Physically/mechanically certain | Behavioral patterns, tendencies |
| **"never"** | Physically impossible | Historical patterns without 100% verification |
| **"all"** | Verified every single instance | Generalizations about groups |
| **"none"** | Verified zero instances exist | Assumptions about absence |
| **"can't"** | Physical/mechanical impossibility | Difficulty or impracticality |
| **"impossible"** | Provably cannot occur | Highly unlikely or unproven |
| **"every"** | Complete verification of all cases | Patterns without full verification |

### Examples of Appropriate Absolutes

✅ "All containers in this cluster include health checks" (verifiable - it's a requirement)
✅ "This function never returns null" (TypeScript type system guarantees it)
✅ "You cannot deploy without passing tests" (CI/CD enforced)

### Examples of Inappropriate Absolutes

❌ "This system always handles errors gracefully" (behavioral pattern, not certain)
❌ "This optimization never causes problems" (absence of evidence ≠ evidence of absence)
❌ "All users prefer this interface" (requires verification of every user)

---

## Vague Comparatives - Require Specific Metrics

**Comparisons must be quantified:**

| Vague Comparative | Required Precision |
|---|---|
| **"better"** | "20% faster" or "reduces errors by 15%" |
| **"worse"** | Specific metric showing deficiency |
| **"faster"** | Time difference or throughput measurement |
| **"slower"** | Time difference or throughput measurement |
| **"lighter"** | Size/weight difference in KB/MB |
| **"heavier"** | Size/weight difference in KB/MB |
| **"more reliable"** | Uptime percentage or error rate comparison |
| **"more efficient"** | Resource usage metrics or performance data |

### Examples

❌ **Wrong:** "The new algorithm is faster."
✅ **Right:** "The new algorithm completes in 120ms vs 340ms (65% faster, benchmarked N=1000)."

❌ **Wrong:** "This approach is much better."
✅ **Right:** "This approach reduces memory usage from 450MB to 180MB (60% reduction) with equivalent throughput."

---

## Quantification Requirements

**Quantify everything possible. If you can measure it, measure it.**

**Performance:**
- ✅ "Response time: 45ms p50, 120ms p99"
- ❌ "Fast response time"

**Pricing:**
- ✅ "$49/month (Standard tier, October 2025)"
- ❌ "Affordable pricing"

**Time:**
- ✅ "Build completes in 3.2 minutes average"
- ❌ "Quick build"

**Frequency/Occurrence:**
- ✅ "Occurs in 3.5% of requests (last 30 days, N=2.4M)"
- ❌ "Rarely occurs"

**Proportion:**
- ✅ "85% of users enable this feature (N=12,400 active users)"
- ❌ "Most users enable this"

---

## When You Can't Quantify - State The Gap

**If precise data is unavailable, explicitly acknowledge it:**

**Option 1: State what you DO know, acknowledge what you DON'T**
✅ "The service was available from 2020-2023. Exact user count during that period requires verification from vendor."

**Option 2: Use available proxy data with clear limitations**
✅ "Based on 50 GitHub issues mentioning this feature (2020-2024), approximately 60% reported successful implementation. This suggests the feature works for most users, though official success rate data is not available."

**Option 3: Explain the limitation**
✅ "Vendor has not published performance benchmarks. Performance characteristics remain unverified pending access to test environment."

**NOT:**
❌ Fill the gap with vague qualifiers ("probably fast," "seems reliable")
❌ State assumptions as facts
❌ Use hedging language to imply certainty

---

## Hedging Language - Use Transparently

**When using approximations, explain WHY precision isn't available:**

✅ "Approximately 150 deployments per month (estimated from CI/CD logs, exact count pending audit)"
✅ "Around 30 minutes average (user-reported average, n=47, varies by configuration)"
✅ "~$35,000 annual cost (October 2025, ±$5k depending on usage patterns)"

**The tilde (~) or "approximately" requires explanation:**
- Why isn't exact data available?
- What's the source of the estimate?
- What's the confidence level?

---

## Example: Precision Language in Practice

**Before (Imprecise):**
> "This is a great library with awesome performance. It's really popular and many developers love using it. The API is clean and it's much better than alternatives. It rarely has bugs and the maintainers are very responsive."

**After (Precise):**
> "This library (v3.2.0) averages 45ms response time in our benchmarks (N=1000, Oct 2025). It has 45,000 GitHub stars and 2.3M weekly npm downloads. The API provides type-safe interfaces with comprehensive TypeScript support. Compared to [Alternative A], it reduces memory usage by 40% (450MB → 270MB in production). It has 12 open bugs (severity: 2 high, 10 low) with average issue response time of 2.1 days (last 90 days, N=156 issues)."

**Key improvements:**
- Specific performance metrics with testing conditions
- Quantified popularity with actual numbers
- API benefits stated factually (type-safe, TypeScript)
- Comparison quantified with percentage and measurements
- Bug count and response time data with timeframe
- All claims traceable to verifiable sources

---

## Precision Language Audit Checklist

**Before ANY content publishes, audit every sentence:**

### Banned Subjective Qualifiers
- [ ] No use of "rare", "common", "many", "few", "most", "often" without quantification
- [ ] All comparative terms include specific metrics
- [ ] All frequency terms replaced with percentages or counts

### Inappropriate Absolutes
- [ ] "Always", "never", "all", "none" used only when provably 100%/0%
- [ ] Behavioral patterns use "typically", "in X% of cases", not absolutes

### Quantification
- [ ] All performance metrics include units and testing conditions
- [ ] All prices include currency, timeframe, and tier/plan
- [ ] All frequency claims include rate or count
- [ ] All comparisons state baseline and measurement

### Data Gaps
- [ ] Unverified claims explicitly noted as "[Requires verification]"
- [ ] Approximations explained with source and confidence level
- [ ] Missing data acknowledged, not filled with vague qualifiers

### Context
- [ ] Relative terms include comparative context
- [ ] Comparisons state what's being compared to what
- [ ] Measurements include conditions and sample sizes

**If ANY item fails audit: Revise before publication.**

---

## Enforcement

**This standard applies to:**
- All technical documentation
- All specifications and requirements
- All code comments explaining behavior
- All commit messages making claims
- All PR descriptions
- All architecture decision records

**Violations:**
- Undermine technical credibility
- Create ambiguity in requirements
- Lead to misaligned expectations
- Are unacceptable

**When in doubt:**
- Quantify with data
- Acknowledge gaps honestly
- Mark unverified as "[REQUIRES VERIFICATION]"

---

**Remember: Precision in language reflects precision in thinking.**
