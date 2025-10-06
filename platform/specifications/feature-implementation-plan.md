# FEATURE IMPLEMENTATION PLAN v1.0
**The Builder Platform - Phased Development Roadmap**

**Last Updated:** October 6, 2024
**Status:** Ready for Sprint Planning
**Estimated Timeline:** 20 weeks (5 months) to MVP

---

## Implementation Philosophy

**Goal:** Get platform in hands of early SME users as quickly as possible to find rough edges.

**Approach:**
- Build minimum viable features first (research, verification, writing)
- Polish core UX (celebration moments, verification flow)
- Add advanced features iteratively (graph visualization, cross-domain insights)
- Ship early, learn fast, iterate based on real user feedback

**Success Metrics:**
- 10 early adopter SMEs using platform (5 automotive, 3 culinary, 2 other domains)
- 95%+ of verified facts meet tier + confidence standards
- Users complete first verification within 10 minutes (FTUE success)
- Knowledge graph grows (measure: nodes per user per week)

---

## Development Phases

### MVP Scope (What Ships First)

**Core Features (Must-Have for Launch):**
1. User authentication (sign up, login, profile)
2. Project creation (domain selection, project setup)
3. Research workspace (spec templates, finding cards)
4. Verification workflow (tier selection, confidence scoring, celebration)
5. Writing interface (hero mode, beautiful typography, inline citations)
6. Basic knowledge graph (store relationships, simple visualization)
7. Conversation logging (manual trigger, markdown export)
8. Domain theming (automotive, culinary, custom)

**Deferred Features (Post-MVP):**
- Advanced graph visualization (time-lapse, complex filtering)
- Automated language precision suggestions (AI-powered)
- Cross-domain pattern detection
- Platform-trained specialized agents
- Multi-user collaboration
- Mobile apps (start with responsive web)

**Rationale:** MVP proves core value proposition - verification workflow + knowledge compounding. Advanced features require usage data to optimize.

---

## Phase 1: Foundation & Core UI (Weeks 1-4)

### Week 1: Project Setup & Design System

**Tasks:**
- [ ] Initialize Next.js 14 project (App Router, TypeScript)
- [ ] Install ShadCN/UI + configure Tailwind
- [ ] Set up PostgreSQL database (local dev, Railway staging)
- [ ] Create Prisma schema (users, projects, research, facts)
- [ ] Define design tokens (colors, typography, spacing, animations)
- [ ] Build DomainThemeProvider component (context for theming)
- [ ] Create base layout components (TopNav, Sidebar, MainContent)

**Deliverable:** Empty app with navigation shell, theme switcher working

**Acceptance Criteria:**
- Can switch between automotive/culinary themes
- Accent colors update across UI
- Typography system in place (Inter, Merriweather, JetBrains Mono)

### Week 2: Authentication & User Profile

**Tasks:**
- [ ] Implement authentication (NextAuth.js or Clerk)
- [ ] Create sign up flow
- [ ] Create login flow
- [ ] Build user profile page (name, domain preference, settings)
- [ ] Add profile photo upload (Cloudinary or S3)
- [ ] Implement session management

**Deliverable:** Users can create account, log in, set domain preference

**Acceptance Criteria:**
- Sign up completes in <2 minutes
- Domain preference saves and persists
- Profile photo displays in top nav

### Week 3: Dashboard (Context-Aware Hero)

**Tasks:**
- [ ] Build dashboard layout (hero section, quick actions, recent activity)
- [ ] Create ProjectCard component (shows progress, stats, actions)
- [ ] Implement feature image background (domain-appropriate, user's media)
- [ ] Add progress indicators (research %, confidence score, word count)
- [ ] Build quick action cards (New Research, Knowledge Graph, Recent Logs)
- [ ] Create RecentVerifications component (last 5 facts, tier badges)

**Deliverable:** Dashboard shows active projects, progress, quick access

**Acceptance Criteria:**
- Dashboard adapts to user's domain (imagery, accent color)
- Progress indicators accurate (pull from database)
- Quick actions navigate to correct screens

### Week 4: Project Creation Flow

**Tasks:**
- [ ] Build domain selection screen (cards: Automotive, Culinary, Woodworking, Custom)
- [ ] Create project setup form (name, research focus, content goals)
- [ ] Add domain-appropriate background imagery to setup screen
- [ ] Implement project creation API (POST /api/projects)
- [ ] Create project database schema (domains, templates)
- [ ] Build first-time user onboarding state management

**Deliverable:** Users can create first project from domain selection to dashboard

**Acceptance Criteria:**
- Domain selection cards are visually distinct and beautiful
- Project setup completes in <3 minutes
- New project appears on dashboard with 0% progress

**Phase 1 Milestone:** User can sign up, select domain, create project, see dashboard. Foundation complete.

---

## Phase 2: Research & Verification Workflow (Weeks 5-8)

### Week 5: Research Workspace Layout

**Tasks:**
- [ ] Build split-pane layout (ResearchSpec left, Findings right)
- [ ] Create ResearchSpecTemplate component (accordion sections)
- [ ] Implement checkbox tracking (per spec item, save to database)
- [ ] Add progress calculation (% complete per section, overall)
- [ ] Build FindingCard component (title, data, source, tier, confidence)
- [ ] Create finding database schema (findings, sources, confidence)

**Deliverable:** Research workspace with spec template and findings area

**Acceptance Criteria:**
- Split panes responsive (stack on mobile)
- Checkboxes save state immediately
- Progress bars update in real-time

### Week 6: Verification Workflow (THE CRITICAL UX)

**Tasks:**
- [ ] Build VerificationDialog component (claim, source, tier, confidence, tags)
- [ ] Implement tier selection radio buttons (Tier 1/2/3 with descriptions)
- [ ] Create confidence slider (0-100%, default 95%)
- [ ] Add tag input with suggestions
- [ ] Build verification API (POST /api/facts/verify)
- [ ] **Implement celebration animation** (confetti, checkmark bounce, toast)
- [ ] Create mini-graph preview (single node appearing)
- [ ] Add "Fact verified!" success state with encouragement messaging

**Deliverable:** Complete verification workflow from finding → verified fact with celebration

**Acceptance Criteria:**
- Dialog opens smoothly (150ms transition)
- Tier selection clear (visual difference between 1/2/3)
- Confidence slider feels precise
- **Celebration animation delights** (users smile when they see it)
- Verified fact appears in findings list with green border + badge
- Research spec checkbox auto-checks when fact verified

**CRITICAL:** This is the "hook" moment. Spend extra time polishing celebration. Test with real users.

### Week 7: Source Tier System & Badges

**Tasks:**
- [ ] Build SourceTierBadge component (color-coded: Tier 1 green, Tier 2 yellow, Tier 3 blue)
- [ ] Create tier explanation tooltips (hover to see Tier 1 = "Primary authoritative")
- [ ] Implement tier filtering (show only Tier 1 facts, etc.)
- [ ] Add tier distribution visualization (pie chart: % of facts by tier)
- [ ] Build confidence breakdown component (average confidence across facts)
- [ ] Create conflict detection logic (when two sources give different data for same spec)

**Deliverable:** Visual tier system with badges, filtering, conflict detection

**Acceptance Criteria:**
- Tier badges instantly recognizable (color + icon)
- Tooltips educational (explain what each tier means)
- Conflict detection alerts user (red warning UI)

### Week 8: Language Precision Checker (Basic)

**Tasks:**
- [ ] Create banned words list (rare, expensive, fast, common, many, often, etc.)
- [ ] Implement text scanning (detect banned words in findings and content)
- [ ] Build PrecisionSuggestion component (highlight word, suggest quantification)
- [ ] Add accept/dismiss actions (accept = replace text + micro-celebration)
- [ ] Create precision tracking (count of vague terms, improvement over time)
- [ ] Implement suggestion API (store dismissed suggestions to improve over time)

**Deliverable:** Language precision checker highlights vague terms, suggests improvements

**Acceptance Criteria:**
- Banned words highlighted in yellow
- Suggestions helpful, not annoying (tone: expert editor)
- Accept suggestion = smooth text replacement + "✓ Precision improved!" toast
- Dismiss works (don't suggest same thing again)

**Phase 2 Milestone:** Research workflow complete. Users can create specs, add findings, verify facts with celebration, get precision feedback. Core value proposition proven.

---

## Phase 3: Writing & Content Creation (Weeks 9-12)

### Week 9: Writing Interface (Hero Mode)

**Tasks:**
- [ ] Build hero mode layout (full-screen, minimal chrome)
- [ ] Implement rich text editor (Tiptap or Novel)
- [ ] Style typography (Merriweather 18px/32px, max-width 680px, centered)
- [ ] Add inline citation system (superscript numbers, linked to sources)
- [ ] Create citation tooltip (hover superscript = show full source)
- [ ] Build bottom status bar (confidence, word count, reading time, source tier distribution)
- [ ] Implement auto-save (every 5 seconds, with "Saved" indicator)

**Deliverable:** Beautiful, distraction-free writing interface with citations

**Acceptance Criteria:**
- Typography feels premium (comfortable to read for 20+ minutes)
- Citations easy to insert (keyboard shortcut or toolbar)
- Auto-save reliable (never lose work)
- Hero mode toggles smoothly (exit to normal view)

### Week 10: Verification Sidebar

**Tasks:**
- [ ] Build verification sidebar (collapsible, summon with ⌘K)
- [ ] Implement verified facts search (query user's knowledge graph)
- [ ] Create drag-to-insert citation (drag fact card → drops citation in text)
- [ ] Add recent verifications list (last 10 facts, filterable)
- [ ] Build tag-based filtering (show facts tagged "VR30", "cassoulet", etc.)
- [ ] Implement confidence score calculation (% of claims backed by verified facts)
- [ ] Create real-time confidence ring (updates as citations added)

**Deliverable:** Sidebar for searching and inserting verified research into content

**Acceptance Criteria:**
- Search returns results <200ms
- Drag-and-drop citation insertion smooth
- Confidence score updates in real-time (no lag)
- Sidebar doesn't obstruct writing (overlay, not push content)

### Week 11: Confidence Scoring System

**Tasks:**
- [ ] Implement claim detection (parse content for factual statements)
- [ ] Build confidence calculation algorithm (verified claims / total claims)
- [ ] Add source tier weighting (Tier 1 = 1.0, Tier 2 = 0.8, Tier 3 = 0.6)
- [ ] Create ConfidenceRing component (circular progress, percentage in center)
- [ ] Build source tier distribution pie chart (% Tier 1/2/3)
- [ ] Implement confidence gate (warn if publishing <95%)
- [ ] Add "Improve Confidence" suggestions (which claims need citations)

**Deliverable:** Real-time confidence scoring with visual feedback

**Acceptance Criteria:**
- Confidence calculation accurate (spot-check with manual count)
- Ring animation smooth (spring physics, not linear)
- Publishing <95% shows warning dialog (not blocked, just warned)
- Suggestions actionable ("Add citation for: VR30 head lifting threshold")

### Week 12: Content Management

**Tasks:**
- [ ] Build content library (list all articles, videos, presentations)
- [ ] Create ContentCard component (title, confidence, word count, status)
- [ ] Implement content status workflow (Draft → Review → Published)
- [ ] Add export options (Markdown, PDF, HTML)
- [ ] Build preview mode (see content as reader would)
- [ ] Create sharing (generate public link for published content)

**Deliverable:** Content management system for organizing and publishing work

**Acceptance Criteria:**
- Content library shows all projects' content
- Export to Markdown preserves citations (footnotes format)
- Preview mode beautiful (same typography as writing mode)
- Shared links publicly accessible (no login required)

**Phase 3 Milestone:** Writing workflow complete. Users can write with beautiful UI, insert verified citations, see confidence score, publish content. Platform is usable end-to-end.

---

## Phase 4: Knowledge Graph & Connections (Weeks 13-16)

### Week 13: Neo4j Integration

**Tasks:**
- [ ] Set up Neo4j database (local dev, Neo4j Aura staging)
- [ ] Create graph schema (nodes: Facts, Projects, Specs, Decisions, Lessons; edges: related_to, cites, informs)
- [ ] Build sync service (Postgres → Neo4j for verified facts)
- [ ] Implement graph queries (Cypher: find related facts, show connections)
- [ ] Create graph API endpoints (GET /api/graph/nodes, GET /api/graph/connections)
- [ ] Add background job for graph updates (when fact verified, create node + edges)

**Deliverable:** Neo4j graph database storing knowledge relationships

**Acceptance Criteria:**
- Every verified fact creates graph node
- Relationships auto-created (fact → project, fact → tags)
- Graph queries return <500ms for 1,000 nodes

### Week 14: Knowledge Graph Visualization (Basic)

**Tasks:**
- [ ] Integrate D3.js or Cytoscape.js
- [ ] Build KnowledgeGraphCanvas component (interactive, zoomable, pannable)
- [ ] Implement node rendering (size by confidence, color by domain, shape by type)
- [ ] Add edge rendering (thickness by relationship strength)
- [ ] Create node click handler (show detail panel)
- [ ] Build detail panel (node info, related nodes, facts count)
- [ ] Implement basic filters (show domain, show node type)

**Deliverable:** Interactive knowledge graph visualization

**Acceptance Criteria:**
- Graph renders <1 second for 500 nodes
- Zoom/pan smooth (60fps)
- Node click shows detail instantly (<100ms)
- Filters update graph in real-time

### Week 15: Connection Discovery

**Tasks:**
- [ ] Build connection suggestion algorithm (when user researches topic, query graph for related facts)
- [ ] Create ConnectionSuggestion component (toast or sidebar card)
- [ ] Implement "Related Research Found" UI (shows fact from other project)
- [ ] Add insert action (click to insert citation from related research)
- [ ] Build connection tracking (measure: how often users accept suggestions)
- [ ] Create cross-domain connection detection (facts from automotive → culinary methodologies)

**Deliverable:** Platform suggests related research from knowledge graph

**Acceptance Criteria:**
- Suggestions relevant (90%+ acceptance rate goal)
- UI not intrusive (suggestion, not interruption)
- Insert action works (citation added to content)
- Cross-domain suggestions accurate (same methodology, different domain)

### Week 16: Graph Features Polish

**Tasks:**
- [ ] Add time-lapse slider (show graph growth over time)
- [ ] Implement timeline animation (nodes appear chronologically)
- [ ] Build mini-graph preview (dashboard widget showing 10 most recent nodes)
- [ ] Create "Expertise Map" view (cluster nodes by topic/domain)
- [ ] Add graph export (PNG, SVG for sharing on social media)
- [ ] Implement graph search (find specific node by name/tag)

**Deliverable:** Polished graph features with time-lapse and search

**Acceptance Criteria:**
- Time-lapse smooth (animate 100 nodes over 5 seconds)
- Mini-graph preview loads <500ms
- Graph export high-quality (shareable on Twitter/LinkedIn)

**Phase 4 Milestone:** Knowledge graph live. Users see expertise visualized, get connection suggestions, watch knowledge compound over time. "Wow" moments unlocked.

---

## Phase 5: Conversation Logs & Polish (Weeks 17-20)

### Week 17: Conversation Logging System

**Tasks:**
- [ ] Build conversation log creation UI (manual trigger button)
- [ ] Create log template (title, date, session type, key outcomes, tags)
- [ ] Implement log storage (Markdown files in database + file system)
- [ ] Add log export (download as .md)
- [ ] Build ConversationLogTimeline component (cards, searchable, filterable)
- [ ] Create log detail view (reading mode with beautiful typography)
- [ ] Implement tagging system (autocomplete tags, link to knowledge graph)

**Deliverable:** Manual conversation logging with timeline view

**Acceptance Criteria:**
- Creating log takes <5 minutes
- Logs searchable by tags, keywords, date
- Timeline visually appealing (important lessons stand out)
- Export preserves formatting

### Week 18: First-Time User Experience (FTUE)

**Tasks:**
- [ ] Build guided first verification flow (5-step wizard)
- [ ] Add tooltips and educational copy
- [ ] Implement first verification celebration (special animation for first-time)
- [ ] Create progress indicator (Step X of 5)
- [ ] Build onboarding checklist (Create project, Verify fact, Write content, View graph)
- [ ] Add in-app help (contextual tips, ? icons with explanations)
- [ ] Implement skip option (for power users who don't need hand-holding)

**Deliverable:** Onboarding flow that teaches verification workflow

**Acceptance Criteria:**
- 80%+ of new users complete first verification
- Average time to first verification <10 minutes
- Users understand tier system after onboarding (quiz/survey)

### Week 19: Responsive & Mobile Optimization

**Tasks:**
- [ ] Audit all screens on mobile (320px, 375px, 414px widths)
- [ ] Fix split-pane stacking (research workspace)
- [ ] Optimize touch targets (min 44px for buttons)
- [ ] Implement mobile navigation (hamburger menu, slide-out sidebar)
- [ ] Add mobile gestures (swipe between panes, pull-to-refresh)
- [ ] Optimize graph for touch (pinch zoom, tap nodes)
- [ ] Test on real devices (iPhone, Android, iPad)

**Deliverable:** Fully responsive platform, mobile-optimized

**Acceptance Criteria:**
- All features work on mobile (no broken layouts)
- Touch targets comfortable (easy to tap)
- Performance good on mobile (<3s initial load on 4G)

### Week 20: Performance & Accessibility Audit

**Tasks:**
- [ ] Run Lighthouse audit (aim for 90+ on all metrics)
- [ ] Optimize images (WebP format, lazy loading, proper sizing)
- [ ] Implement code splitting (route-based, component-based)
- [ ] Add skeleton loaders (perceived performance)
- [ ] Audit accessibility (WCAG 2.1 AA compliance)
- [ ] Test with keyboard only (no mouse)
- [ ] Test with screen reader (VoiceOver, NVDA)
- [ ] Fix contrast issues (4.5:1 minimum for text)
- [ ] Add `prefers-reduced-motion` support (disable animations)

**Deliverable:** Optimized, accessible platform ready for launch

**Acceptance Criteria:**
- Lighthouse score 90+ (Performance, Accessibility, Best Practices, SEO)
- All features keyboard accessible
- Screen reader announces state changes correctly
- No contrast failures (automated tools + manual check)

**Phase 5 Milestone:** MVP complete. Platform polished, accessible, mobile-ready. Ready for early adopter launch.

---

## Post-MVP Roadmap (Months 6-12)

### Advanced Features (Based on User Feedback)

**Quarter 2 (Months 6-8):**
- AI-powered language precision (GPT-4 for context-aware suggestions)
- Automated cross-domain pattern detection
- Collaboration features (multi-user projects, comments, reviews)
- Advanced graph filtering (complex queries, saved views)
- Integration with external tools (Notion import, WordPress export)

**Quarter 3 (Months 9-10):**
- Platform-trained specialized agents (automotive research agent, culinary agent)
- Model distillation from accumulated knowledge
- API for third-party integrations
- Marketplace for research templates (community-created specs)

**Quarter 4 (Months 11-12):**
- Native mobile apps (iOS, Android)
- Offline mode (local-first, sync when online)
- Advanced analytics (research velocity, quality trends, expertise growth)
- White-label platform (enterprise: consulting firms, agencies)

---

## Resource Requirements

### Team Structure (Recommended)

**MVP Team (Weeks 1-20):**
- 1 Full-Stack Engineer (Next.js, React, Node.js, databases)
- 1 UI/UX Designer (Figma mockups, component design, FTUE flow)
- 1 Product Manager (feature prioritization, user testing, feedback)
- 1 Part-Time QA Tester (Weeks 15-20, testing across devices)

**Post-MVP Team (Months 6+):**
- +1 Backend Engineer (graph database optimization, API scaling)
- +1 Frontend Engineer (advanced features, performance)
- +1 DevOps Engineer (deployment, monitoring, scaling)
- +1 Data Scientist (pattern detection, AI features)

### Technology Stack (Finalized)

**Front-End:**
- Next.js 14 (App Router, Server Components)
- React 18 (UI library)
- TypeScript (type safety)
- ShadCN/UI + Tailwind CSS (component library + styling)
- Framer Motion (animations)
- Tiptap (rich text editor)
- D3.js or Cytoscape.js (graph visualization)
- TanStack Query (data fetching)
- Zustand (state management)

**Back-End:**
- Next.js API Routes (serverless functions)
- Prisma (ORM)
- PostgreSQL (relational data: users, projects, content)
- Neo4j (graph database: knowledge relationships)
- NextAuth.js or Clerk (authentication)

**Infrastructure:**
- Vercel (front-end hosting)
- Railway or Render (PostgreSQL, Neo4j hosting)
- Cloudinary or AWS S3 (media storage)
- GitHub Actions (CI/CD)

**Monitoring & Analytics:**
- Vercel Analytics (performance)
- Sentry (error tracking)
- PostHog or Mixpanel (product analytics)

---

## Success Metrics (MVP Launch)

### User Acquisition
- **Target:** 10 early adopter SMEs by Week 20
- **Breakdown:** 5 automotive, 3 culinary, 2 other domains
- **Source:** Personal network, Twitter/LinkedIn sharing, product hunt

### User Engagement
- **First verification completion:** 80%+ of new users
- **Time to first verification:** <10 minutes average
- **Weekly active users:** 60%+ (6 of 10 users active each week)
- **Facts verified per user per week:** 10+ average

### Quality Metrics
- **Verification confidence:** 90%+ of facts at 95%+ confidence
- **Source tier distribution:** 50%+ Tier 1 sources
- **Language precision improvement:** 80%+ vague terms fixed (accept suggestions)

### Knowledge Graph Growth
- **Nodes per user:** 50+ verified facts by end of Month 1
- **Cross-domain connections:** 5+ per user (reusing research across projects)
- **Graph query speed:** <500ms for 1,000 nodes

### Platform Satisfaction
- **NPS Score:** 50+ (Net Promoter Score)
- **Feature requests:** Collect for post-MVP roadmap
- **Bug reports:** <10 critical bugs reported (high quality launch)

---

## Risk Mitigation

### Technical Risks

**Risk:** Neo4j graph queries slow with 10,000+ nodes
**Mitigation:**
- Index optimization (Cypher query planning)
- Pagination (load 500 nodes at a time)
- Caching (TanStack Query, 5-minute cache)
- Fallback: Limit graph visualization to most relevant 500 nodes

**Risk:** Rich text editor performance issues
**Mitigation:**
- Test Tiptap vs Novel early (Week 9)
- Implement virtual scrolling for long documents
- Debounce auto-save (every 5 seconds, not on every keystroke)

**Risk:** Authentication security vulnerabilities
**Mitigation:**
- Use battle-tested auth (NextAuth.js or Clerk, not custom)
- Implement rate limiting (API routes)
- Security audit before launch (automated tools + manual review)

### Product Risks

**Risk:** Verification workflow too complex (users drop off)
**Mitigation:**
- User testing in Week 6 (watch real users verify first fact)
- Simplify if >50% drop off rate
- Add skip option (power users can verify faster)

**Risk:** Language precision checker annoying (users disable it)
**Mitigation:**
- Tone: helpful editor, not grammar police
- Accept/dismiss options (user in control)
- Track acceptance rate (if <30%, reconsider approach)

**Risk:** Knowledge graph overwhelming (users don't understand value)
**Mitigation:**
- Mini-graph preview on dashboard (introduce gradually)
- Educational tooltips (explain what graph shows)
- Time-lapse feature (show growth = demonstrate value)

### Business Risks

**Risk:** Not enough early adopters (can't validate assumptions)
**Mitigation:**
- Owner's network (automotive community)
- Owner's wife (culinary domain)
- Product Hunt launch (reach broader audience)
- Twitter/LinkedIn sharing (build in public)

**Risk:** Users don't see value in compounding knowledge (churn after Month 1)
**Mitigation:**
- Connection suggestions (demonstrate research reuse early)
- Weekly email: "Your knowledge graph grew by X nodes this week"
- Success stories (showcase user who reused research across 5 articles)

---

## Next Steps (Immediate Actions)

**Week 0 (Pre-Development):**
1. ✅ Conversation log created (preserve UI/UX vision)
2. ✅ UI/UX specification finalized (implementation-ready)
3. ✅ Feature implementation plan documented (this document)
4. ⏳ Technical architecture specification (next document)
5. Hire/assign development team
6. Set up project management (Linear, Jira, or GitHub Projects)
7. Create sprint schedule (2-week sprints, 10 sprints total)

**Week 1 (Kick-Off):**
8. Sprint 1 planning meeting
9. Initialize codebase (Next.js, ShadCN/UI, Prisma)
10. Designer creates Figma mockups (dashboard, research workspace, writing interface)
11. Set up staging environment (Vercel, Railway databases)
12. First stand-up (daily 15-minute syncs)

**Week 20 (Launch):**
13. MVP launch to 10 early adopters
14. User onboarding sessions (watch first-time experience)
15. Collect feedback (surveys, interviews, analytics)
16. Plan Sprint 11+ based on learnings

---

## Appendix: Sprint Breakdown

### Sprint 1-2 (Weeks 1-4): Foundation
- Project setup, design system, authentication, dashboard, project creation

### Sprint 3-4 (Weeks 5-8): Research & Verification
- Research workspace, verification workflow (celebration!), tier system, precision checker

### Sprint 5-6 (Weeks 9-12): Writing & Content
- Writing interface, verification sidebar, confidence scoring, content management

### Sprint 7-8 (Weeks 13-16): Knowledge Graph
- Neo4j integration, graph visualization, connection discovery, polish

### Sprint 9-10 (Weeks 17-20): Logs & Launch Prep
- Conversation logging, FTUE, mobile optimization, accessibility audit, launch

**Each sprint:** 2 weeks, sprint planning Monday, demo/retro Friday

---

**Document Status:** Ready for development. Team can begin Sprint 1 immediately.

**Next Document:** Technical architecture specification (tech-architecture-spec.md) - detailed stack decisions, API design, database schemas, deployment strategy.
