# Fact Verification Protocol

**Universal Research and Verification Standard**

**Last Updated:** 2025-10-13
**Status:** Core Standard
**Applies To:** All research, documentation, specifications, and technical claims

---

## Core Principle

**If you wouldn't stake your reputation on it, don't state it.**

Every claim must be verifiable, quantifiable, or explicitly acknowledged as unverified. No exceptions.

**95%+ confidence required for any claim that drives decisions, costs resources, or establishes credibility.**

---

## Source Tier System

### Tier 1 Sources (Primary - Ground Truth)
- Official documentation (language docs, framework docs, API references)
- Vendor technical specifications (published by manufacturer/vendor)
- Academic papers (peer-reviewed, published in reputable journals)
- Standards bodies (RFC, W3C, IETF, ISO)
- Primary source code (when reading directly from repository)
- Verified benchmark results (with methodology documented)

### Tier 2 Sources (Secondary - Trusted Industry)
- Established technical blogs (engineering teams at major companies)
- Professional technical media (reputable tech journalism)
- Recognized technical experts (verified credentials)
- Open source project maintainers (official responses)
- Conference talks (from recognized experts)
- Technical books (published by reputable publishers)

### Tier 3 Sources (Tertiary - Community Validated)
- Stack Overflow (highly-voted answers with verification)
- GitHub issues/discussions (project maintainer responses)
- Technical forums (cross-referenced with multiple sources)
- Developer community posts (with verification)

### Disallowed Sources
- Single-source claims without verification
- Marketing materials without supporting technical data
- Unattributed claims ("everyone knows", "commonly accepted")
- Subjective opinions without data ("I think", "probably")

---

## Verification Workflow

### Step 1: Formulate Precise Research Question

**NOT acceptable:**
- "Is this library good?"
- "How fast is it?"
- "Is it popular?"

**ACCEPTABLE:**
- "What is the average response time for this library under 1000 concurrent requests?"
- "What is the adoption rate of this library measured by npm downloads per month?"
- "What are the documented limitations of this approach?"

**Key difference:** Specific, quantifiable, answerable with data

### Step 2: Research With Quantification Goals

**Look for:**
- Exact numbers (units, percentages, measurements)
- Date ranges (when, how long, what versions)
- Verifiable specifications (dimensions, performance, behavior)
- Documented occurrences (frequency, sample size, methodology)
- Comparative data (benchmarks, A/B tests, before/after)

**Avoid:**
- Subjective assessments ("good", "bad", "fast", "slow")
- Vague quantities ("many", "few", "most", "some")
- Unattributed claims ("people say", "generally known")
- Assumptions filling gaps ("probably", "seems like")

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
| **60-79%** | Mix of Tier 2/3 sources, some agreement | State as "Evidence suggests..." |
| **<60%** | Single source, Tier 3, or contradictory data | Do NOT state as fact. Note as "[Requires verification]" |

### Step 5: Write The Verified Claim

**Format depends on confidence level:**

#### 95%+ Confidence - State as Fact
```markdown
**VERIFIED (95%+):**
"PostgreSQL 16 introduces parallel query execution for aggregate functions, improving performance by 40-60% for large datasets (official PostgreSQL 16 release notes, verified by independent benchmarks from Percona, October 2023)."

**Sources:**
- PostgreSQL 16 Release Notes (Tier 1)
- Percona Benchmark Study (Tier 2)

**Confidence:** 95%+
```

#### 80-94% Confidence - State with Qualifier
```markdown
**CLAIM (85% confidence):**
"Based on npm download statistics (Oct 2025, 2.3M weekly downloads) and GitHub activity (45k stars, 892 contributors), this library has strong community adoption. Official usage statistics are not published by the project."

**Sources:** [List]
**Limitations:** [Explain]
**Confidence:** 85%
```

#### <80% Confidence - Do Not State as Fact
```markdown
**UNVERIFIED:**
"Performance characteristics under high load require verification. Initial testing suggests acceptable performance, but production-scale benchmarks are needed."

**Research Status:** In progress
**Next Steps:** Conduct load testing with production-scale data
**Confidence:** <60%
```

---

## Handling Conflicting Data

### When Two Sources Disagree

**The "Flashing Neon Sign" - Conflicting data is a RED FLAG.**

**Step 1: Acknowledge BOTH Data Points**

```markdown
**Conflict Identified:**
- Source A (Tier 1): Claims 45ms average latency
- Source B (Tier 2): Claims 120ms average latency
- Discrepancy: 167% difference
```

**Step 2: Investigate the Discrepancy**

Ask critical questions:
- What is each source actually measuring?
- Do they use different methodologies?
- Are testing conditions different?
- Which measurement is relevant to your use case?
- Is one more authoritative than the other?

**Step 3: Determine Authority**

Priority order:
1. **Direct measurement** > Calculated estimate
2. **Tier 1 sources** > Tier 2/3 sources
3. **More recent data** > Older data
4. **More relevant conditions** > Less relevant conditions
5. **Conservative estimate** when uncertain

**Step 4: State Finding With Confidence Level**

**If authority is clear:**
```markdown
**Authoritative Measurement:** Official benchmarks show 45ms p50 latency under standard conditions.

**Note:** Third-party testing showed 120ms, but used non-optimized configuration. Official benchmarks with recommended settings are authoritative.

**Confidence:** 95%
```

**If conflict is unresolvable:**
```markdown
**Conflicting Data:**
- Source A: 45ms average
- Source B: 120ms average

**Investigation:** Different testing methodologies (Source A: in-memory, Source B: disk-backed).

**Range stated:** 45-120ms depending on configuration.

**Confidence:** 80% (both sources credible, configuration variance explains difference)

**[REQUIRES FURTHER VERIFICATION]** - Need testing under our specific configuration
```

---

## Handling Data Gaps

### When You Can't Find Exact Data

**Option 1: State What You Know, Acknowledge What You Don't**
```markdown
"The library was maintained from 2018-2023. Current maintenance status is unclear (last commit: 2023-03-15, no response to recent issues)."
```

**Option 2: Use Proxy Data With Clear Limitations**
```markdown
"Based on GitHub star growth rate (450 stars/month, last 6 months), adoption appears to be increasing. This suggests growing community interest, though official usage statistics are not available."
```

**Option 3: Mark as Research Gap**
```markdown
"Performance under production load: [REQUIRES VERIFICATION - Load testing pending]"
```

### What NOT To Do

❌ Fill gaps with vague qualifiers ("probably fast," "seems reliable")
❌ State assumptions as facts
❌ Use hedging to imply certainty ("likely," "appears to be")
❌ Make educated guesses without labeling them

---

## Real-Time Citation Requirements

### In Documentation

**Before stating ANY factual claim:**

1. **Can I cite a source right now?**
   - YES → State the claim with inline citation
   - NO → Research first, then write

2. **Have I verified this with my own research?**
   - YES → Provide source details
   - NO → Do not state as fact

3. **Is my confidence level 95%+?**
   - YES → State as fact with sources
   - NO → Use appropriate qualifier or mark as unverified

**Example of proper citation:**
```markdown
"PostgreSQL supports native JSON operations with indexing (PostgreSQL Documentation v16, jsonb data type), offering performance comparable to dedicated document databases for many use cases (Percona Benchmark Study, Oct 2023)."
```

**NOT:**
```markdown
"PostgreSQL is good with JSON."
```

---

## Conflict Resolution Priority

**When sources disagree:**

1. Tier 1 beats Tier 2
2. Tier 2 beats Tier 3
3. Within same tier: More recent data beats older
4. Within same tier and date: Official documentation beats third-party
5. When equal: Document both, note discrepancy

---

## Verification Checklist

**Before making ANY factual claim, verify:**

### Research Quality
- [ ] Research question is specific and quantifiable
- [ ] Minimum 2 sources consulted (or 1 Tier 1 + thorough documentation)
- [ ] Sources documented with tier, date, exact data
- [ ] Confidence level scored honestly
- [ ] Conflicts identified and investigated

### Language Precision
- [ ] No vague qualifiers used without quantification
- [ ] No inappropriate absolutes used
- [ ] All comparatives include specific metrics
- [ ] Quantifiable claims are quantified
- [ ] Data gaps acknowledged explicitly

### Citation Standards
- [ ] Sources citeable and traceable
- [ ] Dates included for time-sensitive data
- [ ] Testing conditions noted where relevant
- [ ] Sample sizes included for statistical claims

### Confidence Alignment
- [ ] Confidence score matches source quality
- [ ] Claims stated with appropriate qualifiers
- [ ] Gaps acknowledged rather than filled with assumptions
- [ ] If <95% confidence, claim is qualified or marked unverified

---

## Enforcement

**This protocol is MANDATORY for:**
- All technical documentation
- All specifications and requirements
- All architecture decision records
- All benchmarking and performance claims
- All security and compliance statements
- All API documentation

**Violations:**
- Undermine credibility
- Risk incorrect decisions
- Create false expectations
- Are unacceptable

**When in doubt:**
- Research before claiming
- Cite sources
- Acknowledge gaps honestly
- Mark unverified as "[REQUIRES VERIFICATION]"

---

**Remember: If you wouldn't stake your reputation on it, don't state it.**
