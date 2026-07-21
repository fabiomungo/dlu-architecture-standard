# K4 Prompt Pack — Trust & Institution

### DAS BOOK-20 Phase K4 · sprints STX-13 + NEW-07, STX-14/15, NEW-08, NEW-09/10, NEW-16 · generated from the Masterbook v1.0-draft

**Target repo:** `dlu_builder_tk` (the reference implementation).
**Prerequisite:** K3 exit gate — see `../K3/K3-EXIT-REPORT.md`. Every K3
sprint's own V1–Vn checks are green (8/8) and the navigation/evidence
spines (GPS, RouteGraph, Recognition, Evidence Pipeline, AssessmentSession,
Assessment/Tutor/Coach agents, Recommendations v2) are live. **Read
`K4-EXIT-REPORT.md` (STX-13/STX-14-15's own delivery audit) before
starting the remaining K4 sprints below:** the BOOK-20 §8.1/§8.2
conformance-suite *infrastructure* (cross-tenant fuzz, driver chaos
tests, NFR dashboards, a gateway-only egress CI gate, erasure e2e, ACE
trace-completeness measurement, one-voice/"why?" UX audits, scorecards)
is only **partially** built — real where an individual sprint's own
scope required it, absent as unified phase infrastructure otherwise. No
sprint below gets to assume that infrastructure exists; where a
verification depends on it, the sprint must build the narrow slice it
needs rather than citing an earlier phase for something it didn't
actually deliver.

**Scope of this pack.** BOOK-20 Ch. 6 names six K4 items:
`STX-13 + NEW-07` ✅ **delivered** (2026-07-23, credential engine +
signing), `STX-14/15` ✅ **delivered** (2026-07-24, behaviour + Success +
Career + WS08), `NEW-08` (document credentials — DS/self-certification/
transcript, G9-11), `NEW-09/10` (faculty + institution surfaces), `NEW-16`
(catalog edition & explorer, G15) — **prompt files authored, not yet
executed** — and `NEW-17` (credit recognition & pre-evaluation, G16,
added by BOOK-14A) — **explicitly out of this pack's scope; do not touch
its files**, it is documented in BOOK-20 as already in progress on a
separate, concurrent track. Do not fold NEW-17's scope into anything
below opportunistically.

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
STX-13 + NEW-07 (Credential engine + signing + WS07 · seeds credential agent) ✅
   — depended on STX-08 (evidence/triangulation feeds criteria evaluation)
     and STX-12 (RecognitionClaim is the wallet-import landing model)
STX-14/15 (Behaviour recompute + Success + Career agents + WS08 · hardening) ✅
   — depended on K1 twin core (TwinBehaviourProfile, TwinCareerGoal already
     modeled), STX-12 (GPS `esco_occupation`/career scenario scaffolding,
     currently stubbed — Career Advisor is the first real consumer)
NEW-08 (Document credentials — DS/self-cert/transcript/clearance, G9-11)
   — depends on STX-07 (GPS path-health feeds the clearance checklist);
     benefits from (but does not strictly require) NEW-06 (Thesis+
     Committee) for the thesis-deposited clearance criterion — if NEW-06
     hasn't landed, that criterion stays honestly `not_yet_available`
NEW-09/10 (Faculty + Institution surfaces — FW2/FW3/FW5, I2/I3/I5, IW1-3)
   — depends on nothing this pack hasn't already delivered; reads
     STX-08's evidence pipeline (FW3), STX-12's recognition claims (IW2),
     and STX-14/15's Success/Career agents only incidentally (no hard
     blocking edge); if NEW-08 has already landed, IW2 additionally reads
     its clearance-application table (an honest empty state otherwise)
NEW-16 (Catalog Edition & Explorer, G15)
   — depends on NEW-04 (RouteGraphVersion is the immutability pattern to
     copy) and academic_gps_service.compute_scenarios (the engine
     `simulate_scenarios` wraps, never duplicates); NEW-17 (separate,
     concurrent track) depends on THIS sprint's CatalogEdition aggregate —
     do not let that create a reverse dependency; NEW-16 must not touch
     NEW-17's files
```

- **No blocking edge between STX-13 and STX-14/15** — they touched
  disjoint tables (`credential_templates`/`issued_credentials` vs
  `twin_behaviour_profiles`) and disjoint agents; STX-13 ran first only
  because it was requested first.
- **NEW-08, NEW-09/10, and NEW-16 have no blocking edges between each
  other either** — disjoint tables, disjoint surfaces (document
  credentials/clearance vs. faculty-envelope+institution-composite vs.
  catalog-edition+explorer). They can run in any order or in parallel;
  the user's own stated priority (after STX-13/STX-14-15) was "1 and 2"
  — items 1 (author these three prompt files) and 2 (residual-debt
  hardening) — with no stated order among the three sprints themselves.
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

From `../K3/K3-EXIT-REPORT.md` §6 (and re-carried by `K4-EXIT-REPORT.md`
§6 after STX-13/STX-14-15); items the user has asked to prioritize next
("item 2," after authoring NEW-08/09-10/16):

| Debt item | Disposition |
|-----------|-------------|
| Gateway-only egress CI gate (repo-wide grep) — cheap, flagged "should be prioritized early in K4" | **✅ closed (2026-07-24)** — `scripts/ci/check_gateway_only_egress.sh` (+ `tests/test_ci_gateway_only_egress_gate.py`, pass + self-test). Confirmed 8 genuine pre-existing direct-provider call sites predating the ACP gateway cutover (`rag_agent.py`, `content_variation_service.py`, `episodic_vector_service.py`, `kg_nlp_extractor.py`, `kg_service.py`, `media_generation_service.py`, `transcription_service.py`, `academic_embedding_worker.py`) — allowlisted with reasons, NOT migrated (a materially larger task, some may need gateway/LiteLLM config changes for non-chat endpoints like Whisper/DALL-E/embeddings); the gate locks in the current state and catches any NEW direct-construction call site, it does not retroactively fix the eight |
| Cross-tenant leakage fuzz (API + graph + streams + cache) | Still open — a dedicated hardening pass, larger than the egress gate |
| Driver bulkhead chaos tests | Still open — same scope class as the fuzz suite |
| NFR budget dashboards | Still open — not explicitly named in the user's "item 2" ask; lower priority unless redirected |
| None of the nine agents (all delivered as of STX-14/15) has run `/agents/{id}/gate` + been steward-signed | Ops/steward action, not a sprint deliverable — unchanged, re-carried |
| `MOVE_CONSULTS` has exactly one entry (`reframe_goal`) | Remains open only if a future sprint finds a real need — not touched by NEW-08/09-10/16 |
| Erasure e2e chain (credential PII purge → twin data purge, end-to-end) | New gap found at STX-13's own exit audit — `revoke_or_suspend(purge_pii=True)` is a real primitive with no erasure-subsystem caller; still open |

## Phase exit gate

**DAS-Intelligent suite green (BOOK-20 Ch. 8.2):** see `K4-EXIT-REPORT.md`
for the full, honest audit against STX-13/STX-14-15's delivery — credential
survival suite ✅ real; twin-layer consent (not full erasure e2e) 🟡;
ACE trace-completeness measurement, one-voice/"why?" UX audits, and
scorecards ⚪ not built. **NEW-08/NEW-09-10/NEW-16 do not change this
picture on their own** — none of them targets the still-open Ch. 8.2
cross-cutting gaps directly; closing those is tracked separately under
"K3 residual debt" above, per the user's own stated priority order.

`K4-EXIT-REPORT.md` has been produced (STX-13/STX-14-15's own delivery
audit) — it does not declare the K4 phase itself closed; NEW-08/
NEW-09-10/NEW-16 remain to be executed, and a fuller K4 exit assessment
should be revisited once they (and the prioritized residual-debt items)
land.

| Sprint | File | Status | Model rec. (CLAUDE.md §14) |
|--------|------|--------|---------------------------|
| STX-13 + NEW-07 | STX-13-credential-agent-signing.md | ✅ delivered 2026-07-23 | opus for the signing/DID/status-list scope + proof-format design review, sonnet impl |
| STX-14/15 | STX-14-15-behaviour-success-career.md | ✅ delivered 2026-07-24 | opus for the cognitive-budget-scope + ESCO-scope design review, sonnet impl |
| NEW-08 | NEW-08-document-credentials.md | prompt authored, opus design-reviewed (clearance `waived` state + live-resolver design) — not yet executed | opus for the clearance-checklist scope + ELM-lite schema design review, sonnet impl |
| NEW-09/10 | NEW-09-10-faculty-institution-surfaces.md | prompt authored, opus design-reviewed (envelope precedence/wiring + shape fix) — not yet executed | opus for the faculty-envelope precedence/wiring design review, sonnet impl |
| NEW-16 | NEW-16-catalog-edition-explorer.md | prompt authored, opus design-reviewed (snapshot shape + sole-reader gate) — not yet executed | opus for the CatalogEdition snapshot-modeling design review, sonnet impl |
