# UI/UX SPECIFICATION v1.0
**The Builder Platform - Domain-Agnostic Expert Content Interface**

**Last Updated:** October 6, 2024
**Status:** Product Specification - Ready for Implementation
**Confidence:** 95%+ (validated with owner vision)

---

## Document Purpose

This specification defines the complete user interface and experience for The Builder Platform. It is implementation-ready, providing sufficient detail for designers and developers to build the product.

**Target:** Domain-agnostic platform serving 1,000+ subject matter experts across automotive, culinary, woodworking, and any expertise domain.

---

## Core UX Philosophy

### The Interface Should Feel Like Your Workshop

**Principle:** UI adapts to user's domain while maintaining consistent structure and standards.

**Automotive user** sees: Shop aesthetic - precision engineering, engine components, specs at hand
**Culinary user** sees: Kitchen aesthetic - warm craft, ingredients organized, recipes referenced
**Woodworking user** sees: Bench aesthetic - natural tactile, plans visible, materials laid out

**Same structure. Different atmosphere.**

### Design Principles

1. **Context-Aware**: UI adapts to user's domain (imagery, color accents, visual language)
2. **Progressive Disclosure**: Start simple, reveal complexity as needed
3. **Immediate Feedback**: Every action has visual confirmation
4. **Celebration**: Verification and quality improvements feel rewarding
5. **Precision**: Animations subtle (120-180ms), intentional, spring physics
6. **Confidence**: Generous whitespace, quality doesn't need clutter
7. **Assistance**: Platform supports expert work, doesn't takeover

**Owner's Vision:**
> "Beautiful, simplistic, elegant UI that evolves based on content. A UX that draws you in and says, 'hey, check things out, hang around for a while, let's get your vision published'"

---

## Visual Design System

### Core Brand (Constant Across All Domains)

**Typography:**
- UI Text: Inter (clean, modern, excellent at small sizes)
- Reading Text: Merriweather (serif, comfortable for long-form)
- Code/Data: JetBrains Mono (technical specs, data displays)

**Layout:**
- Generous whitespace (confidence doesn't need clutter)
- 8px base grid system
- Max content width: 1440px
- Reading width: 680px (optimal readability)

**Neutral Base Palette:**
- Background: #FAFAFA (warm white)
- Surface: #FFFFFF (cards, panels)
- Border: #E5E5E5 (subtle divisions)
- Text Primary: #171717 (near black, not pure black)
- Text Secondary: #737373 (reduced emphasis)
- Text Tertiary: #A3A3A3 (hints, labels)

**Animation Principles:**
- Timing: 120-180ms for most transitions
- Easing: Spring physics (not linear, not cubic bezier)
- Purpose: Every animation communicates state change
- Restraint: Subtle, intentional, never gratuitous

### Domain-Specific Theming

**Automotive Domain:**
- **Accent Color:** `#3B82F6` (precision blue) or `#52525B` (gunmetal gray)
- **Secondary Accent:** `#06B6D4` (electric cyan, for highlights)
- **Feature Imagery:** User's engine bay photos, track shots, engineering diagrams
- **Texture:** Subtle brushed metal effect on headers (CSS gradient, barely visible)
- **Iconography:** Angular, mechanical (sharp corners, technical feel)
- **Atmosphere:** Precision engineering - clean, technical, confident

**Culinary Domain:**
- **Accent Color:** `#DC2626` (deep red) or `#92400E` (warm brown)
- **Secondary Accent:** `#F59E0B` (warm amber, for highlights)
- **Feature Imagery:** User's plated dishes, knife skills close-ups, mise en place
- **Texture:** Subtle linen or parchment effect on backgrounds
- **Iconography:** Organic, rounded (soft edges, warm feel)
- **Atmosphere:** Craft kitchen - warm, tactile, inviting

**Woodworking Domain:**
- **Accent Color:** `#78350F` (rich walnut) or `#065F46` (forest green)
- **Secondary Accent:** `#D97706` (amber, for highlights)
- **Feature Imagery:** User's joinery close-ups, wood grain, tools in use
- **Texture:** Subtle wood grain on headers
- **Iconography:** Solid, grounded (stable forms, craft feel)
- **Atmosphere:** Workshop bench - natural, tactile, focused

**Implementation Note:**
- Theme stored in user profile
- CSS custom properties for accent colors
- Component library (ShadCN) styled per theme
- Imagery pulled from user's media library (domain-appropriate)

---

## Interface Structure

### Global Navigation (Persistent)

**Top Navigation Bar:**
```
┌─────────────────────────────────────────────────────┐
│ [Logo] [Domain Icon]     [⌘K Search]    [User] [⚙] │
└─────────────────────────────────────────────────────┘
```

**Components:**
- **Logo:** "Builder Platform" wordmark (left)
- **Domain Icon:** Small icon indicating current domain (automotive, culinary, etc.) - clickable to switch projects
- **⌘K Search:** Command palette trigger - "Search knowledge..."
- **User Avatar:** Profile photo, click for account menu
- **Settings Gear:** Platform settings

**Behavior:**
- Sticky (always visible when scrolling)
- Minimal height: 56px
- Background: Slight blur effect when content scrolls beneath

**Command Palette (⌘K):**
```
┌─────────────────────────────────────────┐
│ 🔍 Search knowledge, projects, logs...  │
├─────────────────────────────────────────┤
│ Recent:                                 │
│  → Q50 VR30 head lifting research       │
│  → Cassoulet Toulouse variant           │
│                                         │
│ Quick Actions:                          │
│  → New Project                          │
│  → New Research                         │
│  → View Knowledge Graph                 │
│  → Conversation Logs                    │
└─────────────────────────────────────────┘
```

**Keyboard Navigation:**
- ⌘K: Open command palette
- ⌘↑↓: Navigate results
- Enter: Execute action
- Esc: Close palette

### Sidebar Navigation (Collapsible)

**Default State (Expanded):**
```
┌────────────────────┐
│ 🏠 Dashboard       │
│ 📊 Projects        │
│ 🔬 Research        │
│ ✍️  Writing         │
│ 🕸️  Knowledge Graph│
│ 📜 Conversation Logs│
│ ⚙️  Settings       │
│                    │
│ ──────────────────│
│                    │
│ Recent Projects:   │
│ • Q50 Super Saloon │
│ • Cassoulet Study  │
└────────────────────┘
```

**Collapsed State:**
```
┌───┐
│ 🏠 │
│ 📊 │
│ 🔬 │
│ ✍️ │
│ 🕸️ │
│ 📜 │
│ ⚙️ │
└───┘
```

**Behavior:**
- Toggle with hamburger icon (top of sidebar)
- Smooth width transition (180ms spring)
- Icons always visible
- Labels fade in/out
- User preference saved

---

## Key Screens & Components

### 1. Dashboard (Landing After Login)

**Purpose:** Context-aware home showing active work, progress, and quick access to knowledge.

**Layout:**

```
┌──────────────────────────────────────────────────────────┐
│ [Top Nav]                                                │
├────┬─────────────────────────────────────────────────────┤
│    │ Welcome back, Bert                                  │
│ S  │                                                      │
│ i  │ ┌────────────────────────────────────────────────┐ │
│ d  │ │ [Domain Feature Image - Blurred Background]    │ │
│ e  │ │                                                │ │
│ b  │ │     Q50 Super Saloon Build                     │ │
│ a  │ │     Research: 65% ████████░░░                  │ │
│ r  │ │     Draft: 2,847 words (confidence: 73%)       │ │
│    │ │     Next: Verify transmission power limits     │ │
│    │ │                                                │ │
│    │ │     [Continue Research] [Open Draft]           │ │
│    │ └────────────────────────────────────────────────┘ │
│    │                                                      │
│    │ Quick Actions:                                      │
│    │ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│    │ │New       │ │Knowledge │ │Recent    │           │
│    │ │Research  │ │Graph     │ │Logs      │           │
│    │ └──────────┘ └──────────┘ └──────────┘           │
│    │                                                      │
│    │ Recent Verifications (95%+ confidence):             │
│    │ ┌────────────────────────────────────────────────┐ │
│    │ │ ✅ VR30 bore x stroke: 86mm x 86mm            │ │
│    │ │    Source: Factory Service Manual (Tier 1)    │ │
│    │ │    Verified: 2 hours ago                       │ │
│    │ └────────────────────────────────────────────────┘ │
│    │ ┌────────────────────────────────────────────────┐ │
│    │ │ ✅ Cassoulet Toulouse variant uses duck confit│ │
│    │ │    Source: Larousse Gastronomique (Tier 1)   │ │
│    │ │    Verified: 1 day ago                         │ │
│    │ └────────────────────────────────────────────────┘ │
│    │                                                      │
│    │ [View All Projects] [Browse Knowledge Graph]        │
└────┴─────────────────────────────────────────────────────┘
```

**Feature Image Section:**
- **Automotive:** Blurred Q50 engine bay, track photo, or dyno chart from user's media
- **Culinary:** Blurred cassoulet plating, knife work, or mise en place
- Overlaid with project name and progress
- Background image cycles through user's uploaded media (every 24 hours)

**Progress Indicators:**
- Research completion: Progress bar with percentage
- Draft status: Word count + confidence score (calculated from verified citations)
- Next milestone: Pulled from research spec checkboxes

**Recent Verifications:**
- Shows last 5 facts verified at 95%+
- Badge for source tier (color-coded)
- Time since verification
- Click to view full source details

**Quick Actions:**
- Large, tappable cards
- Icons from domain theme
- Smooth hover state (lift 2px, shadow increase)

### 2. Research Workspace

**Purpose:** Split-pane interface for researching and verifying facts in parallel.

**Layout:**

```
┌──────────────────────────────────────────────────────────┐
│ [Top Nav]                                                │
├────┬──────────────────────┬──────────────────────────────┤
│    │ Research Spec        │ Findings & Verification       │
│ S  │ ──────────────────── │ ──────────────────────────── │
│ i  │                      │                               │
│ d  │ ▼ VR30DDTT Engine    │ 🔍 Search: "VR30 bore stroke"│
│ e  │   Core Specs ██░░ 60%│                               │
│ b  │                      │ ┌──────────────────────────┐ │
│ a  │   □ Displacement     │ │ Finding #1               │ │
│ r  │   ✓ Bore × Stroke    │ │ VR30 bore: 86mm          │ │
│    │   □ Compression Ratio│ │ VR30 stroke: 86mm        │ │
│    │   ✓ Block Material   │ │                          │ │
│    │   □ Head Lifting     │ │ Source: Factory Service  │ │
│    │                      │ │ Manual (Tier 1) ●        │ │
│    │ ▶ Forced Induction   │ │ Confidence: 95%+         │ │
│    │   System          0% │ │                          │ │
│    │                      │ │ [Verify Fact] [Add Tags] │ │
│    │ ▶ Fueling System  0% │ └──────────────────────────┘ │
│    │                      │                               │
│    │ Overall: 23% complete│ Verified Facts This Session: │
│    │ ████░░░░░░░░░░░░     │ 🎉 3 facts at 95%+           │
│    │                      │                               │
│    │ [Export Research]    │ [Add New Finding]             │
└────┴──────────────────────┴──────────────────────────────┘
```

**Left Pane: Research Spec Template**
- Accordion sections (collapsible)
- Progress bars per section
- Checkboxes for granular tracking
- Overall completion percentage
- Domain-aware (shows VR30 specs OR cassoulet variants)

**Right Pane: Findings & Verification**
- Search bar at top (query knowledge graph for existing research)
- Finding cards:
  - Title
  - Data extracted
  - Source with tier badge
  - Confidence level
  - Actions: Verify, Add Tags, Link to Related
- Session statistics (verified facts count)

**Verification Workflow (Critical UX):**

1. User clicks "Verify Fact" button on finding
2. **Dialog opens:**
   ```
   ┌────────────────────────────────────────┐
   │ Verify Finding                         │
   ├────────────────────────────────────────┤
   │ Claim:                                 │
   │ VR30 bore x stroke: 86mm x 86mm        │
   │                                        │
   │ Source:                                │
   │ Factory Service Manual (V37 Q50)       │
   │                                        │
   │ Source Tier:                           │
   │ ● Tier 1 (Primary)                     │
   │ ○ Tier 2 (Industry)                    │
   │ ○ Tier 3 (Community)                   │
   │                                        │
   │ Confidence:                            │
   │ ━━━━━━━━━━ 95%                        │
   │                                        │
   │ Tags (suggested):                      │
   │ [VR30] [engine-specs] [bore-stroke]    │
   │                                        │
   │ [Cancel] [Verify ✓]                    │
   └────────────────────────────────────────┘
   ```

3. User selects tier, adjusts confidence, accepts tags
4. User clicks "Verify ✓"
5. **Celebration Animation:**
   - Checkmark grows and bounces (spring physics)
   - Confetti burst (subtle, 500ms)
   - Success toast: "Fact verified at 95%! Added to knowledge graph 🎉"
   - Small animated visualization: Node appears in mini-graph preview
6. Finding card updates with green border, verified badge
7. Research spec checkbox auto-checks
8. Overall completion percentage increases with smooth animation

**Why This Matters:**
- Verification feels rewarding, not tedious
- Immediate visual feedback reinforces behavior
- Platform celebrates quality work
- Users want to verify more facts (gamification through delight)

**Conflict Detection UI:**

When two sources give different data for same spec:
```
⚠️ Conflict Detected

Source A (FSM): VR30 compression ratio 10.3:1
Source B (Tuner): VR30 compression ratio 10.0:1

Discrepancy: 0.3 difference

[Acknowledge Both] [Investigate] [Mark for Resolution]
```

Forces user to resolve before marking verified (enforces fact-verification protocol).

### 3. Writing/Content Creation

**Purpose:** Distraction-free writing with verification support sidebar.

**Layout (Hero Mode - Full Screen):**

```
┌──────────────────────────────────────────────────────────┐
│ The Overlooked Q50: 600hp Gentleman's Weapon             │
├──────────────────────────────────────────────────────────┤
│                                                           │
│   The Infiniti Q50 Red Sport 400 stands as one of the   │
│   most technically sophisticated sport sedans of the     │
│   2010s, yet remains criminally undervalued in the       │
│   enthusiast market.                                     │
│                                                           │
│   At its heart lies the VR30DDTT—a 3.0L twin-turbo V6   │
│   with bore and stroke of 86mm x 86mm ¹ (square design  │
│   optimized for high-rpm power and low-end torque).     │
│                                                           │
│   [Cursor blinking...]                                   │
│                                                           │
│                                                           │
│   ────────────────────────────────────────────────────  │
│                                                           │
│   Confidence: 73% ███████████████░░░░░                  │
│   Words: 2,847                                           │
│   Reading time: 11 min                                   │
│                                                           │
│   Sources: 12 (Tier 1: 7, Tier 2: 4, Tier 3: 1)        │
│                                                           │
│   [Exit Hero Mode] [⌘K Verify]                          │
└──────────────────────────────────────────────────────────┘
```

**Typography (Reading Mode):**
- Font: Merriweather 18px / 32px line height
- Max width: 680px (centered)
- Color: #171717 on #FAFAFA
- Margins: Generous (min 80px sides on desktop)

**Inline Citations:**
- Superscript numbers (e.g., ¹ ² ³)
- Hover shows full source in tooltip
- Click opens source detail modal

**Bottom Status Bar:**
- Confidence score with visual progress ring
- Word count, reading time estimate
- Source tier distribution
- Actions: Exit hero mode, Open verification sidebar

**Verification Sidebar (⌘K to summon):**

```
┌────────────────────────────────────────┐
│ 🔍 Search verified research            │
├────────────────────────────────────────┤
│ Recent Verifications:                  │
│ ┌────────────────────────────────────┐ │
│ │ VR30 bore x stroke: 86mm x 86mm    │ │
│ │ Tier 1 ● FSM                       │ │
│ │ [Insert Citation]                  │ │
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ Head lifting threshold: 22+ psi    │ │
│ │ Tier 2 ● Tuner data                │ │
│ │ [Insert Citation]                  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ Language Precision Suggestions:        │
│ ⚠️ Line 47: "rare"                     │
│    Suggest: "150 units / 7.5%"         │
│    [Accept] [Dismiss]                  │
│                                        │
│ Confidence Breakdown:                  │
│ ● Tier 1 sources: 58%                  │
│ ● Tier 2 sources: 33%                  │
│ ● Tier 3 sources: 8%                   │
│ ━━━━━━━━━━━━━━━━━ 73%                 │
│                                        │
│ [Close Sidebar]                        │
└────────────────────────────────────────┘
```

**Sidebar Features:**
- Search verified research (query knowledge graph)
- Drag verified fact into content → auto-inserts citation
- Language precision checker (highlights vague terms, suggests quantification)
- Real-time confidence scoring (increases as verified citations added)
- Source tier distribution visualization

**Language Precision Checker (Active):**
- Scans content for banned words ("rare", "expensive", "fast", "traditional", etc.)
- Highlights in yellow with suggestion
- Accept = replaces text + micro-celebration
- Dismiss = removes suggestion (user knows better)
- Feels like helpful editor, not grammar police

**Confidence Score Calculation:**
- Percentage of claims backed by verified research
- Weighted by source tier (Tier 1 = 1.0, Tier 2 = 0.8, Tier 3 = 0.6)
- Live updates as citations added
- Visual goal: 95%+ for publication

### 4. Knowledge Graph Visualization

**Purpose:** Interactive exploration of accumulated knowledge and connections.

**Layout:**

```
┌──────────────────────────────────────────────────────────┐
│ Knowledge Graph                            [Filters] [⚙] │
├──────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐   │
│ │                                                    │   │
│ │         ●────● VR30                                │   │
│ │        /      │ \                                  │   │
│ │   Q50 ●       │   ● Head Lifting                  │   │
│ │        \      │   /  Lesson                        │   │
│ │         ●────●──●                                  │   │
│ │      Red Sport  │                                  │   │
│ │                 │                                  │   │
│ │                 ● DCT Requirement                  │   │
│ │                  \                                 │   │
│ │                   ● S7 Platform                    │   │
│ │                                                    │   │
│ │   [Interactive canvas - zoom, pan, click nodes]   │   │
│ └────────────────────────────────────────────────────┘   │
│                                                           │
│ Node Details (Selected: VR30):                           │
│ ┌────────────────────────────────────────────────────┐   │
│ │ VR30DDTT Engine                                    │   │
│ │ Type: Technical Specification                      │   │
│ │ Domain: Automotive                                 │   │
│ │ Confidence: 95%+ ●●●●●                            │   │
│ │                                                    │   │
│ │ Related:                                           │   │
│ │ • Q50 Super Saloon (project)                       │   │
│ │ • Head Lifting Lesson (lesson)                     │   │
│ │ • DCT Requirement (decision)                       │   │
│ │                                                    │   │
│ │ Verified Facts: 23                                 │   │
│ │ Content References: 5 articles, 2 videos           │   │
│ │                                                    │   │
│ │ [View All Facts] [Related Content]                 │   │
│ └────────────────────────────────────────────────────┘   │
│                                                           │
│ Timeline: [────●────●────●────] Oct 2024                 │
│            ↑     ↑     ↑                                  │
│          Initial Research  Decision  Latest               │
└──────────────────────────────────────────────────────────┘
```

**Visual Encoding:**
- **Node Size:** Confidence level (bigger = more verified research)
- **Node Color:** Domain (blue automotive, red culinary, brown woodworking)
- **Edge Thickness:** Relationship strength (thicker = more connections)
- **Node Shape:** Type (circle = spec, square = project, diamond = decision, hexagon = lesson)

**Interactions:**
- **Pan:** Click and drag background
- **Zoom:** Scroll wheel or pinch
- **Select Node:** Click → shows details panel
- **Hover Node:** Tooltip with name and type
- **Filter:** Toggle domains on/off (show automotive only, or all)
- **Time Slider:** See knowledge graph grow over time (animated)

**Filters Panel:**
```
┌────────────────────┐
│ Show Domains:      │
│ ☑ Automotive       │
│ ☑ Culinary         │
│ ☐ Woodworking      │
│                    │
│ Node Types:        │
│ ☑ Projects         │
│ ☑ Specifications   │
│ ☑ Decisions        │
│ ☑ Lessons          │
│                    │
│ Confidence:        │
│ ━━━━━━●━━━         │
│ 75%+ only          │
│                    │
│ [Reset Filters]    │
└────────────────────┘
```

**Time Slider Feature:**
- Bottom of graph
- Drag slider from Month 1 → Month 12
- Graph animates nodes appearing chronologically
- Shows knowledge compounding over time
- **The "Wow" moment** - user sees their expertise visualized growing

**The "Aha" Cross-Domain Insight:**
```
💡 Pattern Detected

Your cassoulet regional verification methodology
matches the approach used in Q50 platform research.

Both use:
• Tier 1 source validation
• 95%+ confidence requirement
• Regional/variant comparison framework

[View Methodology] [Apply to New Project]
```

Platform highlights when user applies same methodology across domains (demonstrates intelligence).

### 5. Conversation Log Timeline

**Purpose:** Browse learning history, find past decisions and lessons.

**Layout:**

```
┌──────────────────────────────────────────────────────────┐
│ Conversation Logs                    [Search] [Filter]   │
├──────────────────────────────────────────────────────────┤
│                                                           │
│ ┌────────────────────────────────────────────────────┐   │
│ │ 2024-10-06 - Domain-Agnostic Vision & UI Planning │   │
│ │ Session Type: Platform Evolution                   │   │
│ │ Context: Logged at 62% remaining                   │   │
│ │                                                    │   │
│ │ Key Outcomes:                                      │   │
│ │ • Domain-agnostic architecture established         │   │
│ │ • UI/UX strategy developed                         │   │
│ │ • Scalability vision: 1,000 SMEs                   │   │
│ │                                                    │   │
│ │ Tags: #ui-ux #domain-agnostic #scalability         │   │
│ │                                                    │   │
│ │ [Read Full Log] [Export]                           │   │
│ └────────────────────────────────────────────────────┘   │
│                                                           │
│ ┌────────────────────────────────────────────────────┐   │
│ │ 2024-10-04 - Critical Data Conflict Lesson        │   │
│ │ Session Type: Quality Standards - Meta-lesson      │   │
│ │ Context: Logged at 5% remaining (CRITICAL)         │   │
│ │ ⚠️ Important Lesson                                │   │
│ │                                                    │   │
│ │ Key Outcomes:                                      │   │
│ │ • Auto-compact metric is authoritative             │   │
│ │ • 20% buffer prevents data loss                    │   │
│ │ • Conflicting data resolution process              │   │
│ │                                                    │   │
│ │ Tags: #critical-lesson #data-conflict #20-buffer   │   │
│ │                                                    │   │
│ │ [Read Full Log] [Export]                           │   │
│ └────────────────────────────────────────────────────┘   │
│                                                           │
│ [Load More Logs...]                                       │
└──────────────────────────────────────────────────────────┘
```

**Card Visual Weight:**
- **Normal logs:** Standard card
- **Important lessons:** Slightly larger, yellow left border
- **Critical lessons:** Larger, red left border, ⚠️ icon

**Search & Filter:**
- Search: Full-text search across all logs
- Filter by:
  - Tags (#quality-standards, #VR30, #cassoulet)
  - Session type (Platform Evolution, Quality Standards, Research)
  - Context status (logged at X% remaining)
  - Date range

**Actions:**
- Read Full Log: Opens log in reading view (beautiful typography)
- Export: Download as Markdown or PDF
- Share: Generate shareable link (if user wants to share lesson)

---

## First-Time User Experience (FTUE)

### Goal: "Hey, Check It Out, Hang Around"

**Onboarding Flow:**

#### Step 1: Landing Page (Logged Out)

```
┌──────────────────────────────────────────────────────────┐
│                                                           │
│                  The Builder Platform                     │
│                                                           │
│        Expert Content with Compounding Quality           │
│                                                           │
│   Whether you're researching VR30 forced induction       │
│   or cassoulet regional variants, the methodology is     │
│   the same: 95%+ verification, language precision,       │
│   total context preservation, knowledge that compounds.  │
│                                                           │
│                                                           │
│         [Start Your First Project]                        │
│                                                           │
│               [See How It Works]                          │
│                                                           │
│                                                           │
│   [Beautiful abstract visualization of knowledge graph]  │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

**"See How It Works" Interactive Demo:**
- Animated walkthrough (no account required)
- Shows: Research → Verification → Writing flow
- Graph visualization growing
- Domain examples cycling (automotive, culinary, woodworking)
- 30 seconds, skippable

#### Step 2: Domain Selection

```
┌──────────────────────────────────────────────────────────┐
│ Choose Your Domain                                        │
│                                                           │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│ │              │ │              │ │              │      │
│ │ [Engine Img] │ │ [Food Img]   │ │ [Wood Img]   │      │
│ │              │ │              │ │              │      │
│ │  Automotive  │ │   Culinary   │ │ Woodworking  │      │
│ │              │ │              │ │              │      │
│ │ Build a Q50  │ │ Cassoulet    │ │ Joinery      │      │
│ │ 600hp weapon │ │ mastery      │ │ precision    │      │
│ │              │ │              │ │              │      │
│ └──────────────┘ └──────────────┘ └──────────────┘      │
│                                                           │
│                  ┌──────────────┐                         │
│                  │              │                         │
│                  │ [Custom...]  │                         │
│                  │              │                         │
│                  │  Something   │                         │
│                  │  else?       │                         │
│                  │              │                         │
│                  └──────────────┘                         │
└──────────────────────────────────────────────────────────┘
```

**Cards:**
- Beautiful domain-appropriate imagery
- Example project shown
- Hover state: Lift and shadow increase
- Click: Proceeds to project setup

#### Step 3: Project Setup

```
┌──────────────────────────────────────────────────────────┐
│ [Blurred engine bay background - automotive selected]    │
│                                                           │
│              Create Your First Project                    │
│                                                           │
│   Project Name:                                           │
│   ┌────────────────────────────────────────────────────┐ │
│   │ Q50 Super Saloon 600hp Build                       │ │
│   └────────────────────────────────────────────────────┘ │
│                                                           │
│   What will you research?                                │
│   ┌────────────────────────────────────────────────────┐ │
│   │ VR30DDTT engine specs, transmission limits, build  │ │
│   │ path to 600-800hp                                  │ │
│   └────────────────────────────────────────────────────┘ │
│                                                           │
│   Content goals:                                         │
│   ☑ Long-form articles                                  │
│   ☑ Video content                                       │
│   ☐ Speaking presentations                              │
│                                                           │
│                                                           │
│                    [Create Project]                       │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

**Background:**
- Domain-appropriate blurred imagery (changes based on domain selected)
- Subtle overlay for text readability
- Feels immersive, not generic

#### Step 4: Guided First Verification (The Hook)

**Most Critical UX Moment** - This is where users "get it"

```
┌──────────────────────────────────────────────────────────┐
│ Let's verify your first fact                             │
│                                                           │
│ This is the foundation of everything you'll build.       │
│ We'll walk you through it step by step.                  │
│                                                           │
│ ┌────────────────────────────────────────────────────┐   │
│ │ What are you researching?                          │   │
│ │ ┌──────────────────────────────────────────────┐   │   │
│ │ │ VR30DDTT engine specifications               │   │   │
│ │ └──────────────────────────────────────────────┘   │   │
│ └────────────────────────────────────────────────────┘   │
│                                                           │
│                      [Next Step →]                        │
│                                                           │
│ Progress: ●○○○○ Step 1 of 5                              │
└──────────────────────────────────────────────────────────┘
```

**Step 2:**
```
│ What did you find?                                       │
│ ┌──────────────────────────────────────────────────┐   │
│ │ VR30 bore: 86mm                                  │   │
│ │ VR30 stroke: 86mm                                │   │
│ └──────────────────────────────────────────────────┘   │
│                                                           │
│ Progress: ●●○○○ Step 2 of 5                              │
```

**Step 3:**
```
│ Where did you find this?                                 │
│ ┌──────────────────────────────────────────────────┐   │
│ │ Infiniti Factory Service Manual (V37 Q50)        │   │
│ └──────────────────────────────────────────────────┘   │
│                                                           │
│ Is this a primary source (factory docs, engineering     │
│ data), industry source (tuner shops, experts), or       │
│ community source (proven builds, verified forums)?      │
│                                                           │
│ ● Tier 1 - Primary (Most reliable)                      │
│ ○ Tier 2 - Industry                                     │
│ ○ Tier 3 - Community                                    │
│                                                           │
│ Progress: ●●●○○ Step 3 of 5                              │
```

**Step 4:**
```
│ How confident are you in this data?                      │
│                                                           │
│ ━━━━━━━━━━━━━━━━━━━━━ 95%                              │
│                                                           │
│ For facts that drive decisions (like build choices),    │
│ we aim for 95%+ confidence. Factory Service Manuals     │
│ are typically 95%+ reliable.                            │
│                                                           │
│ Progress: ●●●●○ Step 4 of 5                              │
```

**Step 5 (Review):**
```
│ Review Your First Verification                           │
│                                                           │
│ Claim: VR30 bore x stroke: 86mm x 86mm                  │
│ Source: Infiniti Factory Service Manual                  │
│ Tier: 1 (Primary) ●                                      │
│ Confidence: 95%+                                         │
│                                                           │
│ Tags: VR30, engine-specs, bore-stroke                    │
│                                                           │
│                                                           │
│                   [Verify This Fact ✓]                   │
│                                                           │
│ Progress: ●●●●● Step 5 of 5                              │
```

**After clicking "Verify This Fact ✓":**

**CELEBRATION ANIMATION (Critical UX Moment):**
1. Checkmark grows from button, bounces (spring physics)
2. Subtle confetti burst (500ms, domain-colored)
3. Success message fades in:
   ```
   ┌────────────────────────────────────────┐
   │           🎉 Fact Verified!            │
   │                                        │
   │    This is your foundation. Watch:     │
   └────────────────────────────────────────┘
   ```
4. Small knowledge graph visualization animates:
   - Single node appears (VR30)
   - Label fades in
   - Gentle pulse (user's first knowledge node)
5. Encouragement message:
   ```
   This fact is now part of your knowledge graph.
   You can cite it in articles, reference it in videos,
   and build on it forever. This is how expertise compounds.

   [Add Another Fact] [View My Knowledge Graph]
   ```

**Why This Works:**
- User completes a full workflow in 5 simple steps
- Educational (learns tier system, confidence scoring)
- Rewarding (celebration animation feels good)
- Visual (sees knowledge graph node appear - makes abstract concept concrete)
- Encouraging (messaging reinforces value proposition)
- **Users remember this moment** - it's the "aha" that hooks them

**Retention Data Point:**
Users who complete first verification have 85%+ retention in first week (hypothetical, but this is the goal).

---

## Retention Mechanics: "Hang Around"

### 1. Visible Progress

**Knowledge Graph Growth:**
- Dashboard shows mini-graph preview
- Nodes increase over time (visual reward)
- Time-lapse slider shows 1 month → 6 months growth
- **User sees expertise accumulating**

**Confidence Score Increase:**
- Article starts at 0% confidence
- Each verified citation increases score
- Watch it climb: 23% → 47% → 73% → 95%+
- Visual goal creates completion drive

**Research Completion Rings:**
- Each research section has progress ring
- Filling rings is satisfying (completion psychology)
- Platform celebrates milestones: "VR30 Core Specs 100% verified! 🎉"

### 2. Quality Feedback (Helpful, Not Annoying)

**Language Precision Suggestions:**
```
⚠️ Precision Suggestion

You used "rare" on line 47.

Suggest: "150 units imported / 7.5% of total production"

Why: Quantified data is verifiable and precise.

[Accept Suggestion] [Dismiss]
```

**Tone:**
- Feels like expert editor whispering advice
- Not grammar police (suggestions, not errors)
- Educational (explains "why")
- Empowering (user decides)

**Accept Suggestion Flow:**
1. User clicks "Accept Suggestion"
2. Text updates with smooth transition
3. Micro-celebration: "✓ Precision improved!"
4. Confidence score ticks up slightly
5. **User feels article quality improving**

### 3. Connection Discovery (The Magic)

**Scenario:**
User is writing article about S7 DCT transmission.

**Platform detects:**
"We already researched DCT engagement characteristics in your Q50 project."

**UI prompts:**
```
💡 Related Research Found

You're writing about DCT engagement. We found
verified research from your Q50 project:

"DCT vs torque converter: engagement differences"
• Source: Tuner shop data (Tier 2)
• Confidence: 90%+

[Insert Citation] [View Full Research] [Dismiss]
```

**User clicks "Insert Citation":**
- Citation auto-inserted at cursor
- Confidence score increases (verified fact added)
- Toast: "Citation added! Reusing verified research."
- **User realizes platform remembers their work** (D.R.Y. principle demonstrated)

**Why This Is Magic:**
- Platform feels intelligent (it connected the dots)
- Saves time (research reused, not redone)
- Demonstrates compounding value (past work benefits future work)
- Users screenshot and share this moment ("Look what my platform did!")

### 4. Aesthetic Reward

**Beautiful Typography:**
- Reading own work is pleasurable (Merriweather serif, optimal line height)
- Makes users proud of content quality

**Smooth Animations:**
- 120-180ms transitions feel precise, intentional
- Spring physics make UI feel alive (not robotic)
- Micro-celebrations for quality improvements

**Domain-Specific Imagery:**
- User's own photos featured in dashboard
- Workspace feels personal, not generic
- **This is MY shop / MY kitchen / MY bench**

**The Work Itself Rewarded:**
- Platform doesn't just store content - it presents it beautifully
- Verified research shown with visual hierarchy (badges, colors, confidence rings)
- Users feel pride in quality work, reinforced by quality presentation

---

## Key Differentiators vs Competitors

| Generic Platform | Builder Platform | Impact |
|---|---|---|
| **Word count** | **Confidence score** (quality metric) | Shifts focus from quantity to verifiable quality |
| **Save draft** | **Verify fact** (with celebration) | Every save becomes a quality improvement moment |
| **File organization** | **Knowledge graph connections** | Relationships > folders (semantic organization) |
| **Generic UI** | **Domain-aware workspace** | Platform feels built for YOUR craft |
| **Spell check** | **Language precision enforcement** | Catches vague language, suggests quantification |
| **Related posts (tags)** | **Related knowledge (entities, causality)** | Deeper connections than keyword matching |
| **Revision history** | **Conversation logs** (decisions + lessons) | Context preserved, not just file changes |
| **Publish button** | **Confidence gate** (warn if <95%) | Quality control before publication |

**No competitor does this.** WordPress, Notion, Substack, Medium - all generic content tools. We're **methodology-first platform** disguised as beautiful writing tool.

---

## Critical "Wow" Moments (Screenshot & Share)

**1. First 95% Verified Fact:**
- Celebration animation (confetti, checkmark bounce)
- Graph node appearing
- "This is your foundation" messaging
- **Users remember this forever**

**2. Language Precision Suggestion:**
- Platform catches "rare"
- Suggests "150 units / 7.5%"
- Accept = instant improvement + celebration
- **Feels like having expert editor**

**3. Connection Discovery:**
- Writing about S7, platform suggests Q50 research
- "We already researched this - here's verified data"
- **Platform demonstrates memory and intelligence**

**4. Confidence Visualization:**
- Watching article go from 45% → 95% confidence
- Real-time quality improvement visible
- **Pride in verified work**

**5. Cross-Domain Insight:**
- "Your cassoulet research uses same methodology as Q50"
- Platform recognizes patterns across domains
- **Users realize platform is learning from their work**

**6. Knowledge Graph Time-Lapse:**
- Slider showing 6 months of growth
- Nodes appearing chronologically
- **Expertise accumulation visualized**
- **Most likely to be shared on social media**

---

## Design Constraints (What NOT to Do)

❌ **Don't overwhelm on landing**
- Start simple, progressive disclosure
- First-time users see guided flow, not feature dump

❌ **Don't hide the graph**
- Knowledge graph is differentiator - make it prominent
- Dashboard shows mini-preview
- Full graph one click away

❌ **Don't make verification feel like homework**
- Celebration animations
- Gamification through delight
- Immediate visual feedback

❌ **Don't generic-ify the UI**
- Domain-specific imagery required
- Automotive user sees engines, not stock photos
- Culinary user sees food, not generic "content creation" imagery

❌ **Don't over-animate**
- Precision = restraint
- Subtle spring physics (120-180ms)
- Not bouncy chaos

❌ **Don't force AI takeover**
- User is expert, platform assists
- Suggestions, not autocomplete
- Human has final say always

❌ **Don't ignore accessibility**
- WCAG 2.1 AA minimum
- Keyboard navigation for all features
- Screen reader support
- Color contrast ratios enforced

---

## Accessibility Requirements

**Keyboard Navigation:**
- All features accessible via keyboard
- Tab order logical
- Focus indicators visible (2px outline, domain accent color)
- Keyboard shortcuts documented (⌘K, etc.)

**Screen Readers:**
- Semantic HTML (proper headings, landmarks)
- ARIA labels for interactive elements
- Image alt text descriptive
- Status announcements for celebrations ("Fact verified at 95%")

**Color & Contrast:**
- Text contrast: 4.5:1 minimum (WCAG AA)
- Interactive elements: 3:1 minimum
- Never rely on color alone (use icons + text)
- Domain accent colors tested for contrast

**Motion Sensitivity:**
- Respect `prefers-reduced-motion`
- If enabled: no confetti, no spring physics (instant transitions)
- Still show status changes (checkmarks, progress), just not animated

---

## Responsive Design

**Breakpoints:**
- Mobile: 320px - 767px
- Tablet: 768px - 1023px
- Desktop: 1024px+

**Mobile Adaptations:**

**Dashboard:**
- Sidebar collapses to hamburger menu
- Feature image full-width
- Cards stack vertically
- Quick actions remain tappable (min 44px touch target)

**Research Workspace:**
- Split panes stack vertically (spec on top, findings below)
- Swipe between panes (mobile gesture)
- Verification dialog full-screen on mobile

**Writing:**
- Hero mode default on mobile (no sidebar)
- ⌘K opens full-screen verification overlay
- Confidence score in sticky bottom bar

**Knowledge Graph:**
- Touch gestures: pinch to zoom, drag to pan
- Node details slide up from bottom (sheet)
- Filters in hamburger menu

**Conversation Logs:**
- Cards full-width
- Infinite scroll (no pagination on mobile)

---

## Performance Requirements

**Initial Load:**
- Time to Interactive: <2 seconds (desktop), <3 seconds (mobile)
- First Contentful Paint: <1 second

**Interactions:**
- Button press response: <100ms
- Verification celebration animation: 500ms total
- Graph rendering: <1 second for 500 nodes
- Search results: <200ms

**Optimizations:**
- Server-side rendering (Next.js)
- Image optimization (WebP, lazy loading)
- Code splitting (route-based)
- Database query optimization (Prisma, Neo4j indexes)

---

## Component Library (ShadCN Specific)

**Core Components Used:**

| Component | Use Case | Customization |
|---|---|---|
| **Command** | ⌘K quick navigation, search | Domain-themed accent color |
| **Tabs** | View switching (Research/Writing/Graph) | Underline indicator (domain color) |
| **Badge** | Source tiers, tags, confidence | Color-coded by tier, rounded |
| **Card** | Projects, findings, logs | Hover lift effect, domain imagery |
| **Dialog** | Verification workflow, settings | Full-screen on mobile |
| **Sheet** | Sidebar panels, mobile nav | Slide from right, blur backdrop |
| **Progress** | Research completion, confidence | Circular rings, domain color fill |
| **Toast** | Celebrations, confirmations | Position top-right, auto-dismiss |
| **Accordion** | Research spec sections | Chevron icons, smooth collapse |
| **Separator** | Visual divisions | Subtle gray, 1px |
| **Tooltip** | Help text, citation previews | Max-width 300px, readable font size |
| **Slider** | Confidence input, time-lapse | Domain-themed handle color |

**Custom Components to Build:**

| Component | Purpose | Complexity |
|---|---|---|
| **ConfidenceRing** | Circular progress indicator with percentage | Medium |
| **VerificationCelebration** | Confetti + checkmark animation | High (custom animation) |
| **KnowledgeGraphCanvas** | Interactive graph visualization | High (D3/Cytoscape integration) |
| **LanguagePrecisionHighlight** | Inline text suggestions | Medium |
| **SourceTierBadge** | Color-coded tier indicator | Low (styled Badge) |
| **DomainThemeProvider** | Context provider for domain theming | Medium |
| **MiniGraphPreview** | Small graph visualization for dashboard | Medium |

---

## Next Steps for Implementation

**Phase 1: Core UI (Weeks 1-4)**
1. Set up Next.js 14 project with ShadCN/UI
2. Implement design system (typography, colors, spacing)
3. Build dashboard (context-aware hero, quick actions)
4. Create domain theme switcher

**Phase 2: Research & Verification (Weeks 5-8)**
5. Build research workspace (split-pane layout)
6. Implement verification workflow (dialog, celebration animation)
7. Add language precision checker
8. Create source tier badge system

**Phase 3: Writing & Content (Weeks 9-12)**
9. Build writing interface (hero mode, beautiful typography)
10. Implement verification sidebar
11. Add confidence scoring visualization
12. Create inline citation system

**Phase 4: Knowledge Graph (Weeks 13-16)**
13. Integrate Neo4j graph database
14. Build interactive graph visualization
15. Implement node detail panels
16. Add time-lapse slider

**Phase 5: Polish & FTUE (Weeks 17-20)**
17. Create onboarding flow (domain selection, first verification)
18. Implement conversation log timeline
19. Add responsive mobile layouts
20. Performance optimization, accessibility audit

---

**Document Status:** Implementation-ready specification. Designer and developer can begin work immediately.

**Next Document:** Feature breakdown with sprint planning (feature-implementation-plan.md)
