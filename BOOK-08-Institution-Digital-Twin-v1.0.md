# BOOK-08 — Institution Digital Twin
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The third twin: the institution as a continuously observed learning organism.
> Where the Student Twin answers "who is the learner?" and the Faculty Twin
> anchors pedagogical authority, the Institution Twin answers the questions
> boards, rectors and accreditors ask — *are our programs healthy, are our three
> economies balanced, do we have capacity, are we compliant, is the
> transformation on track?* — **continuously, from kernel data, instead of
> annually, from document hunts**.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-02 (three economies,
> scorecard, maturity ladder), BOOK-06 (twin mechanics), BOOK-07 (F5 capacity
> feeds). **Informs:** BOOK-17 (institution workspace), BOOK-19 (compliance),
> BOOK-20 (transformation instrumentation).
> **Primary audience:** rectors, provosts, boards, QA officers, architects.

**Normative language:** RFC 2119. Twin mechanics inherited from BOOK-06 (anchor,
layers, context service, versioning); deltas in Ch. 7. The **ESSE3 gap register
continues here** (G7–G8, institutional level), per the standing instruction that
gaps found in the ESSE3 verification inform all subsequent Books.

---

# Chapter 1 — Purpose

The Institution Twin exists because BOOK-02 made promises that need instruments:

1. The **three economies** (knowledge, trust, attention) must expose health
   indicators (BOOK-02 §3.1) — decisions are tested against all three.
2. The **executive scorecard** (BOOK-02 Ch. 12) must render continuously.
3. **Internal QA is continuous** (BOOK-02 §9.2): the accreditation dossier is
   generated, every claim linked to kernel evidence.
4. The **maturity ladder** (BOOK-02 Ch. 11) is assessed per process area with
   evidence, not self-assessment optimism.

The Twin is the read-model that makes all four true. It is **decision support,
never decision automation**: ACE renders briefing dossiers from it
(propose-tier); no institutional decision is executed by an agent (BOOK-02
Ch. 4 reserved decisions).

---

# Chapter 2 — Layers

Anchor: `InstitutionTwin` (GUID, 1:1 `Institution`, hence 1:1 Tenant). Layers are
computed read-models refreshed on schedules appropriate to their volatility —
the Institution Twin is **almost entirely derived state** (unlike the Student
Twin, which owns career goals and memory).

| Layer | Contents | Sources | Refresh |
|-------|----------|---------|---------|
| I1 — Structure & Offering | hierarchy (Campus/College/School/Department), programs + versions, catalog items, terms, teaching sections | C3 aggregates (live) | real-time (it *is* the structural data) |
| I2 — Academic Health | per-program health composites (Ch. 4): outcome coverage, Bloom profile, completion, learning gain, durability, equity deltas | Coach reports, coverage matrices, BKT/evidence aggregates, xAPI analytics | nightly + on QA events |
| I3 — Three Economies | knowledge/trust/attention indicators (Ch. 3) | mixed (below) | daily |
| I4 — Capacity & Operations | faculty capacity vs HITL queue depths (F5 rollups), AI budget burn per engine/process area, driver health, infra SLOs | F5 aggregates, gateway usage accounting, observability stack | hourly |
| I5 — Compliance Posture | AI Act obligation register status, GDPR/FERPA posture, accreditation dossier freshness, audit findings, incident register | BOOK-19 registers, audit logs | on change + weekly attestation |
| I6 — Strategy & Transformation | maturity level per P01–P08 with evidence links, KPI vs targets, parallel-cost burn-down | BOOK-20 assessments, scorecard feeds | per governance cadence |

Access model: no consent flags (institutional data), but **role-scoped reads**
(dean sees their college; rector sees all; platform operator sees cross-tenant
aggregates only, anonymized) — every read audited like staff twin views.

---

# Chapter 3 — Three-Economy Instrumentation (I3)

Making BOOK-02 §3.1 measurable. Reference indicators (institutions calibrate
targets; presence is normative):

## Knowledge economy

- **Coverage integrity:** % programs with complete I/R/M trajectories
  (`OutcomeCoverageMatrix` — running today).
- **Freshness:** content age distribution; % courses past refresh SLA
  (`ContentRefreshJob` data).
- **Coherence:** unresolved `SAME_AS` candidates and duplicate-concept rate
  (ontology service); KG orphan rate (concepts covered by no lesson).
- **Grounding health:** % AI generations with complete retrieval provenance.

## Trust economy

- **Verification SLA:** median time evidence → human verification decision.
- **Evidence balance:** distribution of evidence types per credential (a
  credential class drifting toward single-source, unproctored evidence is a
  trust erosion alarm — BOOK-01 Ch. 8 triangulation).
- **Integrity incidents:** rate, severity, time-to-resolution.
- **Credential reliability:** verification-endpoint uptime; revocation rate and
  reasons; % explained AI outputs (target 100%, ADR-0006).

## Attention economy

- **Mentorship hours per learner** (F5 rollup) — the metric that MUST rise
  (BOOK-02 Ch. 5.1).
- **HITL queue health:** depth vs capacity per queue type; approval latency
  (a growing queue is an institutional alert, not a faculty failing — BOOK-07
  Ch. 5).
- **Belonging index:** cohort attachment distribution; % learners with zero
  community ties (Success Agent signal source).
- **Faculty load balance:** F5 variance across department; burnout guardrails.

**The balance rule (normative):** I3 MUST render the three economies side by
side. A governance decision brief generated by ACE MUST state expected impact on
all three (the BOOK-02 test, operationalized).

---

# Chapter 4 — Program Health (I2)

## 4.1 The composite

Per program (and per program version), a health record:

```text
ProgramHealth:
  design:    outcome coverage % · Bloom profile match · CAT-trajectory coherence (BOOK-01 5.2.3)
  learning:  completion · learning gain · durability (30d+ retention) · transfer proxy
  equity:    disparate-impact deltas on all learning metrics (blocking guardrail)
  demand:    enrollment funnel · persona mix · recognition inflow (transfer credits)
  economics: C_learner · contribution margin · AI cost share (BOOK-02 8.1)
  delivery:  faculty coverage (sections staffed) · content freshness · learner satisfaction
```

Every element links to its kernel evidence (drill-down, not dashboard folklore).

## 4.2 Program lifecycle decisions

`design → approved → active → under_revision → teach_out → retired`

Health thresholds trigger **proposals** (never automatic transitions): sustained
equity deltas → mandatory review; coverage decay → revision proposal to the
program director; demand collapse → teach-out analysis for the board. Teach-out
protects enrolled learners: their GPS plans are recomputed with guarantees
before any retirement decision is ratified.

## 4.3 The offering pipeline (Italian institutional lens — G7)

The ESSE3/CINECA world manages the **offerta formativa** as a regulated pipeline:
*ordinamento* (ministerial course framework) → *regolamento didattico* (annual
regulation) → *manifesto* (published yearly offering), with cohort-specific
regulation years binding each student. **Gap G7:** DLU's Program/ProgramVersion/
CourseCatalogItem model covers program versioning but not the **regulation-year
binding** (which rules apply to which cohort) nor the ministerial framework
lineage. Resolution: extend ProgramVersion with `regulation_year` semantics and
cohort binding (BOOK-04 C3 extension); where CINECA systems are present, the
ordinamento/OFF.F data is a **driver mirror** (BOOK-07 §6.3 pattern). → BOOK-17
(institution workspace), BOOK-18 (driver contract).

---

# Chapter 5 — Capacity & Operations (I4)

- **Human capacity:** F5 rollups vs contracted load; verification and approval
  queue depths vs available examiner hours; forecast (term calendar ×
  enrollment) so capacity problems surface **before** the exam session, not
  during.
- **AI capacity & economics:** budget burn per engine and process area (BOOK-02
  8.1 attribution), quota exhaustion events (MUST degrade visibly), provider
  fallback activations, cost-per-learner trend.
- **Platform operations:** driver health (per-driver circuit-breaker state —
  BOOK-03 Ch. 6), event-mesh consumer lag, non-functional budget compliance
  (BOOK-03 Ch. 8) — sourced from the running observability stack.

---

# Chapter 6 — Compliance Posture (I5) and the Regulatory Views

## 6.1 The living self-study

I5 holds the **generated accreditation dossier** state: every QA claim
(coverage, Bloom, verification SLAs, integrity metrics) with its kernel evidence
link and freshness stamp (BOOK-02 §9.2). Accreditation preparation becomes
reviewing a dossier that already exists.

## 6.2 AI Act register

Deployer obligations (BOOK-00 Ch. 12, BOOK-02 §9.3) as live posture: named
oversight per system (envelope owners current?), logging completeness, learner
transparency notices version, incident register trend, FRIA status. Red posture
items are board-visible by construction.

## 6.3 Ministerial reporting — Gap G8 (Italian deployments)

Italian universities feed the **ANS (Anagrafe Nazionale Studenti)** through
seven canonical data submissions (*spedizioni*, from career activation onward)
and maintain **SUA-CdS / AVA** records for ANVUR accreditation — today served by
ESSE3/CINECA integrations with the OFF.F and ANS national databases. **Gap G8:**
DLU has no ministerial-reporting capability — and per the driver doctrine it
SHOULD NOT reimplement one where ESSE3 is present (the submissions stay
ESSE3-side; DLU guarantees that everything ESSE3 needs flows to it via the
driver). What DLU MUST add: (a) **completeness monitoring** — I5 tracks that
mirror data required by ANS submissions is present and consistent (missing
career events surface *before* a spedizione fails); (b) **SUA-CdS evidence
feed** — the generated dossier (6.1) exports the quality sections SUA-CdS
requires, as a Track-A view. → BOOK-18 (ESSE3 driver contract), BOOK-19
(compliance calendar).

> The gap register G1–G8 (BOOK-07 Ch. 6 + this chapter) is a **standing
> annex of the standard**: BOOK-15 owns G2/G5/G6 mechanics, BOOK-16 owns G3,
> BOOK-17 owns G1/G4 surfaces, BOOK-18 owns the ESSE3 driver, BOOK-19 owns
> G8 compliance calendaring.
>
> *(Amended by Masterbook Review R2:)* for Italian **telematic** deployments,
> I5 additionally tracks the **DE/DI quota posture** per program (G14 —
> BOOK-19 §5.1): per-CFU Didattica Erogativa/Interattiva ledger health and
> CEV-evidence freshness, alongside the ANS completeness monitor.

**✅ implemented (NEW-13, 2026-07-31):** the completeness monitor reads
NEW-11's own `esse3_boundary_career.ans_completeness_ok`/
`.ans_missing_fields` — the boundary-table row NEW-11 already keeps
fresh IS the completeness signal, never a new computation this Book's
own driver doctrine would otherwise forbid. The SUA-CdS evidence feed is
a Track-A view (`compliance_posture_service.export_g8_dossier_view`)
over the SAME dossier `compute_compliance_posture` already assembles —
not a second document-generation pipeline. Degrades honestly to
`not_yet_available` if NEW-11 has not been executed in a given
deployment (this Book's driver contract is a soft, not hard, dependency).

---

# Chapter 7 — Twin Mechanics Deltas (vs BOOK-06)

1. **Derived, not owned:** layers are recomputed read-models; the Twin stores
   computation lineage (sources + as-of timestamps) so every number is
   reproducible.
2. **Versioning:** `twin_version` bumps per layer refresh; briefs cite the
   version (as agent turns do for student twins).
3. **Snapshots:** at term boundaries and before board meetings — immutable,
   the basis of trend claims and accreditation history.
4. **No erasure** (institutional data), but retention classes apply to
   underlying personal aggregates (equity metrics use cohort minimums to
   prevent re-identification: cells below n=10 are suppressed — normative).
5. **Access:** role-scoped, audited; cross-tenant aggregation only in the
   platform-operator plane, anonymized (BOOK-03 Ch. 5).

---

# Chapter 8 — Consumers

| Consumer | Reads | Via |
|----------|-------|-----|
| Rector/Board | scorecard (I2/I3/I6), red posture items (I5) | institution workspace (BOOK-17) + ACE briefing dossiers (propose-tier) |
| Dean/Program director | their slice of I2/I4; revision proposals | same, college-scoped |
| QA officer | I5 dossier, audit findings | dossier export |
| Registrar | G8 completeness monitor, verification SLAs | operational views |
| Platform operator | anonymized cross-tenant I4 | operator plane |
| Accreditor (external) | exported dossier with evidence links | Track-A artifacts |

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| I1 Structure | `models_institution.py` hierarchy, programs, terms, sections; InstitutionDashboard | ✅ | regulation-year binding (G7) ⚪ |
| I2 Academic health composite | **as of NEW-10 (2026-07-26)**: `program_health_service.py` — design (real, read-time rollup of course-level `OutcomeCoverageMatrix` rows — no code path anywhere writes a genuine `entity_type='program'` row, confirmed, so this is a rollup not a fabricated write), learning (completion real, learning-gain/durability not tracked anywhere), equity (real, n≥`min_n` suppression reusing STX-11's exact floor + `StudentTwin.persona` cohort dimension), demand/delivery (real, via `TeachingSection`), economics (`not_yet_available`, no cost model exists) — every real element carries a drill-down reference; never mutates `Program.active`/`sunset_date` | ✅ **I2 delivered (NEW-10)** | economics dimension; learning-gain/durability tracking |
| I3 Knowledge indicators | coverage ✅, `ContentRefreshJob` ✅, ontology service ✅ — **as of NEW-10, composed into `three_economies_service.py`'s real `knowledge` key** | ✅ **NEW-10** | grounding-provenance metric ⚪ |
| I3 Trust indicators | credential service, audit logs — **as of NEW-10, composed into the real `trust` key** (evidence_balance/integrity_incidents/credential_reliability, each caveated as approximate) | ✅ **NEW-10 (approximate)** | verification SLA instrumentation ⚪ (no `verified_at` timestamp exists anywhere to measure against) |
| I3 Attention indicators | cohorts/forums ✅ — **as of NEW-10, `faculty_load_balance` is real** (via `FacultyAssignment` counts) | 🟡 **NEW-10 (thinnest of the three, honestly)** | mentorship-hours/belonging-index ⚪ (F5 rollups still don't exist); HITL-queue-health ⚪ (deliberately NOT built on `move_proposal_service.list_for_twin`, which reads a test-only fake-client attribute in production — building on it would fabricate a signal, not surface a real one) |
| I4 AI economics | gateway usage accounting, quota budgets ✅ | ✅ | per-engine attribution 🔵 (BOOK-03) |
| I4 Ops | Grafana/OTel stack ✅ | ✅ | consumer-lag + driver-health panels 🟡 |
| I5 Compliance | compliance/multiregion docs, audit service — **as of NEW-13 (2026-07-31), `compliance_posture_service.py` generates the real "living self-study" dossier with all 12 claims real/verified or an honest, data-backed gap**: the original 7 (coverage tracking, evidence sole-writer, credential status-list, CLO→PLO→ILO chain, item-calibration governance, clearance live-resolution, staff-only recognition adjudication) plus 5 NEW-13 fills — AI Act deployer-obligation register (extends the live `ai_agent_configs` registry, never resurrects either dead-code AI-governance attempt), G8 ANS/SUA-CdS completeness monitor (reads NEW-11's own `ans_completeness_ok` signal), G12 RSI ledger, G14 DE/DI ledger (one roster-anchored function, two regimes), G13 Identity Verification Policy (live-resolved, versioned disclosure) — plus a compute-on-read compliance calendar as a new response section | ✅ **I5 dossier fully delivered (NEW-10 + NEW-13)** | none outstanding at I5 posture level — residual gaps are named honestly INSIDE each claim (Moodle instructor-event under-count for G12/G14; FEX v1.4/tutor-mapping/CEV evidence for G14) |
| I6 Transformation | PI status reports, release gates | 🟡 | maturity evidence model ⚪ (BOOK-20) |
| G8 completeness monitor | ERPNext/ESSE3 mirrors | ✅ **NEW-13 (2026-07-31)** | — |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Program health composite | The per-program record of Ch. 4.1, every element evidence-linked |
| Regulation-year binding (G7) | Cohort-to-regulation association of the Italian offerta formativa pipeline |
| Spedizione (G8) | One of the canonical ANS ministerial data submissions |
| Completeness monitor | I5 check that driver mirrors hold everything ministerial reporting needs |
| Cell suppression | n<10 suppression rule for equity analytics (Ch. 7.4) |
| Living self-study | The continuously generated, evidence-linked accreditation dossier |

---

*BOOK-08 v1.0 — awaiting review. The twin trilogy (06/07/08) is complete; next
per dependency order: BOOK-09 (Academic Cognitive Engine), which consumes all
three twins as context.*

**Sources (G7/G8 verification):**
[Cineca — Studenti e Didattica (ESSE3, OFF.F, ANS integration)](https://www.cineca.com/sistemi-informativi-universita/studenti-e-didattica) ·
[Blog ESSE3 ANS — Cos'è l'Anagrafe Nazionale Studenti](http://ans-esse3.cineca.it/ans) ·
[Blog ESSE3 ANS — Le 7 Spedizioni](http://ans-esse3.cineca.it/ans/spedizioni) ·
[CINECA Technical Portal — Anno Accademico di Regolamento e aderenza all'Offerta Formativa](https://wiki.u-gov.it/confluence/display/ESSE3/Anno+Accademico+di+Regolamento+e+l'aderenza+all'Offerta+Formativa)
