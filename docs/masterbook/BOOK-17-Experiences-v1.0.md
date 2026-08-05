# BOOK-17 — Experiences
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> Everything before this Book is invisible to the people it serves. The
> experience layer is **where the architecture succeeds or dies**: a university
> is a service platform whose product is transformation, and transformation
> happens — or doesn't — in thousands of small moments of clarity, momentum and
> trust. This Book specifies the experience architecture (one kernel,
> role-shaped views), the **Canvas · Companion · Missions** triad every
> workspace is built from, the full workspace catalog (student WS00–WS08,
> faculty, institution), the design and quality bars, and the conversational
> etiquette of a proactive institution. It resolves G1 and G4 and runs the
> standing G-register check.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** every kernel Book (experiences
> own no state — BOOK-03 Ch. 2); BOOK-09 (one voice); Foundation §11/§14/§15.
> **Primary audience:** product, UX, frontend engineers, faculty representatives.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** built
on the running UI assets: Paper.design system (`UI_REVISION_PLAN`, tokens),
Next.js portal with role-based views, existing components (`StudentCoursePlayer`,
`KnowledgeMastery`, `MasteryDashboard`, `LearnerProfileSettings`, notification
center), the F2 UX sprint patterns (empty states, AI latency, undo/redo,
propose/accept, error handling, breadcrumbs), `accessibility_service`, i18n
infrastructure, and the constitutional WS map (§15).

---

# Chapter 1 — Thesis: the Experience IS the Product

Three inversions define the DLU experience against both legacy academic IT and
generic AI chat products:

1. **From navigation to orientation.** Legacy platforms are menus over
   features; the learner must know where things are. DLU's surfaces answer the
   Seven Questions (BOOK-00) *at the learner*, continuously: every workspace
   opens on *where you are, what changed, what's next* — not on an empty menu.
2. **From chatbot to companion.** Generic AI UX bolts a chat window onto an
   app. DLU has **one companion** (the One-Voice Principle, BOOK-09 §5.2)
   present everywhere, workspace-biased, memory-bearing, explanation-ready —
   the conversation and the canvas are two views of the same cognitive state.
3. **From engagement to transformation.** The experience optimizes learning
   and trust, never session time (BOOK-01 Ch. 10 guardrails; desirable
   difficulty means the experience sometimes *should* feel like work — honest
   effort, honestly framed).

## The six experience principles (Foundation §11), made normative

| Principle | Binding rule | Anti-pattern (prohibited) |
|-----------|--------------|---------------------------|
| Proactive | the system reaches out on kernel events within notification etiquette (Ch. 8) | nagging; duplicate prompts (recommendation idempotency) |
| Contextual | every surface renders against the twin (purpose-tagged reads) | context-blind generic screens |
| Conversational | anything visible is askable ("why?", "what if?") | dead-end dashboards |
| Adaptive | pace/sequence/modality per BOOK-01 Ch. 7 bounds | personalizing the canon; dark-pattern adaptivity |
| Explainable | every AI-derived element has an explanation affordance (trace-backed) | "the algorithm says" |
| Continuous | state survives sessions, devices, lifecycle stages | starting over; lost drafts (undo/redo + versioning are UX law) |

---

# Chapter 2 — Experience Architecture

```text
Portal shell (Next.js, Keycloak SSO, role routing)
 └─ Workspace = Canvas + Companion + Missions        ← the triad, every workspace
      Canvas    role-shaped kernel views (read APIs, live via events)
      Companion the one-voice conversation, workspace-biased (ACE route)
      Missions  the actionable stream: recommendations, HITL items, due reviews,
                applications, approvals — each mission = kernel object + one action
```

Rules:

1. **The triad is mandatory.** A workspace without a companion is a dead
   dashboard; without missions it is a report; without a canvas it is a chatbot.
   All three, always — sized to the role.
2. Experiences own **no domain state** (BOOK-03 Ch. 2): presentation state
   only; every mutation is a kernel call or an event.
3. **Same kernel, shaped views:** learner, faculty, registrar and rector see
   the *same* truth at different projections — never parallel truths
   (the Moodle delivery surface embeds per the platform strategy; its events
   flow back as xAPI).
4. Deep links everywhere: every kernel object has a stable URL; every
   companion answer can link into the canvas it describes.

---

# Chapter 3 — Student Experience: WS00–WS08

Primary navigation (Foundation §15): **Discover · Plan · Learn · Practice ·
Assess · Achieve · Grow**. Per workspace: purpose, canvas, companion bias,
signature missions, and the **aha moment** the design must engineer (the moment
the learner *feels* the differentiator).

| WS | Name (nav) | Canvas | Companion bias | Signature missions | Aha moment |
|----|-----------|--------|----------------|--------------------|-----------|
| WS00 | Discovery & Twin (Discover) | profile, goals, consent, **AI memory panel** (BOOK-12), persona | Discovery | complete diagnostics; set goals; review "what the AI knows about me" | *"it actually listened"* — the twin plays back who you are, editable |
| WS01 | Academic Journey (Plan) | GPS scenario comparison, adopted path, term plan, ETA bands | Navigator | adopt/replan; advisor co-review | *"I can see my whole road — and the trade-offs"* (Pareto honesty, BOOK-14 Ch. 7) |
| WS02 | Credit Recognition (Plan) | claim inventory, yield estimates, dossier status, hedges | Recognition | upload documents; file claims; track adjudication | *"my past counts — 21 ECTS recognized before I started"* |
| WS03 | Personal Knowledge Map (Grow) | the L4 graph: mastery-colored concepts, frontier, gap paths | Tutor/Coach | contest a state; explore frontier | *"this is my mind, mapped — and I can see what 'ready to learn' means"* |
| WS04 | Learning (Learn) | course player, content, progress, pacing | Coach | today's plan; resume; review debt | *"it knows exactly where I left off and why this is next"* |
| WS05 | Personal Tutor (Practice) | tutoring session, worked examples, hint ladder visible | Subject Tutor | practice sets; struggle sessions | *"it makes me find the answer — and I do"* (P4 experienced) |
| WS06 | Examination & Mastery (Assess) | sessions calendar (appelli, G2), readiness predictions, attempts, evidence timeline | Assessment | enroll in session; sit; review feedback; (refuse & retake where allowed) | *"I knew I was ready before I walked in"* |
| WS07 | Credential Wallet (Achieve) | credentials, document credentials, DS, sharing controls, verify links | Credential | claim; export; share; import external | *"my degree explains itself — and employers can verify it in one click"* |
| WS08 | Engagement & Success (Grow) | community, cohorts, belonging, wellbeing-respectful progress | Success/Coach | join groups; peer-teach (CAT-7); re-engage | *"someone noticed — and it was a person"* (BOOK-02 Ch. 6: the intervention is human) |

> ✅ **IMPLEMENTED (NEW-23, SPRINT-12, 2026-07-31):** WS03 (Grow) gained a
> real, self-service **Study Missions** stream — daily-generated missions
> from three sources (`coach`: top scored `Recommendation`, concept-level;
> `gps`: first `PathStep` of the adopted scenario; `self`: student-created)
> — deliberately a DIFFERENT, distinctly-named component
> (`StudyMissionsFeed.js`) from the workspace triad's own "Missions" HITL
> stream (`MissionsFeed.js`), which already means the ACE propose-tier
> queue; the two coexist side by side, never merged. WS03's canvas also
> gained a **before/after knowledge-growth panel** (`knowledge_map_
> snapshots`, captured at first `mastery.updated` for a course and at
> `course.achieved`), and WS07's wallet now receives **auto-issued course
> badges with zero human intervention** — closing a fully-built but
> never-wired STX-13 credential pipeline (BOOK-16 Ch. 4, item 2 callout).
> Nudging (disengagement detection) reuses the SAME etiquette-gated
> `learning_coach` mission pattern plus real delivered notifications — a
> severely disengaged twin escalates via the real crisis pathway
> (`RISK_DETECTED`, BOOK-07 FW4), never a new mechanism.

**Catalog Explorer (G15 — pre-auth + WS00/WS01 surface) — ✅ implemented
(NEW-16, 2026-07-27):** the published
CatalogEdition renders as an explorable space — programs, courses (codes,
credits, prerequisites as navigable chains, designations, knowledge/competency
contributions), recognition policies — with **what-if simulation** powered by
`simulate_scenarios` (BOOK-14 Ch. 9): a prospect declares background and goal
and sees candidate paths, estimated recognition and duration *before creating
an account*; saving a simulation flows into the Discovery dialogue (WS00).
Faculty-side, the same data authors through **FW1** (course contribution
declarations, recognition equivalencies). The legal document (BOOK-16 §6.4a)
is downloadable from the explorer — one aggregate, three renderings.

Cross-WS rules: lifecycle-aware composition (a Prospect sees WS00+catalog; an
Active student all nine; an Alumna WS07/08 + re-entry — BOOK-06 Ch. 4);
persona-parameterized onboarding order (Transfer lands on WS02 *first* —
recognition-first routing made experiential); regression framed per
compassionate-recalculating (BOOK-14 §6.2).

---

# Chapter 4 — Faculty Experience (five workspaces)

| FW | Name | Canvas | Companion bias | Signature missions |
|----|------|--------|----------------|--------------------|
| FW1 | Design Studio | Builder/FEX wizard, Factory pipeline, gate status (3-gate flow), Coach reports — **as of NEW-16 (2026-07-27), extended with DEVELOPS/COVERS contribution declarations + recognition-policy/equivalency declarations** (feeding the NEXT `CatalogEdition` snapshot only, never retroactive) | Course Architect | author; respond to Gate 1/3; review AI output (Gate 2); declare catalog contributions/recognition policies (NEW-16) |
| FW2 | Teaching Operations | sections, calendars, **office hours (G1)**: publishable slots + student booking; **teaching register (G4)**: auto-generated from delivery events, per-session topics editable, submit for department approval | Coach (faculty-side) | confirm register entries; publish appelli (G2, BOOK-15); communications |
| FW3 | Verification Desk | HITL queues (evidence verification, summative sign-off, recognition dossiers), viva dossiers, committee duties (G6) | Assessment | verify; examine; sign |
| FW4 | Mentorship | advisee twins (`purpose=staff_view`, audited), risk flags, intervention proposals | Success | meet; respond to proposals; log outcomes |
| FW5 | Envelope Console | per-course agent envelopes (F4), digests of agent activity, tuning proposals (M4 → propose) | — | inspect; tune; approve learned defaults |

**G1 resolved:** office hours live on F1 (BOOK-07), published to students as
bookable slots (calendar + notification integration) — trivial mechanics,
outsized trust value. **G4 resolved:** the register is a **generated Track-A
view** (BOOK-07 §6.2): DLU already knows what was taught when; the faculty
member confirms and annotates instead of transcribing; department-head approval
is a HITL mission; the signed register exports for compliance. Bureaucracy
inverted: the system drafts, the human certifies.

Workload honesty rule: FW surfaces render F5 *to the faculty member first*
(BOOK-07 Ch. 5) — queue depths, verification load, mentorship hours — the
instrument of the mentorship dividend in their own hands.

---

# Chapter 5 — Institution & Staff Experiences

| IW | Role | Canvas | Signature missions |
|----|------|--------|--------------------|
| IW1 Rector's Bridge | rector/provost/board | scorecard (BOOK-08 I2/I3/I6), three-economy balance, red posture items | review ACE briefs (propose); ratify teach-outs |
| IW2 Registrar Desk | registrar / Evidence Registrar | clearance queue (G11), recognition adjudication, committees (G6), **G8 completeness monitor**, credential issuance (reserved tier) | adjudicate; convene; issue |
| IW3 QA Console | QA officers | living self-study (BOOK-08 §6.1), coverage/Bloom audits, integrity metrics, item fairness flags | maintain dossier; trigger reviews |
| IW4 Advisor Workspace | advisors | caseload twins, GPS hedges, risk stream | co-review plans; interventions |
| IW5 Steward Console | AI Pedagogy Steward | agent scorecards (BOOK-10 Ch. 8), calibration drift, incident queue, release gates | approve releases; throttle; investigate |
| IW6 Operator Plane | platform operator | cross-tenant anonymized I4, driver health, mesh lag | operate (BOOK-03 Ch. 5 rules) |

All staff views of learner data are purpose-tagged and audited (BOOK-06 §5.1);
equity analytics render with n≥10 suppression (BOOK-08).

---

# Chapter 6 — Design System and Quality Bars

1. **Design system (running, binding):** Paper.design tokens — Inter only,
   `var(--)` tokens (no raw hex), no card shadows, hover = background only,
   `useNavigate()`, `t('namespace:key')` i18n everywhere (bilingual IT/EN
   minimum — the Builder already is), `institutionType` guards.
2. **Accessibility:** WCAG 2.2 AA floor; accommodations flow from L1
   preferences automatically (assessment accommodations per BOOK-15 Ch. 11 —
   privately applied); the accessibility service audits generated media
   (captions, transcripts, alt text are pipeline outputs, not afterthoughts).
3. **The F2 UX pattern library (running, elevated to law):**
   - *Empty states* teach: every empty canvas explains what will appear and
     offers the first mission;
   - *AI latency*: streamed first token (< 3 s budget), skeletons, honest
     progress ("consulting your knowledge map…" — real stage names, no fake
     spinners), interruptible;
   - *Undo/redo + version history* on every authored artifact;
   - *Propose/accept*: every propose-tier AI output renders as a diff/card
     with accept · edit · reject — never silent application;
   - *Error handling*: degraded modes visible (BOOK-03/09: stale-with-notice,
     deterministic-only banners), never blank failures;
   - *Breadcrumbs* + deep links (Ch. 2.4).
4. **AI-specific affordances (normative):** the **"why?" affordance** on every
   AI-derived element (opens the rendered trace — BOOK-09 Ch. 8); calibrated
   confidence rendering (bands and hedges, BOOK-14 Ch. 8.4); agent attribution
   on request (one voice, inspectable contributors); the **memory panel**
   (WS00) with direct deletion (BOOK-12).

---

# Chapter 7 — Conversational Etiquette

1. **One companion, everywhere:** persistent across workspaces, biased by the
   current one (BOOK-09 §5.1); full-duplex with the canvas (answers link in,
   canvas elements are askable).
2. **Proactivity etiquette:** notifications are missions (actionable), rate-
   limited per person per day (reference: ≤ 3 proactive contacts), quiet hours
   honored, batched digests preferred; the serendipity quota (BOOK-01 Ch. 7)
   surfaces as *"something different"*, labeled as such.
3. **Honesty rules:** the companion says *"I don't know"* (abstain move renders
   as such), shows when it's deferring to a human, and never simulates human
   warmth it doesn't owe — it is a superb assistant, not a friend
   (affect moves are encouragement-of-effort, SDT-consistent, BOOK-09 catalog).
4. **Human escalation is one tap** from any conversation (refer_to_human as UX
   guarantee), and crisis routing (BOOK-11 §5.1) overrides everything with a
   warm, immediate handover.

---

# Chapter 8 — Experience Instrumentation

Experience telemetry rides xAPI (no parallel tracker): time-to-first-value per
WS (aha latency), mission completion rates, companion helpfulness
(thumb + resolution tracking), "why?" affordance usage (explainability that
nobody opens is decoration — target: measured, nonzero), trust signals
(propose-acceptance rates, contest rates), belonging index inputs (WS08).
Experiments follow BOOK-01 Ch. 10: declared target metric + guardrails
(wellbeing, equity blocking); no engagement-only optimization, ever.

---

# Chapter 9 — G-Register Check (standing verification)

| Gap | Disposition |
|-----|------------|
| **G1 office hours** | **resolved**: FW2 publishing + student booking (Ch. 4) |
| G2 appelli | surfaced: WS06 session calendar + readiness; FW2 publication (aggregate in BOOK-15) ✅ |
| G3 verbalizzazione | surfaced: pending-verbalization states rendered honestly (WS06/FW3) ✅ |
| **G4 registro lezioni** | **resolved**: generated register + confirm/annotate + approval mission (FW2) |
| G5 tesi | surfaced: thesis workspace thread in WS06/FW3/FW4 (aggregate in BOOK-15) ✅ |
| G6 commissioni | surfaced: FW3 committee duties, IW2 convening ✅ |
| G7 regulation-year | honored: WS01 renders the learner's regulation context in plans ✅ |
| G8 ANS/SUA-CdS | surfaced: IW2 completeness monitor, IW3 dossier ✅ |
| G9 certificati | surfaced: WS07 self-service documents ✅ (engine in BOOK-16) |
| G10 Diploma Supplement | surfaced: WS07 first-class artifact ✅ |
| G11 conseguimento titolo | surfaced: WS01/WS07 clearance checklist + application flow; IW2 queue ✅ |

Register complete: **G1–G11 all resolved or surfaced**; remaining engineering
lands in BOOK-18 (drivers) and BOOK-20 (sprints).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Portal shell + roles | Next.js portal, Keycloak SSO, role views | ✅ | triad composition per workspace 🔵 |
| Design system | Paper.design plan + tokens + UI checks (automated: no-hex, no-shadow, no-window.location…) | ✅ (partial rollout) | complete UI-REVISION phases 🟡 |
| F2 UX patterns | empty-state, AI-latency, undo/redo, propose/accept, error, breadcrumb sprints | ✅ | elevate to conformance checks 🔵 |
| Student canvases | `StudentCoursePlayer`, `KnowledgeMastery`, `MasteryDashboard`, `StudentProgress`, notification center | 🟡 | WS composition per Ch. 3 (STX-06…14 UI halves) |
| Companion | — | 🔵 STX-06 | one-voice UI + "why?" affordance ⚪ |
| Faculty surfaces | Builder/FEX ✅, gates ✅, sections ✅ — **as of NEW-09 (2026-07-26): FW2 (G1 office-hours booking + G4 generated register) ✅ delivered; FW3 (Verification Desk, single-twin viva scope, honest committee-duties gap) ✅ delivered; FW5 (Envelope Console, wired into the real Decide-step runtime) ✅ delivered** | ✅ **FW2/FW3/FW5 delivered (NEW-09)** | FW4 (not in this sprint's scope) |
| Institution surfaces | dashboards (institution, analytics, LLM usage, AI governance) — **as of NEW-10 (2026-07-26): IW1 Rector's Bridge, IW2 Registrar Desk, IW3 QA Console ✅ delivered as 3 NEW, separate, role-scoped pages** (`institution_workspaces.py`) rather than an extension of the existing `InstitutionDashboard.js` | ✅ **IW1/IW2/IW3 delivered (NEW-10)** | IW4–IW6 composition ⚪ (out of this sprint's scope) |
| Accessibility | `accessibility_service`, AccessibilityDashboard, media QA | ✅ | WCAG 2.2 AA audit cadence 🟡 |
| i18n | i18n infra + t() convention | ✅ | full key coverage 🟡 |
| Experience telemetry | xAPI substrate | ✅ | UX event vocabulary ⚪ |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| The triad | Canvas + Companion + Missions — mandatory workspace anatomy |
| Aha moment | The engineered instant a workspace proves its differentiator |
| Mission | Actionable item bound to a kernel object with exactly one primary action |
| "Why?" affordance | Universal trace-opening control on AI-derived elements |
| Proactivity etiquette | Rate-limited, quiet-hours, digest-first contact discipline |
| Generated register | G4 resolution: system drafts the teaching log, human certifies |
| Honest latency | Real stage names, streaming, interruptibility — no fake progress |
| Recognition-first onboarding | Transfer/professional personas land on WS02 before planning |

---

*BOOK-17 v1.0 — awaiting review. G-register complete (G1–G11). Next: BOOK-18
(Technical Architecture & Turnkey Integration — the mapping and driver Book) and
BOOK-19/20 to close the Masterbook.*
