# K4 Trust & Institution — Exit Report

**Phase:** K4 (BOOK-20 roadmap) · **Target repo:** `dlu_builder_tk`
**Executed:** 2026-07-23 → 2026-07-24 · **Sprints:** STX-13 + NEW-07,
STX-14/15 (2/2 requested ✅ — this pack's own scope was explicitly
limited to these two; NEW-08, NEW-09/10, NEW-16, NEW-17 are real BOOK-20
K4 deliverables NOT requested, NOT authored, NOT executed this pass)

---

## 1. Exit gate assessment (BOOK-20 Ch. 8.2, "DAS-Intelligent")

Ch. 8.2's own wording: "Core + : twin seven layers live with
consent/erasure e2e; ACE trace completeness (100% sampled cycles);
harness gates enforced in ACP lifecycle; GPS sovereignty audit (weights
inspectable); credential survival suite; one-voice + 'why?' UX checks;
scorecards live." As with K3, this is layered: (a) the two executed
sprints' own V1–Vn checks, and (b) the phase-level DAS-Intelligent
criteria as cross-cutting infrastructure. (a) is fully green. (b) is
**partially** satisfied — real where a sprint's own scope happened to
deliver it, absent as unified phase infrastructure otherwise. Reported
honestly, not conflated.

| Gate criterion | Status |
|---|---|
| STX-13's own V1–V6 checks green | ✅ 11/11 tests, all passing |
| STX-14/15's own V1–V5 checks green | ✅ 17/17 tests, all passing |
| Twin seven layers live with consent/erasure e2e | 🟡 **Partially.** All seven layers (`identity/academic/competency/knowledge/career/behaviour/ai`) are live and readable via `TwinContextService`; L6 consent-gating is real and exercised (STX-14/15's nightly recompute skips non-consenting twins, tested). **Erasure e2e is NOT proven end-to-end**: STX-13's `credential_revocation_service.revoke_or_suspend(purge_pii=True)` exists as a real, tested primitive but has no erasure-subsystem CALLER anywhere in this codebase (confirmed absent by grep before building it) — an erasure REQUEST → credential PII purge → twin data purge chain has never been exercised end-to-end. This is a real gap, not a documentation oversight. |
| ACE trace completeness (100% sampled cycles) | ⚪ **Not measured.** No sampling/completeness audit was built or run this phase. `AceCycleTrace` remains append-only and immutable (STX-06-era guarantee, unaffected), but "100% of cycles produce a trace" has not been verified by an actual audit — asserted by construction (every `run_cycle`/`run_mission` path either persists a trace or returns a `deferred`/error state before one would exist), never measured. |
| Harness gates enforced in ACP lifecycle | ✅ **Unchanged from K2/K3, still true.** `AgentGateRun` + `ctx_hash`-verified deploy gate (NEW-02, K2) continues to apply to all nine agents now registered. **However:** none of the nine agents (the six from K3 plus Credential/Student Success/Career Advisor from K4) has actually RUN its own `/agents/{id}/gate` harness — all nine remain `lifecycle_state="testing"`, zero `deployed` transitions. The gate mechanism is enforced; it has simply never been invoked for any real agent yet. |
| GPS sovereignty audit (weights inspectable) | ✅ **Unaffected, still true from K3.** `PathScenario.objective_weights` remains inspectable (NEW-04, K3) — no K4 sprint touched GPS/RouteGraph. |
| Credential survival suite | ✅ **Real, built this phase.** STX-13's V3 ("survival tests: suspension/erasure leave credentials valid") is a genuine, tested suite: revoking one credential leaves an unrelated credential's status-list bit and row untouched (tested); a `purge_pii=True` erasure leaves the signed VC's OWN offline verification intact (tested, with the honest caveat above that this specific VC shape had no PII to begin with — see `sprint_decisions_20260723_stx13.md` §5 for the documented, non-hidden finding about what a future PII-bearing VC shape would require). |
| One-voice + "why?" UX checks | ⚪ **Not built.** No dedicated one-voice consistency audit or "why?" UX check suite exists for the two new agents (Credential's `celebrate`/`recommend_next`, Student Success's `flag_risk`/`encourage`, Career Advisor's three moves) beyond their own NEW-02 scenario-bank quality rubrics. The `ace.py` `/trace/{cycle_id}` "why?" affordance (K2-era) works generically for any agent including these; a dedicated UX audit of it was not performed. |
| Scorecards live | ⚪ **Not built.** No KPI scorecard/dashboard infrastructure was built in K3 or K4 (K3's own exit report already flagged the identical gap for its own KPI wave — this is the same, still-open, cross-phase debt, not a new K4 miss). |

**Verdict: both requested sprints' own functional delivery PASSED (28/28
tests total). The phase-level DAS-Intelligent criteria are genuinely
partial** — credential survival and harness-gate mechanics are real;
trace-completeness measurement, erasure e2e, one-voice/why UX audits, and
scorecards are not built. This mirrors K3's own honest disclosure
discipline: functional sprint delivery ≠ phase-level infrastructure
completeness, and the two must not be conflated in this report.

---

## 2. Per-sprint delivery and verification outputs

### STX-13 + NEW-07 — Credential Engine + signing + Credential Agent + WS07 (✅ 2026-07-23)

Delivered: `credential_templates`/`credential_signing_keys`/`credential_
status_list_sequences` (platform schema) + `issued_credentials` (tenant
schema); a deterministic criteria engine (no LLM in the eligibility
path); real did:web (one method) + `eddsa-jcs-2022` Data Integrity
signing — a deliberate scope narrowing from JSON-LD RDF canonicalization
(`eddsa-rdfc-2022`) after an opus-class design review found it would pull
in an unused `pyld` dependency and threaten offline verification via its
default network `@context` fetch; versioned per-institution Ed25519 keys
(Fernet-at-rest) so a future rotation never orphans an already-signed VC;
a real W3C Bitstring Status List with a platform-schema row-locked
`status_list_index` allocator (the concrete fix for a genuine concurrent-
issuance collision hazard the design review flagged — never `max()+1`);
wallet API + WS07 UI (`CredentialWallet.js`); wallet import lands as an
unverified `RecognitionClaim` candidate, never a trusted import (no
external issuer trust registry exists); Credential Agent seeded
(`celebrate`/`recommend_next`, structurally incapable of deciding
certificate/degree issuance — that's `credential_issuance_service`'s
HITL-only path). Deliberately left three pre-existing, overlapping
badge/credential implementations untouched (`credential_service.py`/
`CourseAchievement`, `backend/domains/badge(s)/`, the disconnected
`services/dlu_badge` microservice) per the constitution's own explicit
instruction to build new tables in `models_student_experience.py`.
11 tests, all green. Migration (full chain from the first revision)
verified upgrade/downgrade/upgrade clean on an isolated throwaway
Postgres. Found and fixed, incidentally: three CI gate scripts
(`check_evidence_sole_writer.sh`, `check_identity_reconciliation_sole_
mapper.sh`, `check_kg_staging_reads.sh`) had lost their executable bit
during an in-session worktree-recreation event, unrelated to this
sprint's own code, causing 5 spurious test failures — root-caused and
fixed via `git update-index --chmod=+x` (this repo's `core.fileMode=
false` config means a plain `chmod` alone would not have been picked up).

### STX-14/15 — Behaviour recompute + Student Success + Career Advisor + WS08 (✅ 2026-07-24)

Delivered: `behaviour_recompute_service.py` — the first-ever writer of
`TwinBehaviourProfile` (dead since STX-01/02) — a deterministic, named-
constant weighted heuristic over existing aggregate signals
(`AceCycleTrace` activity ratio, `Recommendation` accept/dismiss ratio,
`TutorDialogueState` friction), never an LLM call, never a trained model;
L6-consent-gated per twin (skip, never error, never stale-data reuse); a
NEW `risk_score` threshold crossing (never a repeat) emits `risk.
detected`. `mission_budget_service.py` generalizes STX-10's Learning-
Coach-only `coach_etiquette_service` into a `(agent_key, mission_kind)`-
parameterized primitive — verified behavior-preserving for the Coach's
own existing daily-cap/quiet-hours logic. Student Success Agent binds
`flag_risk`, filed only on a genuine Decide-step confirmation (verified
with three cases: flag_risk / other-move / budget-deferred) — no
advisor-assignment relationship exists anywhere in this data model
(confirmed absent), so the HITL proposal queue itself, the same pattern
every other agent's propose-tier surface already uses, is the v1 human-
connection vehicle, not an invented push notification. Career Advisor's
ESCO gap analysis (`career_gap_service.py`) is grounded in a small,
hand-curated v1 seed (8 occupations, `urn:dlu-esco-lite:` URIs that can
never be mistaken for real ESCO data) — honestly `not_yet_available`
outside it. `success-watch` consumer group (reserved since STX-03, zero
handlers until now) made real: `risk.detected` routes to the gated
mission; `graduation.predicted` registered but honestly dormant (no
producer exists anywhere in this codebase — a distinct, much larger
feature, out of scope). WS08 `EngagementWorkspace.js` — a self-facing
"how you're doing" view (`risk_score` never rendered to the student) +
career-goal gap-analysis panel; route `/student/success` (not
`/student/engagement`, already a pre-existing, unrelated PI-3 page).
**Completes all nine BOOK-10 Ch. 3 agents** with a real config row. 17
tests, all green. Migration verified the same way as STX-13. Found and
fixed, incidentally: the original backend implementation pass omitted
NEW-02 scenario banks for both new agents — authored
`student_success.yaml`/`career_advisor.yaml` (12 scenarios each, all 9
classes) before any test could legitimately claim coverage; also found
`backend/evals/loader.py`'s `BANK_VERSION` was never bumped for STX-13's
own `credential.yaml` addition — bumped once to cover both the missed
STX-13 bump and this sprint's two new banks.

---

## 3. Regression evidence

Full non-integration/non-slow suite, run after each sprint:
- STX-13 (post its own incidental executable-bit fix): **82 failed, 2305
  passed** — down from the STX-10/K3 baseline of 84 failed/2292 passed;
  the delta is fully explained (5 tests broken by an in-session,
  unrelated worktree event, fixed; +11 new STX-13 tests), verified by a
  direct diff of the full failure list before/after the fix, not
  assumed.
- STX-14/15: **82 failed, 2322 passed** — the failure list is
  byte-identical (diffed directly) to the STX-13 post-fix baseline; the
  +17 passed exactly matches STX-14/15's own new tests. Zero new
  regressions from either sprint's own code changes.

Every migration in this phase was verified by running the FULL chain
from the very first revision against a freshly created, isolated,
disposable `pgvector/pgvector:pg15` container (never the shared dev
stack), then downgrade → upgrade again, confirmed via direct schema
inspection (`\d`) at each step.

## 4. `git diff --stat` (implementation repo, K4 range: `631ca85`..`070c2b3`)

```
45 files changed, 5901 insertions(+), 118 deletions(-)
```

Commit series on `stx07-work`:
- `a4505f0` — feat(stx-13): Credential Engine + signing + Credential Agent + WS07 (K4)
- `070c2b3` — feat(stx-14-15): Behaviour recompute + Student Success + Career Advisor + WS08 (K4)

## 5. Register updates (this repo)

- **TRACEABILITY.md:** K4 Trust & Institution row updated twice (once per
  sprint) with full technical detail; "Blocking dependencies" paragraph
  updated (STX-08 ✅ → credential work ✅ closed; the nine-agents roster
  marked complete); NEW-08/09/10/NEW-16/17 explicitly noted as
  BOOK-20-blueprinted, not requested, not started (NEW-17 flagged as
  in-progress on a separate, concurrent track — not touched).
- **BOOK-10-AI-Workforce-v1.0.md:** the nine-agents status row updated
  twice — Credential (STX-13) then Student Success + Career Advisor
  (STX-14/15), the latter closing the row out at 9/9 with a real config
  row, contract card, and scenario bank for every one.
- **BOOK-16-Credential-and-Trust-Architecture-v1.0.md** Annex A: VC
  composition, criteria engine, verification endpoint, status-list
  revocation, and wallet import rows all updated from planned/partial to
  delivered, with the exact scope decisions (JCS not RDF, KMS deferred,
  unverified-import tier) recorded inline.
- **Constitution** (`docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`): new §12
  (Credential Engine, fully rewritten from "design" to "✅ implemented");
  new §9.7c (Behaviour/Success/Career); §13.1/§13.2 (both migrations,
  both new model sets); §14 (both new route surfaces); §15 (WS07/WS08
  rows marked implemented); §18 (phasing table, both sprints); §20 (open
  decisions #3, #4, #5 all resolved with the actual implementation
  choices recorded, not just "decided").
- **Design decision docs** (`dlu_builder_tk`):
  `sprint_decisions_20260723_stx13.md` (9 numbered decisions) and
  `sprint_decisions_20260724_stx14_15.md` (9 numbered decisions), each
  with a full opus-design-review record on its hardest scope call.

## 6. Residual debt / carried forward

| Item | Status | Owner/When |
|---|---|---|
| Erasure e2e chain (erasure request → credential PII purge → twin data purge, exercised end-to-end) | `revoke_or_suspend(purge_pii=True)` exists as a real, tested primitive with no caller — no erasure subsystem exists anywhere in this codebase | Whenever a real GDPR/FERPA erasure workflow is built — flagged, not invented here |
| ACE trace completeness measurement (100% sampled cycles) | Asserted by construction, never actually measured/audited | A dedicated audit pass, K4+ |
| One-voice + "why?" UX checks (dedicated audit, beyond per-agent scenario-bank rubrics) | Not built | K4+ or a UX-focused hardening pass |
| KPI scorecards/dashboards | Not built — same gap K3's own exit report already flagged, still open, not new to K4 | K4+ (carried twice now) |
| Cross-tenant leakage fuzz / driver bulkhead chaos tests / gateway-only egress CI gate | Not built — same gap K3's own exit report flagged, still open | K4+ (carried twice now); user has asked to prioritize this next |
| None of the nine seeded agents has run `/agents/{id}/gate` + steward sign-off | Confirmed — all nine `lifecycle_state="testing"`, zero `deployed` | ops/steward action, not a sprint deliverable |
| `success-watch`'s `graduation.predicted` handler is real but dormant | No producer exists anywhere in this codebase; building one is a distinct, much larger feature | Future sprint, if a graduation-prediction feature is ever requested |
| Every STX-14/15 heuristic weight (`ENGAGEMENT_WEIGHT_*`, `RISK_WEIGHT_*`, `FRICTION_*`) and the pre-existing `RISK_THRESHOLD=0.70` | Explicit, unvalidated v1 policy knobs, chosen with zero real data | Ongoing recalibration once real usage data exists |
| ESCO-lite seed (8 occupations) | Deliberately bounded — full ESCO coverage (~3000 occupations), a live API client, and automated quarterly refresh are all explicitly deferred | Future sprint, if broader coverage is requested |
| NEW-08 (Document credentials, G9/G10/G11), NEW-09/10 (Faculty + Institution surfaces), NEW-16 (Catalog Edition & Explorer, G15) | Real BOOK-20 K4 deliverables — not requested, not authored, not started this pass | User has asked to prioritize authoring these next |
| NEW-17 (Credit Recognition & Pre-Evaluation, G16) | In progress on a separate, concurrent session/track (evidenced by an untracked `BOOK-14A` doc + a G16 TRACEABILITY row neither authored nor touched by this work) | Not this session's concern — do not duplicate |
| NEW-06 (Thesis + Committee, G5/G6) | Still open since K3's own exit report — needs only STX-08 ✅, not blocked by anything in K4 | Whenever prioritized |

## 7. Next

Per the user's explicit direction: (1) author prompt files for the
remaining K4 BOOK-20 Ch. 6 items (NEW-08, NEW-09/10, NEW-16 — NEW-17
excluded, it's the separate concurrent session's own work) into
`implementation/roocode/K4/`, alongside the existing README/STX-13/
STX-14-15 files; (2) begin closing the residual-debt items carried from
K3 into K4 (cross-tenant leakage fuzz, driver bulkhead chaos tests,
gateway-only egress CI gate — NFR dashboards/scorecards not explicitly
called out by the user, treated as lower priority unless redirected).

The K4 phase-level exit gate (DAS-Intelligent, Ch. 8.2) is NOT being
declared closed by this report — the gaps in §1/§6 remain open. This
report documents STX-13/STX-14-15's own delivery honestly against that
gate, consistent with the discipline established in K3's own exit
report, and does not claim phase completion beyond what was actually
built.
