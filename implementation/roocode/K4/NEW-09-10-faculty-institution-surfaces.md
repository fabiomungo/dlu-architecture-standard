# Sprint NEW-09/10 — Faculty + Institution Surfaces (G1/G4; I2/I3/I5; IW1–IW3)
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-08 (evidence pipeline), competency_graph_service.verify() (existing), K4 (gate)

## Role
`backend-dev` + `frontend-dev` (BOOK-07 Ch. 2/4/6.1/6.2 Faculty Digital
Twin; BOOK-08 Ch. 2/3/4/6 Institution Digital Twin; BOOK-17 Ch. 4/5
Faculty + Institution workspaces; BOOK-10A `dlu-faculty-envelope-advisor`,
`dlu-inst-dean-briefer` skills).

## Context — read before coding
1. **Scope split, stated explicitly** (BOOK-20 Ch. 6's own sprint-code
   convention): **NEW-09** = the faculty-facing half — FW2 (office hours
   G1, generated register G4), FW3 (Verification Desk), FW5 (Envelope
   Console). **NEW-10** = the institution-facing half — Institution Twin
   composites (I2 program health, I3 three-economy indicators, I5
   compliance posture) + IW1–IW3 surfaces (Rector's Bridge, Registrar
   Desk, QA Console). TRACEABILITY's own G-register rows confirm: G1/G4
   are assigned to NEW-09 specifically, not NEW-10. This prompt covers
   both halves in one change set (matching BOOK-20's own "NEW-09/10"
   pairing) but keep the two halves' code cleanly separable (different
   route files, different frontend surfaces) since they may need to ship
   independently later.
2. **FW2 — office hours (G1) and generated register (G4)** (BOOK-17
   Ch. 4): office hours are "trivial mechanics, outsized trust value" —
   `FacultyProfile.office_hours` (JSON) already exists (see §4 repo
   state) with nothing built on top; this sprint adds the publish/booking
   workflow. The register is a **generated Track-A view** (BOOK-02 Ch.
   9.1 pattern, "bureaucracy inverted: the system drafts, the human
   certifies"): DLU already has delivery/xAPI events; the register is
   DRAFTED from those events, the faculty member confirms/edits
   per-session topics, a department-head approval mission signs off, the
   signed register exports for compliance (BOOK-07 Ch. 6.2's own gap
   framing: "xAPI records delivery activity; the legal register artifact
   does not exist" — this sprint builds that artifact).
3. **FW3 — Verification Desk**: a worklist/queue UI over the EXISTING
   single-action HITL verify primitive (`competency_graph_service
   .verify()`, `POST /api/competencies/{id}/verify` — already live,
   ADR-0012 sole-writer path). This sprint generalizes single-action
   verify into a real staff worklist (list pending items, batch/filter,
   act) — it does NOT reinvent the verify act itself. Also surfaces viva
   dossiers (STX-11, already real) and committee duties tied to G6 —
   **G5/G6 (Thesis + Committee, NEW-06) is confirmed NOT built** (no
   `Thesis`/`Committee` model anywhere) — the committee-duties panel of
   FW3 is therefore honestly `not_yet_available` until NEW-06 lands; do
   not fabricate committee data to fill this panel.
4. **FW5 — Envelope Console** over **F4** (BOOK-07 Ch. 4 Pedagogical
   Envelope). Opus design-review verdict: APPROVE WITH CHANGES —
   verified directly against the runtime path
   (`ace_service.py`'s `_decide`/`check_preconditions`,
   `pedagogical_moves.validate_envelope`) before finalizing this scope:
   - **Storage shape is the FLAT runtime shape, not BOOK-07's nested
     YAML shape.** `validate_envelope()` validates
     `{disabled_moves, disabled_classes, autonomy_caps, limits,
     escalation_overrides}` — a flat structure. BOOK-07 Ch. 4's own
     `autonomy`/`scope.allowed_sources`/`scope.struggle_zone`/
     `scope.tone`/`visibility.transcript_access`/`overrides_reason`
     fields do NOT map onto that validator and have **no enforcement
     path anywhere in the engine today**. Store the flat, engine-
     enforced shape as the source of truth; persist `tone`/
     `allowed_sources`/`transcript_access` ONLY if explicitly marked
     `not_yet_enforced` in the schema/UI — never implying they have a
     live effect they don't.
   - **The table MUST be wired into the actual Decide-step runtime, or
     it is write-only decoration.** `ace_service._decide` currently
     reads a single flat dict, `agent.envelope_defaults or {}`
     (platform-level, `AiAgentConfig`), and composes autonomy as
     "most-restrictive-tier-wins" across catalog/binding/envelope layers.
     A new course-level `faculty_envelopes` row must be resolved and
     MERGED against that platform default at cycle start via a new
     `resolve_effective_envelope(platform, faculty)` function — see
     deliverable #4b. Building the table without this wiring makes V2
     untestable and the console cosmetic.
   - **Learned-default proposals: defer the AI advisor agent itself**
     (`dlu-faculty-envelope-advisor`, BOOK-10A, marked ⚪/K4, not built
     anywhere — building the full agent is a separate, later piece of
     work, not one of the nine BOOK-10 Ch. 3 agents already delivered),
     **but a deterministic, clearly-labeled heuristic hint IS in scope**
     and costs almost nothing: the activity digest (deliverable #4)
     already rolls up per-course move/cap-rejection counts from
     `AceCycleTrace` — a rule like "move X capped-to-propose and
     rejected N× → consider disabling" is real, testable, and beats a
     dead placeholder. It must be labeled a heuristic hint, explicitly
     NOT the advisor agent, so V5's honesty bar still holds — the
     learned-default proposal FEATURE itself (the agent-driven version)
     stays `not_yet_available`.
5. **Institution Twin I1–I6** (BOOK-08 Ch. 2) — only **I2, I3, I5** are
   in this sprint's scope (I1 Structure is already live via
   `models_institution.py` + `InstitutionDashboard.js`; I4
   Capacity/Operations and I6 Strategy are out of scope):
   - **I2 Program Health** (BOOK-08 Ch. 4): a per-`Program`/
     `ProgramVersion` composite — design (outcome coverage %, Bloom
     profile match), learning (completion, learning gain, durability),
     equity (disparate-impact deltas — blocking guardrail, n≥10
     suppressed), demand, economics, delivery. Every element MUST link
     to kernel evidence ("drill-down, not dashboard folklore" — V3's
     literal bar). BOOK-08 Annex A confirms the INPUTS already exist
     (Pedagogical Coach reports, `OutcomeCoverageMatrix`, BKT/analytics
     aggregates) — what's missing is the COMPOSITE + drill-down links,
     exactly this sprint's job. Health thresholds trigger proposals
     only, never automatic program-lifecycle transitions.
   - **I3 Three Economies** (BOOK-08 Ch. 3; theory in BOOK-02 §3.1): the
     three economies are **Knowledge, Trust, Attention** — NOT a
     learner/institution/cost split (confirmed against GLOSSARY.md).
     Reference indicators: Knowledge (coverage integrity, freshness,
     coherence, grounding health), Trust (verification SLA, evidence
     balance, integrity incidents, credential reliability), Attention
     (mentorship hours per learner — "the metric that MUST rise", HITL
     queue health, belonging index, faculty load balance). Normative
     rule: I3 MUST render the three side by side. BOOK-08 Annex A: some
     inputs exist (coverage ✅, `ContentRefreshJob` ✅, credential
     service + audit logs 🟡), others don't (grounding-provenance
     metric, verification-SLA instrumentation, F5 rollups for
     attention — **F5, faculty workload/capacity, does not exist
     either**, so the Attention economy's own inputs are the thinnest of
     the three; scope honestly).
   - **I5 Compliance Posture** (BOOK-08 Ch. 6): the "living self-study"
     (generated accreditation dossier, every QA claim linked to kernel
     evidence + freshness stamp) + AI Act register posture (BOOK-19) +
     (Italian) G8 ANS/SUA-CdS monitor + G14 DE/DI posture. BOOK-08 Annex
     A: 🟡 (compliance/multiregion docs + audit service exist) but the
     generated dossier and AI Act register itself are ⚪ (not built).
6. **IW1–IW3** (BOOK-17 Ch. 5) — Rector's Bridge (IW1: scorecard, I2/I3/
   I6 balance, red-posture items), Registrar Desk (IW2: clearance queue
   G11 — **this sprint reads NEW-08's clearance-application table if
   NEW-08 has landed; if it hasn't, this panel is honestly empty/
   not_yet_available, never fabricated** — plus recognition adjudication
   [already real, STX-12] and committee duties [not_yet_available,
   NEW-06]), QA Console (IW3: living self-study = I5's dossier,
   coverage/Bloom audits, integrity metrics). Cross-cutting rule (BOOK-17
   Ch. 5): all staff views of learner data are purpose-tagged, audited,
   and equity analytics render with **n≥10 suppression** (BOOK-08) — a
   real, in-repo precedent already exists for this exact suppression
   pattern (`ItemCalibrationParams`/item-fairness cohort slicing, STX-11)
   — reuse its shape, don't invent a new one (V4's literal bar).
7. **Repo-verified existing state — read before writing any code:**
   - `FacultyProfile.office_hours` (JSON, `models_institution.py`) — raw
     data field exists, no booking/publish workflow.
   - `TeachingSection`/`FacultyAssignment` (`models_institution.py`,
     CRUD live via `backend/api/routes/teaching_sections.py`) — the
     substrate FW2's register generation reads delivery events against;
     no register-generation logic exists yet.
   - `AiAgentConfig.envelope_defaults` (`models_ai.py`, platform schema)
     — comment already says "per-course faculty envelopes override
     (BOOK-07 F4)" but only stores PLATFORM-level defaults; **no
     per-(faculty, course, agent), faculty-owned, versioned envelope
     table exists** — this sprint builds that new table; do not repurpose
     `envelope_defaults` itself (it's platform-scoped, not faculty-owned).
     `pedagogical_moves.validate_envelope()` is the existing shape-
     validator to reuse for the new table's values.
   - `competency_graph.py`'s `POST /{id}/verify` — the single-item verify
     act, already live; no staff-facing pending-verification LIST/queue
     route exists — build the queue read surface, reuse the verify act
     as-is.
   - `InstitutionDashboard.js` + `GET /api/institution/dashboard` —
     already shows I1-structure KPI cards, outcome-coverage gauges, a
     generic alerts list, and static 1EdTech badges. **No I2 composite,
     no I3 panel, no I5 section exists in it.** Extend this existing
     dashboard/API rather than building a disconnected new page — its
     `useInstitutionalContext()` + `institutionType==='university'` guard
     conventions are the established pattern to reuse.
   - Item-fairness n≥10 suppression precedent: `ItemCalibrationParams`/
     STX-11's cohort-slicing code (`item_calibration_service.py`) —
     reuse this exact suppression mechanism for I2/I3's equity cells and
     IW3's fairness views.
   - `move_proposal_service.py` is the existing propose-tier HITL
     pattern for the envelope advisor's future "learned-default
     proposals" — a natural fit if/when that agent exists, but this
     sprint does not need to wire it (see §4's scope call).

## Deliverables

### NEW-09 (faculty-facing)
1. **FW2 office hours (G1)**: publish/booking workflow on top of
   `FacultyProfile.office_hours` — publishable slots, student booking,
   notification integration (reuse the existing notification
   preference/service pattern, don't invent a new channel).
2. **FW2 generated register (G4)**: a new durable table
   (`teaching_registers` or similar) drafted from `TeachingSection`
   delivery/xAPI events, per-session topics editable by the instructor,
   `submitted_for_approval` → department-head approval mission (a real
   HITL act, not `move_proposal_service`'s ephemeral store — this record
   needs to survive for compliance/audit purposes) → signed/exported.
3. **FW3 Verification Desk**: a real worklist route (list pending
   `StudentCompetency` verify candidates, viva dossiers awaiting
   examiner action, filterable) over the EXISTING verify/viva primitives
   — no new verify logic, a queue view only. Committee-duties panel:
   honestly `not_yet_available` (NEW-06 not built).
4. **FW5 Envelope Console**: new `faculty_envelopes` table (tenant
   schema — `faculty_user_id`, `course_id`, `agent_key`, envelope JSON in
   the FLAT runtime shape validated by
   `pedagogical_moves.validate_envelope()`
   (`disabled_moves`/`disabled_classes`/`autonomy_caps`/`limits`) —
   BOOK-07's `tone`/`allowed_sources`/`transcript_access` fields, having
   no engine enforcement path, are stored only as `not_yet_enforced`;
   `version`, `effective_at`, `created_by`, versioned/audited per Rule
   1); a manual tuning UI (inspect current envelope, propose a change,
   versioned + effective next turn — V2's literal bar); activity digest
   (a simple rollup read, e.g. weekly mission/move counts per course,
   reusing `AceCycleTrace`) PLUS a deterministic, clearly-labeled
   heuristic hint derived from that digest (e.g. "move X capped-to-
   propose and rejected N× this week — consider disabling") — this
   heuristic is NOT the `dlu-faculty-envelope-advisor` agent and must be
   labeled as a heuristic hint, not an AI recommendation; the agent-
   driven "learned-default proposal" feature itself stays explicitly
   `not_yet_available` (per §4's scope decision) — document as deferred,
   not fabricated as working.
4b. **Wire the envelope into the real Decide-step runtime**: a new
   `resolve_effective_envelope(platform_envelope, faculty_envelope)`
   function, called from `ace_service._decide` (or wherever the current
   `agent.envelope_defaults or {}` read happens) BEFORE
   `check_preconditions` — resolves which `faculty_envelopes` row
   applies (keyed `course_id` + `agent_key`; if a `TeachingSection` has
   multiple instructors, resolve by union/most-restrictive across their
   rows, documented as such) and merges it against the platform-level
   `AiAgentConfig.envelope_defaults` under a floor/ceiling rule: the
   faculty row overrides field-by-field but is CLAMPED to the platform
   band (an `autonomy_cap` may only tighten toward, never loosen past,
   the platform ceiling; `disabled_moves`/`disabled_classes` are a UNION
   of both levels; humility-move immunity, already enforced by
   `validate_envelope`, remains a hard floor neither level can weaken).
   The resolved envelope's version is recorded on the `AceCycleTrace` so
   V2 can be tested precisely (a cycle already in flight must use the
   envelope version live when it started, not a version that changed
   mid-cycle).
5. **Frontend**: extend/add faculty-facing pages for FW2/FW3/FW5 (check
   existing frontend structure for any faculty-role page precedent to
   extend rather than building from a blank slate).

### NEW-10 (institution-facing)
6. **I2 Program Health composite**: a per-`Program`/`ProgramVersion`
   read-model service composing the design/learning/equity/demand/
   economics/delivery dimensions from EXISTING sources (Pedagogical
   Coach reports, `OutcomeCoverageMatrix`, BKT/analytics aggregates) —
   every element links to its kernel evidence source (a drill-down
   reference, not just a number). Dimensions with no real backing source
   render honestly `not_yet_available` (e.g. "transfer proxy," "AI cost
   share" if no real cost-attribution data exists yet — check before
   claiming).
7. **I3 Three-Economy panel**: Knowledge/Trust/Attention indicators,
   rendered side by side (normative rule). Reuse what's real (coverage,
   `ContentRefreshJob`, credential/audit data); honestly `not_yet_
   available` for grounding-provenance, verification-SLA, and (since F5
   faculty-workload doesn't exist) most Attention-economy indicators —
   do not fabricate a belonging index or mentorship-hours figure from
   nothing.
8. **I5 Compliance Posture**: the generated "living self-study" dossier
   (every QA claim → kernel evidence link + freshness stamp) + an AI Act
   register posture read (if BOOK-19's register/audit infrastructure
   already has real data to read — verify before building, honestly
   `not_yet_available` otherwise).
9. **IW1 Rector's Bridge**: scorecard view over I2/I3 composites (I6
   excluded, out of scope) + red-posture flagging.
10. **IW2 Registrar Desk**: clearance queue (reads NEW-08's clearance-
    application table if it exists — check `git log`/`alembic history`
    for NEW-08 before building; if NEW-08 hasn't landed, this panel is
    an honest empty state) + recognition adjudication (already real,
    STX-12 — surface it here) + committee duties (`not_yet_available`,
    NEW-06) + G8 completeness monitor read (if real data exists).
11. **IW3 QA Console**: the living self-study dossier (shares I5's data)
    + coverage/Bloom audits (reuse `OutcomeCoverageMatrix`) + integrity
    metrics (reuse existing audit/incident data) + item-fairness flags
    (reuse STX-11's n≥10 suppression pattern directly).
12. **Extend `InstitutionDashboard.js`/`GET /api/institution/dashboard`**
    (or split into role-scoped IW1/IW2/IW3 views per BOOK-17's own
    canvas-column design — your call, document which and why) rather
    than building disconnected new pages.

## Verifications
- **V1** the generated teaching register is reproducible from the same
  delivery-event input (determinism, matching this codebase's own
  reproducibility convention elsewhere — e.g. `PathScenario.
  inputs_fingerprint`) and the human-certify flow requires an explicit
  department-head approval act before export — no auto-certified
  register.
- **V2** an envelope change is versioned (a new row/version, never an
  in-place mutation of a prior version) and takes effect only at the
  NEXT agent turn/cycle — a fixture test confirms a cycle already in
  flight uses the envelope version live when IT started, not a
  mid-cycle change — AND the effective envelope actually used by that
  cycle is `resolve_effective_envelope`'s merge of the platform default
  with the course's faculty override under the floor/ceiling rule
  (autonomy never loosens past the platform ceiling; disabled-sets
  union), with the resolved faculty-envelope version recorded on the
  cycle's `AceCycleTrace` — not just a row existing in the table
  unconnected to any real Decide-step outcome.
- **V3** I2's program-health drill-down reaches real kernel evidence —
  every rendered composite number links to (and a test follows the link
  to) an actual `OutcomeCoverageMatrix`/BKT/evidence row, never a bare
  number with no traceable source.
- **V4** equity cells across I2/I3/IW3 apply n≥10 suppression (reusing
  STX-11's existing mechanism) — a fixture with a cohort cell below the
  floor is suppressed, not shown with a misleadingly small-sample value.
- **V5** (this pack's own addition) honest-scope check: every dimension/
  panel this sprint could not back with real data renders a visible
  `not_yet_available` state, never a fabricated number — a negative test
  asserts this for at least: FW3's committee-duties panel, FW5's
  learned-default-proposal stub, I3's Attention-economy indicators
  lacking F5, IW2's committee-duties panel · `pytest -m phase1` stable ·
  migrations up/down/up clean on an isolated Postgres.

## DoD
V1–V5 green · BOOK-07 Annex A (F4 gap) and BOOK-08 Annex A (I2/I3/I5
gaps) updated from 🟡/⚪ to reflect exactly what was delivered vs. what
remains honestly `not_yet_available` · BOOK-17 Ch. 4/5 (FW2/FW3/FW5,
IW1–IW3) marked implemented with the same honesty · TRACEABILITY G1/G4
rows updated · constitution gets a note if any student-facing surface
was touched (unlikely — this sprint is staff/faculty/institution-facing,
verify no learner-facing route changed) · decisions note recording: the
faculty-envelope table's exact (flat, engine-enforced) schema and its
`resolve_effective_envelope` floor/ceiling merge rule against platform
`envelope_defaults`, which I2/I3/I5 dimensions are real vs. `not_yet_
available` and why, the FW5 advisor-agent deferral decision (heuristic
hint permitted, agent itself deferred), and whether IW1–IW3 extended
`InstitutionDashboard.js` or split into separate pages.
