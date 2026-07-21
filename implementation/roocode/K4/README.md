# K4 Prompt Pack — Trust & Institution

### DAS BOOK-20 Phase K4 · sprints STX-13 + NEW-07, STX-14/15 · generated from the Masterbook v1.0-draft

**Target repo:** `dlu_builder_tk` (the reference implementation).
**Prerequisite:** K3 exit gate — see `../K3/K3-EXIT-REPORT.md`. Every K3
sprint's own V1–Vn checks are green (8/8) and the navigation/evidence
spines (GPS, RouteGraph, Recognition, Evidence Pipeline, AssessmentSession,
Assessment/Tutor/Coach agents, Recommendations v2) are live. **Read the
exit report's §1 and §6 before starting K4 work:** the BOOK-20 §8.1
DAS-Core conformance-suite *infrastructure* (cross-tenant fuzz, driver
chaos tests, NFR dashboards, a gateway-only egress CI gate) is only
**partially** built — real where an individual K3 sprint's own scope
required it, absent as unified K3-phase infrastructure otherwise. K4 does
not get to assume that infrastructure exists; where a K4 verification
below depends on it, the sprint must build the narrow slice it needs
rather than citing K3 for something K3 didn't actually deliver.

**Scope of this pack.** BOOK-20 Ch. 6 names six K4 items:
`STX-13 + NEW-07` (credential engine + signing), `NEW-08` (document
credentials — DS/self-certification/transcript, G9-11), `NEW-17` (credit
recognition & pre-evaluation, G16, added by BOOK-14A), `NEW-16` (catalog
edition & explorer, G15), `STX-14/15` (behaviour + Success + Career +
WS08), and `NEW-09/10` (faculty + institution surfaces). **This pack
authors and executes only `STX-13 + NEW-07` and `STX-14/15`** — the two
sprints explicitly requested. `NEW-08`, `NEW-16`, `NEW-17`, and
`NEW-09/10` are real BOOK-20 K4 deliverables, left for a future prompt
pack pass; do not treat their absence here as an oversight, and do not
fold their scope into STX-13/STX-14/15 opportunistically. (`NEW-17` in
particular is documented in BOOK-20 as already in progress on a separate,
concurrent track — do not touch its files.)

**Execution rules:** BOOK-20 Ch. 12 bind every sprint — read them first.
Digest: Turnkey `CLAUDE.md` guardrails are absolute (GUID PKs for new
tables, `Integer` only for FKs to `courses.id`, platform vs tenant schema,
async routes / sync Celery, additive-only migrations with tested
downgrade, soft delete, no column literally named `metadata`, no
cross-file `relationship()`); all V-checks green before DoD; docs sync in
the same change set (constitution + CLAUDE.md + Book Annexes +
TRACEABILITY); G/A-register duty; ontology naming via `dlu-core.yaml` or
RFC first; **all LLM calls via the ACP gateway (ADR-0013) — never direct
provider calls**; **every learner-facing agent stays
`lifecycle_state='testing'` until its NEW-02 harness run is green and
steward-signed — no exceptions.**

## Order and dependencies

```text
STX-13 + NEW-07 (Credential engine + signing + WS07 · seeds credential agent)
   — depends on STX-08 (evidence/triangulation feeds criteria evaluation)
     and STX-12 (RecognitionClaim is the wallet-import landing model)
STX-14/15 (Behaviour recompute + Success + Career agents + WS08 · hardening)
   — depends on K1 twin core (TwinBehaviourProfile, TwinCareerGoal already
     modeled), STX-12 (GPS `esco_occupation`/career scenario scaffolding,
     currently stubbed — Career Advisor is the first real consumer)
```

- **No blocking edge between the two sprints** — STX-13 and STX-14/15
  touch disjoint tables (`credential_templates`/`issued_credentials` vs
  `twin_behaviour_profiles`) and disjoint agents; they can run in either
  order or in parallel. This pack executes STX-13 first only because it
  was requested first.
- **STX-13 does not extend the three pre-existing, overlapping badge
  implementations** (`backend/services/credential_service.py` +
  `CourseAchievement`; `backend/domains/badge/` unregistered dead code;
  `backend/domains/badges/` unregistered dead code with a real migration;
  the disconnected `services/dlu_badge` microservice with genuine
  Ed25519+JSON-LD signing). The constitution (`STUDENT_EXPERIENCE_
  ARCHITECTURE.md` §13.1) already directs new credential tables into
  `models_student_experience.py` — that is the authoritative instruction
  this sprint follows. The redundancy is real and pre-existing, not
  something STX-13 is expected to clean up; flag it, don't fix it.
- **STX-14/15 cannot inherit a general "cognitive budget engine"** — none
  exists (`ace_service.py`, `ace_worker.py`, and `consolidation_service.py`
  each carry an explicit `TODO(budget): BOOK-09 Ch. 6's general cognitive
  budget engine … is later work` comment). The only budget-shaped
  precedent is `coach_etiquette_service.py`, which is hardcoded to the
  Learning Coach agent alone. STX-14/15 builds a Success-scoped budget
  gate generalizing that shape — not the general BOOK-09 engine, which
  stays open debt (see the residual-debt table below).
- **STX-14/15 cannot inherit an ESCO dataset** — confirmed absent
  end-to-end (no client, no cached snapshot, no seed rows; the codebase's
  own comments in `academic_gps_service.py` say so explicitly, and the
  constitution's own §20 open-decision row 4 assigns "ESCO dataset
  hosting" to STX-12, which did not resolve it). STX-14/15 is the sprint
  that must finally decide and build the v1 answer (a local snapshot, per
  the constitution's own suggestion) — see the STX-14/15 prompt's design
  note.

## K3 residual debt — assigned intake

From `../K3/K3-EXIT-REPORT.md` §6; items this pack can reasonably close or
must explicitly re-defer:

| Debt item | Disposition in K4 |
|-----------|-------------------|
| Gateway-only egress CI gate (repo-wide grep) — cheap, flagged "should be prioritized early in K4" | Out of scope for STX-13/STX-14-15 specifically (neither sprint's own V-checks name it); still open, still worth doing before the K4 exit report is written |
| None of the six K3 agents has run `/agents/{id}/gate` + been steward-signed | Ops/steward action, not a sprint deliverable — unchanged, re-carried |
| `MOVE_CONSULTS` has exactly one entry (`reframe_goal`) | STX-14/15 does **not** need a new consult pair (Success/Career's moves — `flag_risk`, `encourage`, `refer_to_human`, `reframe_goal`, `recommend_next`, `explain_concept` — don't require blackboard consultation to reach L4 by this pack's own design); remains open only if a future sprint finds a real need |
| Cross-tenant leakage fuzz / driver bulkhead chaos / NFR dashboards (unified suites) | Out of scope for individual K4 sprints; carried to the K4 exit report's own residual-debt table unless a dedicated hardening pass is requested |
| Calibration seeding beyond `recommend_next`/readiness/recognition | Unrelated to STX-13/STX-14-15's own predictive surfaces (Credential Agent doesn't predict; Success/Career's risk-scoring and gap-analysis are model-scored, not agent-predicted moves in the STX-11 calibration sense) — not this pack's debt to retire |

## Phase exit gate

**DAS-Intelligent suite green (BOOK-20 Ch. 8.2):** Core (Ch. 8.1) plus —
twin seven layers live with consent/erasure e2e (L6 already has a
consent flag, `CONSENT_LAYER_FLAGS[L6_BEHAVIOUR]`; STX-14/15 must respect
it, not merely inherit it) · ACE trace completeness (100% sampled
cycles) · harness gates enforced in ACP lifecycle · GPS sovereignty audit
(weights inspectable — unaffected by this pack) · **credential survival
suite** (STX-13's own V3: suspension/erasure leave issued credentials
verifiable) · one-voice + "why?" UX checks · scorecards live. This pack
covers only the credential-survival and (partially) the L6-consent
strands of Ch. 8.2 — the rest (ACE trace completeness at 100% sampling,
one-voice/"why?" UX audits, scorecards) are cross-cutting and not owned
by either sprint here; note them as still-open in the K4 exit report
rather than claiming this pack alone satisfies Ch. 8.2.

Produce `K4-EXIT-REPORT.md` (same template as K2/K3) before requesting
further K4 items (`NEW-08`, `NEW-16`, `NEW-09/10`) or K5.

| Sprint | File | Model rec. (CLAUDE.md §14) |
|--------|------|---------------------------|
| STX-13 + NEW-07 | STX-13-credential-agent-signing.md | opus for the signing/DID/status-list scope + proof-format design review, sonnet impl |
| STX-14/15 | STX-14-15-behaviour-success-career.md | opus for the cognitive-budget-scope + ESCO-scope design review, sonnet impl |
