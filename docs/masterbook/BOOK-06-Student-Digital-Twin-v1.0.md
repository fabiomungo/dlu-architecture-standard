# BOOK-06 — Student Digital Twin
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The specification of the aggregate everything else orbits. The Student
> Experience is built around seven pillars — **Student Digital Twin, Academic GPS,
> Competency Graph, Personal Knowledge Graph, AI Workforce, Evidence-Based
> Assessment, Credential Wallet** — and the Twin is the one that binds the other
> six: it is the shared context of the AI Workforce, the input of the GPS, the
> holder of competency and knowledge state, the subject of evidence, and the owner
> of the wallet. Its mission: accompany the learner **from first orientation to
> the degree and through continuous career development** without ever losing state.
>
> **Conforms to:** BOOK-00 v2.0 (ADR-0004). **Depends on:** BOOK-04 (C7 aggregates,
> identity/consent), BOOK-05 (vocabulary). **Informs:** BOOK-07/08 (sibling twins),
> BOOK-09/10 (agent context), BOOK-14 (GPS input), BOOK-15/16 (evidence, wallet).
> **Implementation profile:** `dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`
> (STX-01/02 sprints) — this Book is the standard; the constitution is its Turnkey
> realization.
> **Primary audience:** architects, AI engineers, data-protection officers.

**Normative language:** RFC 2119.

---

# Chapter 1 — Purpose and Position

## 1.1 What the Twin is

The Student Digital Twin is the **continuously evolving, layered, versioned,
consent-governed representation of one learner within one tenant**. It exists to
answer the first three of the Seven Canonical Questions (BOOK-00 Ch. 2) directly —
*who is the learner, what do they really know, where do they want to go* — and to
supply every other engine with the context needed to answer the rest.

## 1.2 What the Twin is not

- Not a mega-profile table (§2.1); not a data lake of raw behavioural exhaust
  (aggregates only); not a judgment of the person (BOOK-01 Ch. 6.3 — no admission
  scoring, no pricing, no protected-attribute features); not a replacement for
  official records (mirror rule, ADR-0009).

## 1.3 The seven pillars and the Twin's role in each

| Pillar | The Twin's role |
|--------|-----------------|
| Student Digital Twin | *is* it |
| Academic GPS | supplies goals (Career layer), state (Competency/Knowledge layers), constraints (Academic layer); receives adopted plans |
| Competency Graph | Competency layer = the student tier of the graph (BOOK-04 C4) |
| Personal Knowledge Graph | Knowledge layer = the learner's overlay on the Academic Knowledge Network (`KNOWS`, mastery P(L)) — the WS03 "Personal Knowledge Map" is its constitutional rendering |
| AI Workforce | shared context: all nine agents read the Twin through one service, write it only through events (Ch. 6) |
| Evidence-Based Assessment | evidence updates Competency/Knowledge layers; the Twin never holds unevidenced claims |
| Credential Wallet | wallet contents derive from Twin competency state; credentials survive independently of Twin erasure (Ch. 9) |

---

# Chapter 2 — Architectural Decisions

## 2.1 Composite read model (ADR-0004, confirmed)

The Twin is: **(a)** a thin anchor row (identity linkage, lifecycle state, persona,
version, consent); **(b)** layer tables for state the kernel owns; **(c)** mirrors
for state owned elsewhere (ERPNext academic record; BKT mastery; competency
state); **(d)** one assembly service producing the layered context document.

Rationale: single sources of truth stay intact; layers update independently
through events; consistency is managed per layer, not per monolith; erasure and
consent operate at layer granularity.

## 2.2 One person, one tenant, one twin

The Twin is tenant-scoped (BOOK-04 §5.1): a person active in N institutions has N
twins. Cross-tenant linkage is a federation operation (C10), consent-gated
(`cross_institution_sharing`), realized as a mobility dossier — never as implicit
twin merging.

## 2.3 Anchor contract (kernel)

```text
StudentTwin: id (GUID) · user_id → platform.users (GUID, unique) · tenant_id
  · lifecycle_state · persona · twin_version (int, monotonic)
  · consent_flags (purpose-scoped, BOOK-04 §5.2) · last_synced_at
  · soft delete (deleted_at)
```

`twin_version` bumps on **every layer write**; it is the cache-busting and
staleness token for all consumers (agents cite the version they reasoned over).

---

# Chapter 3 — The Seven Layers

Per layer: contents · sole writers · update triggers · consumers · consent gate ·
freshness policy.

## L1 — Identity

- **Contents:** profile, contacts, language, accessibility preferences, IdP
  linkage. **Storage:** `platform.users` + `LearnerProfile` + anchor.
- **Writers:** learner (self-service), registrar. **Triggers:** `profile.updated`.
- **Consent:** none needed (contractual base). **Freshness:** immediate.

## L2 — Academic

- **Contents:** programme, curriculum snapshot, credits earned/required, academic
  status, current term. **Storage:** `TwinAcademicMirror` — read-only mirror of
  ERPNext (`source='erpnext'`, `synced_at`).
- **Writers:** sync consumer only (`enrollment.synced`, `grade.synced` via n8n
  bridge). **Consumers:** GPS (constraints), Navigator, advisors.
- **Consent:** contractual. **Freshness:** sync SLO ≤ 15 min; staleness surfaced
  (`synced_at` always displayed with the data).

## L3 — Competency

- **Contents:** per-competency status (`targeted → … → verified`), confidence,
  levels, links to evidence. **Storage:** `StudentCompetency` (+`EvidenceRecord`
  via C8).
- **Writers:** Competency Engine only (recompute on `evidence.recorded`);
  human verification actions. **Triggers:** `competency.*` events.
- **Consumers:** GPS (gaps), Credential Engine (criteria), Career Advisor,
  open learner model views.
- **Consent:** contractual (it *is* the academic substance). **Freshness:**
  event-driven; decay checkpoint per BOOK-01 Ch. 6 (default 180-day half-life).

## L4 — Knowledge (the Personal Knowledge Graph)

- **Contents:** per-concept mastery P(L) (BKT), prerequisite position, review
  schedule state (SM-2). **Storage:** `concept_mastery` (+ Neo4j `KNOWS` overlay
  as the graph projection).
- **Writers:** mastery tracking service (every scored interaction); kg-sync
  consumer for the overlay. **Triggers:** `mastery.updated`, `activity.recorded`.
- **Consumers:** Tutor (struggle-zone selection), Coach (review missions),
  Recommendation stage-1, WS03 rendering.
- **Consent:** contractual. **Freshness:** near-real-time (per attempt).

## L5 — Career

- **Contents:** goals (target roles, industries, interests), ESCO occupation
  URIs, priorities, goal status. **Storage:** `TwinCareerGoal`.
- **Writers:** learner (directly — goals are self-determined), Career Advisor
  (proposals only). **Triggers:** goal CRUD events.
- **Consumers:** GPS (`best_career_path`), Career Advisor, Discovery Agent.
- **Consent:** `career_processing`. Degradation: career scenario disabled;
  goals remain stored but unprocessed.

## L6 — Behaviour

- **Contents:** computed aggregates only — learning-style distribution, study
  habit histograms, engagement score + trend, dropout risk score. **Storage:**
  `TwinBehaviourProfile`, `features_version`-stamped.
- **Writers:** nightly Celery recompute from xAPI/Caliper streams. **Consumers:**
  Coach (pacing), Success Agent (risk), personalization guardrails.
- **Consent:** `behaviour_analytics`. Degradation: no profile; risk detection
  from academic signals only. **Freshness:** nightly; never real-time (privacy
  by aggregation).
- **Prohibition:** raw event streams MUST NOT be exposed as twin content
  (BOOK-04 Ch. 8, sensitive-learning class).

## L7 — AI

- **Contents:** durable memory (facts, preferences, intervention history,
  conversation summaries — never transcripts), salience, expiry; active
  recommendations. **Storage:** `TwinAIMemory` + `recommendations`.
- **Writers:** **ACE only** (agents propose `memory[]`, the Brain persists —
  BOOK-03 §3.9). **Consumers:** all agents (scoped per Ch. 6), learner
  (inspectable — Ch. 8).
- **Consent:** `ai_personalization`. Degradation: layer returns `None`; agents
  operate stateless. **Freshness:** per turn; expiry honored at read time.

---

# Chapter 4 — Lifecycle and Personas

## 4.1 The eight states

```text
Prospect → Applicant → Candidate → Enrolled → Active Student → Graduate → Alumni → Lifelong Learner
```

The Twin is created at **Prospect** (consent-minimal: identity + declared
interests only) and **never closes** — the continuity from first orientation to
career development is precisely the absence of terminal states. Transitions are
`student.lifecycle.changed` events, triggered by P01 processes (application,
admission, enrollment sync, graduation clearance, alumni transition).

> **Scope amendment (ADR-0026, 2026-08-29):** these eight states describe the
> **Twin** — the person's relationship with the institution over a lifetime —
> and only the Twin. A **regulated academic career** (one specific program
> relationship: a degree, a certificate, a microcredential) is a distinct,
> separate entity, `StudentCareer`, layered *beneath* the Twin
> (`DLU_Student_Lifecycle_Regulatory_State_Model_v1.0.md` §3.2–3.3, ADR-0026).
> A `StudentCareer` **is** terminal — `WITHDRAWN`, `DISMISSED`, `FORFEITED`,
> `TRANSFERRED_OUT`, `GRADUATED`, `DECEASED` close it, reopenable only via an
> explicit authorized `REOPEN_CAREER` event — without contradicting this
> section: one Student may hold several careers (one `GRADUATED`, one
> `ACTIVE`, one still `APPLICATION_SUBMITTED`), and the Twin above them keeps
> its own, independent non-terminal state regardless of how many careers
> beneath it have closed. Nothing in this section changes as a result; it
> continues to govern the Twin exclusively.

| State | Layers active | Dominant pillar/agents | Notes |
|-------|--------------|------------------------|-------|
| Prospect | L1, L5 (declared), L7 (discovery memory) | Discovery Agent | CRM-driven (P01.1.01); no academic mirror yet |
| Applicant | + application dossier refs | Discovery, Recognition (early) | admission is ERPNext/CRM-owned; Twin observes |
| Candidate | + L3 seeded (diagnostics, prior-learning claims) | Recognition Agent | seeded states carry low trust (BOOK-01 Ch. 6.2) |
| Enrolled | + L2 (first sync), L4 initialized | Navigator (first GPS plan) | onboarding P01.1.04, persona-parameterized |
| Active Student | all seven | all nine agents | the steady state |
| Graduate | L2 frozen snapshot; wallet complete | Credential Agent | graduation predicted → cleared → credentialed |
| Alumni | L6 dormant; L5/L7 active | Success (re-engagement), Career Advisor | dormant learner, not an exit (BOOK-02 Ch. 6) |
| Lifelong Learner | as Active, subscription-based | Coach, Career Advisor, GPS | re-entry regenerates L2 mirror against new offerings |

Regression is legal (Alumni → Active on re-enrollment); the Twin history records
every transition (audit).

## 4.2 The five intake personas

**Canonical set:** New Student · Transfer Student · Professional Learner ·
International Student · Corporate Learner.

> **Clarification (supersedes Foundation v1 §12):** "Lifelong Learner" is a
> **lifecycle state**, not an intake persona — every persona eventually becomes
> one. This removes the redundancy between the Foundation's persona list and its
> lifecycle model.

Personas parameterize — they MUST NOT gate capabilities (BOOK-02 Ch. 6):

| Persona | Onboarding emphasis | GPS default | Distinctive twin behaviour |
|---------|--------------------|-----------|---------------------------|
| New Student | Discovery-led: goals elicitation, diagnostic baseline | `fastest_path` within program | L3 starts near-empty; belonging signals watched early (Tinto) |
| Transfer Student | **Recognition-led**: transcript/credit analysis before planning | recompute after recognition | L3 seeded from prior-learning evidence (propose-tier, registrar-verified) |
| Professional Learner | Recognition of experience (CV → competency claims) + goal precision | `highest_competency_growth` | strong L5; pacing tuned to work constraints (L6) |
| International Student | mobility/compliance dossier, language preference | standard | cross-institution consent prompted explicitly; regional pinning verified |
| Corporate Learner | employer framework alignment (SFIA), cohort binding | competency-gap driven | employer visibility is consent-scoped and **minimal-disclosure** (status, not detail) |

> ✅ **IMPLEMENTED (NEW-22, SPRINT-11, 2026-07-31):** the New Student row's
> "diagnostic baseline" is real — `student_onboarding_journeys`/`diagnostic_
> assessments`/`diagnostic_results` (`dlu_builder_tk`, T2), a day-0 flow
> (profile → consents → diagnostic → goal) triggered by `applicant.
> matriculated` at the Enrolled lifecycle state (§4.1), not by the
> Candidate row above. The diagnostic is a confidence self-check over real
> Knowledge Graph concepts, seeding ONLY a separate BKT-based `concept_
> mastery` baseline (`MasteryTrackingService`, reused directly) — it does
> NOT seed L3/`StudentCompetency` the way the Candidate/Transfer Student
> rows above describe for prior-learning evidence; those remain a
> genuinely different, trust-weighted evidence pipeline (NEW-06), never
> touched by this diagnostic.

## 4.3 Persona assignment

Proposed by the Discovery Agent from the intake dialogue, confirmed by the learner
(self-determination — BOOK-01 P7), revisable at any time. Stored on the anchor;
changes are events.

---

# Chapter 5 — Context Assembly

## 5.1 The single door

`TwinContextService.get_context(user_id, layers, purpose)` is the **only** way any
consumer obtains twin state (BOOK-03 §3.2). Direct table reads outside the Twin
Engine are conformance failures.

- `layers`: requested subset; entitlement-checked (Ch. 6).
- `purpose`: mandatory audit tag (`tutor | gps | recommendation | success |
  discovery | staff_view | …`) — logged with actor identity; the basis of the
  staff-access audit (BOOK-02 Ch. 4).
- Consent evaluation happens **here** (BOOK-04 §5.2): ungranted layers return
  `None` + audit entry, callers degrade per their contract.

## 5.2 Caching and consistency

Per-layer Redis cache keyed `(twin_id, layer, twin_version)`; reference TTLs:
300 s default, 3600 s behaviour, no cache for consent. Event consumers bump
`twin_version` (invalidate) on layer writes. Consumers MUST tolerate
**bounded eventual consistency**: the version they read is included in their
output provenance (an agent explanation cites the twin version it reasoned over).

## 5.3 Prompt serialization

Serialization of TwinContext into agent prompts is owned by ACE (BOOK-03 §3.9):
per-agent token budgets, salience-ranked truncation with explicit truncation
markers, vocabulary from the ontology registry (BOOK-05 Ch. 8 — the twin speaks
DLU-Core in prompts, so agent explanations match the UI).

---

# Chapter 6 — The Twin as Shared Agent Context

The nine agents collaborate **through ACE** (implementation name:
`academic_brain_service` — "Academic Brain" is the deprecated synonym, BOOK-00
glossary) and share the Twin as common ground. Entitlements are normative:

| Agent | Reads (layers) | Writes (via events/ACE only) | Never |
|-------|----------------|------------------------------|-------|
| Discovery | L1, L5, L7 | persona proposal, `competency.discovered`, L7 memory | L6 raw signals |
| Recognition | L1, L3, external docs | prior-learning `EvidenceRecord` (propose), L7 | auto-verify (HITL only) |
| Academic Navigator | L2, L3, L4, L5 | `path.replanned` (on adoption), L7 | modify goals (learner-owned) |
| Learning Coach | L4, L6, L7 (+L2 pacing) | review missions, nudges (act-tier), L7 | summative anything |
| Subject Tutor | L4, L7 (+course context) | tutoring evidence trail, L7 | L5, L6 (no career/behaviour in tutoring) |
| Assessment | L3, L4 | formative assessments (act), summative proposals | grade summative alone (BOOK-01 Ch. 8) |
| Credential | L3 | issuance proposals | issue high-stakes without HITL |
| Student Success | L2, L4, L6 | `risk.detected/cleared`, intervention proposals | contact externals without approval |
| Career Advisor | L3, L5 (+labour data) | goal proposals, gap analyses, L7 | rewrite goals; share with employers beyond consent |

Cross-cutting rules:

1. **No agent writes twin tables.** Agents return structured proposals
   (`memory[]`, `events[]`); ACE validates against the taxonomy and ontology,
   then persists/emits (BOOK-03 §3.9).
2. **Least privilege by default:** an agent requesting a layer outside its row
   is denied and the denial audited.
3. **Coordination is Brain-mediated:** agents do not invoke each other; ACE
   routes and sequences (e.g., Recognition results trigger Navigator replanning
   via `competency.updated` → GPS invalidation — event flow, not agent chatter).

---

# Chapter 7 — Versioning, Consistency, Audit

1. `twin_version` is monotonic per twin; every layer write bumps it exactly once
   per transaction (outbox-coupled).
2. Layer writes are serialized per twin (idempotent consumers + per-aggregate
   ordering, BOOK-03 Ch. 4.1); conflicting concurrent writes to the *same* layer
   resolve last-write-wins **within** a layer, never across layers.
3. **Snapshotting:** a full twin snapshot (all layers + version) is taken at every
   lifecycle transition and on demand for audit/mobility dossiers; snapshots are
   immutable and retention-classed (BOOK-04 Ch. 8).
4. Every read with `purpose != learner_self` is audit-logged; every write carries
   its causal event id — the twin's history is fully reconstructible.

---

# Chapter 8 — The Open Learner Model (learner-facing twin)

BOOK-01 P8 made visibility normative; this chapter makes it concrete:

1. **Visibility:** L3, L4 (and their trends) MUST be renderable to the learner in
   inspectable form — the Personal Knowledge Map (WS03) for L4, the competency
   passport view for L3. L6 is summarized in learner-respectful terms; L7 memory
   is listable ("what the AI remembers about me").
2. **Explanation:** every displayed state answers "why": mastery cites recent
   evidence counts and durability; competency confidence cites its evidence
   records and weights (deterministic formula — BOOK-01 Ch. 6).
3. **Contestability:** the learner MAY contest any L3/L4/L7 state. A contest
   creates a review task (HITL for L3 `verified`-adjacent states; automated
   re-diagnostic offer for L4) and is itself logged as a metacognitive event.
4. **Memory control:** the learner MAY delete any L7 memory item directly
   (immediate effect); deletion is honored in the next context assembly.
   ✅ **IMPLEMENTED (NEW-03, 2026-07-18):** `DELETE /api/twin/me/memory/{id}`
   (`dlu_builder_tk`, ownership-checked, ai-layer cache bust — see BOOK-12
   Annex A and BOOK-12 Ch. 6).

---

# Chapter 9 — Privacy, Consent, Erasure

1. **Consent** is purpose-scoped per BOOK-04 §5.2; evaluated at assembly (§5.1);
   changes take effect at next assembly (cache bust); all changes audited.
   Minors (high-school profile): guardian consent per BOOK-19.
2. **Data classes:** L4/L6/L7 are *sensitive-learning* (BOOK-04 Ch. 8): consent-
   gated, region-pinned, aggregate-only, never sold or shared beyond purpose.
3. **Erasure procedure** (GDPR/FERPA, constitutional):
   anchor soft-delete → hard purge of layer tables (L5–L7 immediately, L3/L4 per
   retention schedule) → Neo4j overlay node + relationship deletion → L7 memory
   purge → cache flush. **Exception:** evidence supporting issued credentials is
   retained **pseudonymized** (documented lawful basis) — the Credential Wallet
   survives its owner's twin, because third parties rely on verification.
4. **Region pinning:** twin data never leaves its tenant's region (BOOK-03 Ch. 8);
   mobility dossiers are explicit, consented exports.
5. **Prohibited uses** restated: admission scoring, pricing, employer disclosure
   beyond minimal consented status, any protected-attribute inference (BOOK-01
   Ch. 6.3).

---

# Chapter 10 — Integration Contracts (the other six pillars)

| Pillar | Contract |
|--------|----------|
| **Academic GPS** (BOOK-14) | reads L2/L3/L4/L5 via context service (`purpose=gps`); consumes `competency.updated`, `enrollment.synced` for invalidation; writes back only `path.replanned` + adopted scenario refs into L7 |
| **Competency Graph** | L3 *is* its student tier; definitions stay platform-tier (BOOK-04 C4); recompute contract per BOOK-01 Ch. 6 |
| **Personal Knowledge Graph** | L4 = BKT state + `KNOWS` overlay; WS03 renders it; overlay written only by kg-sync consumers (BOOK-03 §3.3) |
| **AI Workforce** (BOOK-10) | entitlement matrix of Ch. 6; shared memory in L7; all via ACE |
| **Evidence-Based Assessment** (BOOK-15) | evidence pipeline is the only path from activity to L3; L4 updates per attempt; the Twin holds no unevidenced claims |
| **Credential Wallet** (BOOK-16) | criteria evaluate L3; issued credentials referenced from the Twin but stored independently (erasure exception, Ch. 9.3) |

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Anchor + layer tables | `models_student_twin.py` **delivered STX-01 (2026-07-14)** | ✅ | identity duality reconciled (ADR-0014) |
| Context service | `TwinContextService` **delivered STX-02 (2026-07-14)**: purpose audit, Ch. 6 entitlement matrix in code (data-driven), consent gating, per-layer version-keyed cache, `/api/twin`; `tutor_context_service` is now an adapter over it | ✅ | prompt serialization stays with ACE (STX-06) |
| L1 | `platform.users`, `LearnerProfile`, learner routes | ✅ | — |
| L2 mirror | ERPNext + n8n bridge (architecture ✅) | 🔵 | `TwinAcademicMirror` + sync consumers |
| L3 | `Competency`/`CLOCompetency` ✅; `StudentCompetency`+evidence + Competency Engine (recompute §5.3, HITL verify, CASE import, decay checkpoint) — **delivered STX-04 (2026-07-15)** | ✅ | evidence pipeline intake (STX-08) remains the only missing writer |
| L4 | `concept_mastery` BKT ✅ + SM-2 ✅; `KNOWS` overlay 🔵 STX-05 | 🟡 | — |
| L5 | anchor table + manual goal-setting (`PATCH /me/career-goals`, STX-02); Career Advisor gap analysis reads it (STX-14/15) but writes nothing back | 🔵 | no dedicated L5 recompute/write pipeline exists yet |
| L6 | `TwinBehaviourProfile` + `behaviour_recompute_service.py` — first-ever writer, **delivered STX-14/15 (2026-07-24)**: deterministic weighted heuristic over `AceCycleTrace`/`Recommendation`/`TutorDialogueState` signals, L6-consent-gated, threshold-crossing emits `risk.detected` | ✅ | recalibration of the heuristic's weights against real usage data (BOOK-20 residual debt) |
| L7 | `TwinAIMemory` + `memory_write_service.py` — **delivered NEW-03 (2026-07-18)**: consolidation pipeline, consent-gated retrieval, cross-learner isolation (fuzz-tested) | ✅ | the pre-existing STX-06 `/api/brain/memory/{id}` route still has no ownership check (`DELETE /api/twin/me/memory/{id}` does) |
| Lifecycle events | P01 processes ✅; `student.lifecycle.changed` 🔵 STX-03 | 🟡 | — |
| Personas | — | ⚪ | anchor field + Discovery assignment flow (STX-06) |
| Open learner model | `KnowledgeMastery`/`MasteryDashboard` ✅ (partial) | 🟡 | contestability flow ⚪; WS03 map 🔵 |
| Erasure procedure | compliance docs (multiregion) 🟡 | 🟡 | executable erasure job ⚪ (BOOK-19) |
| Snapshots | `twin_snapshots` (immutable) + `create_snapshot`/`set_lifecycle_state` — **delivered STX-02** | ✅ | wire remaining lifecycle producers as they land (ERPNext sync) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Twin anchor | The thin root row: identity linkage, lifecycle, persona, version, consent |
| Personal Knowledge Graph | Canonical name of L4 as rendered to the learner (WS03 Personal Knowledge Map) |
| Intake persona | One of the five canonical onboarding profiles (Ch. 4.2); parameterizes, never gates |
| Purpose tag | Mandatory audit label on every context assembly (`purpose=` of §5.1) |
| Twin snapshot | Immutable full-state capture at lifecycle transitions and on demand |
| Contest | Learner-initiated challenge of a displayed model state (Ch. 8.3) |
| Mobility dossier | Consented, explicit cross-tenant export of twin state (federation) |

---

*BOOK-06 v1.0 — awaiting review. Next per dependency order: BOOK-07 (Faculty
Digital Twin) — or, if preferred, BOOK-13/14 to complete the intelligence spine
first.*


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

**Persona × EKG-usage/RKG-maintenance (RFC-0002, BOOK-19 §1.2):** Student's EKG usage is
`STU-01…12` + tutor `STU-13…15`; its only RKG-maintenance touchpoint is the Open Learner Model's
existing dispute/contest right over its own L3/L4/L7 data (Ch. 8) — never write access to the
graph itself.

The **Student Learning Digital Twin** is the tutor-facing twin projection: goals + mastery (mastery≠confidence) + misconceptions + working/episodic/preference memory. Built via projection services; the browser never computes mastery.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
