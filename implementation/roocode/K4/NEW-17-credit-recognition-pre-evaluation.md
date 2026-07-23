# Sprint NEW-17 — Credit Recognition & Pre-Evaluation (G16)
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-16 (editions), NEW-06 (committee, Tier-2), STX-12 (recognition agent/skills) — all delivered

## Role
`backend-dev` + light `frontend-dev`, with an opus-class design review on
the jurisdiction rule-pack schema and the Tier-1/Tier-2 HITL boundary
before implementation (DAS BOOK-14A; BOOK-14 Ch. 4/8; BOOK-15 Ch. 8;
BOOK-16) — the rule arithmetic is exactly the kind of policy encoding
that's hard to reverse once real institutions start citing it.

## Context — read before coding
1. BOOK-14A in full — this sprint's own normative source. Ch. 2 (domain
   model additions: `RecognitionRulePack`, `CreditPreEvaluation`,
   `EquivalenceRule`, `ExternalSyllabusRecord`, `BadgeCreditRule`, plus
   additive columns on `ExternalCourse` and `RecognitionClaim`), Ch. 3
   (the two seeded rule packs — IT-CFU per DM 931/2024, US-SCH per
   PLA/CAEL — **every parameter in these tables is data, never a code
   branch**), Ch. 4 (the three-tier flow: Tier 0 anonymous what-if
   already exists via NEW-16's `simulate_scenarios`; Tier 1 instant AI
   estimate with mandatory non-binding marker + confidence bands; Tier 2
   HITL-validated statement through NEW-06's Committee aggregate), Ch. 5
   (badge-to-credit auto-convalida on the Bestr→ESSE3 pattern), Ch. 6
   (historic-syllabus answer — the *outbound* endpoint is NEW-16's own
   extension, not this sprint's; this sprint owns the *inbound*
   `ExternalSyllabusRecord` side), Ch. 7 (implementation mapping — confirms
   this sprint's exact scope boundary against STX-12/NEW-06/NEW-16/STX-13),
   Ch. 8 (G-register: G16 owned here, register becomes G1–G16 complete).
2. **Repo-verified existing assets to extend, not rebuild:**
   - `backend/database/models_student_experience.py::RecognitionClaim`
     (STX-12) — open claim taxonomy, `status` moves only via
     `recognition_service.adjudicate_claim` (registrar HITL, never a
     formula), `probability_estimate`/`probability_confidence` honestly
     None/"low" until real calibration exists. Add the three BOOK-14A
     columns (`rule_pack_version`, `authenticity_score`,
     `equivalence_rule_id`) additively — do not touch the existing
     probability-honesty discipline.
   - `backend/services/recognition_yield_service.py` —
     `estimate_claim()`, `resolve_claim_class()`, `_clo_external_similarity()`,
     `_eligibility_band()`, `_get_calibration()`,
     `record_adjudication_outcome()`. This is the yield estimator BOOK-14A
     Ch. 2 says the new `EquivalenceRule` precedent memory must feed —
     extend `estimate_claim` to consult precedents before falling back to
     raw similarity, don't fork a parallel estimator.
   - `backend/database/models_institution.py::ExternalCourse` (platform
     schema) — add the additive columns Ch. 2 specifies
     (`ssd_code`, `unit_system`, `units`, `grade_scale`,
     `syllabus_record_id`, `source_edition_year`).
   - `backend/database/models_catalog_edition.py::CatalogEdition` (NEW-16)
     — `CreditPreEvaluation` binds to a pinned edition exactly the way
     `RouteGraphVersion`/enrollment already pin theirs; reuse
     `CatalogEditionImmutableError`'s pattern (typed immutability error,
     never a silent UPDATE) for `CreditPreEvaluation`'s own frozen fields
     once validated.
   - `backend/database/models_thesis_committee.py::Committee`/
     `CommitteeVerdict` (NEW-06) — Tier-2 routes to a `kind="recognition"`
     committee (BOOK-15 Ch. 8 already names this committee kind); reuse
     `committee_service.py`'s formation/conflict-of-interest/convene/
     decide_verdict primitives, do not reimplement a second HITL queue.
   - `backend/services/credential_signing_service.py` —
     `sign_credential(vc_json, signing_key)`, `get_active_key(db,
     institution_id)` (STX-13/NEW-07). The Validated Pre-Evaluation
     Statement is a signed document credential per Ch. 4.2 — reuse this
     signing path, don't build a second one.
   - `backend/domains/badges/models.py::BadgeClass`/`BadgeAssertion` — the
     richer, migration-backed badge domain (the K4 README already flags
     three overlapping badge implementations as pre-existing, undisturbed
     redundancy — `BadgeCreditRule` matches against `BadgeClass` here,
     specifically, since it is the one with real signature verification
     via `services/dlu_badge`; do not add a fourth).
   - `backend/services/event_taxonomy.py` — `EVENT_TYPES` frozenset +
     named constants (e.g. `THESIS_DEFENDED = "thesis.defended"`). Amend
     in the SAME change set as this sprint's code (RFC-first per Ch. 7):
     add `PREEVALUATION_REQUESTED`, `PREEVALUATION_ESTIMATED`,
     `PREEVALUATION_VALIDATED`, `PREEVALUATION_CONVERTED`,
     `CREDENTIAL_RECOGNIZED`.
   - Migration chain: current head is `20260802_0900` (NEW-15, K5's
     last). Chain this sprint's migration off it — do not branch.
3. **Explicit non-goals (repo-verified absent, correctly out of scope
   here):** the outbound historic-syllabus public endpoint is NEW-16's
   own extension (Ch. 6 point 1) — if NEW-16's sprint didn't build it,
   flag as carried debt, do not build it inside NEW-17. ESSE3 convalida
   sync is NEW-11's driver contract (Ch. 7 table) — this sprint's badge
   auto-convalida writes DLU-side evidence/credit disposition only: an
   ESSE3 mirror write, where the driver is present, is NEW-11's own
   consumer of the `credential.recognized` event, not something this
   sprint calls directly. PagoPA fee collection (Ch. 3.1's fee table) is
   NEW-12's driver — this sprint models the fee *policy* as rule-pack
   data, never collects payment itself.

## Deliverables
1. **`RecognitionRulePack`** (platform, GUID, additive migration):
   versioned, effective-dated, regulation-year-aware policy object per
   Ch. 3's two schemas. Seed exactly `rulepack-it-cfu` v1 (unit system,
   SSD+CFU matching basis, legacy equivalences, fraction tolerances,
   DM 931/2024 experience caps, master-credit caps, ITS Academy rules,
   year-placement thresholds, obsolescence window, procedural terms,
   fee schedule) and `rulepack-us-sch` v1 (SCH, minimum grades,
   exclusions, CAEL PLA methods, PLA caps + residency, portability
   disclosure text, financial disclosure text) as **data rows**, not
   constants in Python — a hard-coded jurisdiction parameter anywhere
   outside these rows is this sprint's own V6 conformance failure.
2. **`CreditPreEvaluation`** (tenant, GUID, additive migration): the G16
   aggregate — prospect (twin) → target `CatalogEdition` (pinned, per
   NEW-16) → tier state machine (`tier1_estimated` →
   `tier2_requested` → `tier2_validated` → `converted`, or terminal
   `expired`/`declined`) → per-course disposition table (recognizable |
   partial+integration | excluded+reason) with estimated units +
   confidence band + year-placement estimate (IT) / residency check
   (US). Frozen once `tier2_validated` (mirrors
   `CatalogEditionImmutableError`'s discipline) except for the
   conversion-side fields enrollment sets.
3. **`EquivalenceRule`** (tenant, shareable, additive migration):
   precedent memory — `(external course/certification fingerprint) →
   (internal course/competency, disposition, conditions)`, sourced from
   Tier-2 adjudications. `recognition_yield_service.estimate_claim` and
   the Tier-1 matching engine both consult this table BEFORE falling
   back to raw embedding similarity — a claim backed by a precedent
   gets a materially tighter confidence band (the "faster and more
   accurate with volume" property, Ch. 6.3), never a fabricated exact
   match. Consortium-shareable is a schema affordance (an
   `institution_id` scope column plus a `shared` flag) — cross-tenant
   sharing mechanics are NOT built this sprint (no consortium exists
   yet to share with); leave the column honestly unused beyond the
   owning tenant.
4. **`ExternalSyllabusRecord`** (tenant, additive migration): the inbound
   historic-syllabus evidence — source edition/year, document ref,
   provenance, authenticity signals (reuses the existing
   `plagiarism_service`-adjacent document-processing pipeline for
   extraction, never a new one). Referenced by `ExternalCourse.
   syllabus_record_id` (additive column) and by `RecognitionClaim`.
5. **`BadgeCreditRule`** (platform, additive migration): badge class →
   credit disposition mapping (course convalida | CFU/SCH amount |
   competency evidence weight) + conditions (edition/program scope, rule-
   pack caps). Auto-tier reserved to low-stakes, well-defined rules only
   (language competency badges, transversal skills) — anything touching
   degree-requirement caps arithmetic is `propose` tier into the
   recognition committee queue, never auto-applied, per Ch. 5 point 4.
6. **The three-tier service** (`backend/services/pre_evaluation_service.py`
   or similar): Tier 1 — extraction (reuse STX-12's document-processing
   skills, template-free) → authenticity screening (score, never a
   verdict — detector humility, same posture as BOOK-15 Ch. 9's
   plagiarism-detector rule) → matching engine (precedents ⊕ similarity
   ⊕ rule-pack arithmetic) → disposition table + non-binding marker,
   rendered honestly with confidence bands, **within the request** (no
   background job needed for Tier 1 — V2's <60s budget is a synchronous
   or near-synchronous path). Tier 2 — dossier compilation (citing
   precedents + rule-pack computation trace, R5 deliberation style) →
   routed to a `kind="recognition"` Committee (NEW-06) → verdict per
   item → **on validation**, statement issuance (signed document
   credential via `credential_signing_service`, bound to the pinned
   edition + a validity window) → new `EquivalenceRule` precedent(s)
   recorded from the verdict. Conversion — on enrollment, the validated
   statement converts to formal recognition without re-adjudication
   (window/edition permitting): evidence recorded through STX-08's
   sole-writer service, `RecognitionClaim`s created/updated, GPS replan
   triggered (NEW-04's traffic table), `credential.recognized` emitted.
7. **Badge auto-convalida flow**: wallet import or issuer webhook →
   cryptographic verification (OB 3.0 signature via the existing
   `services/dlu_badge` verification path — trust tier above any parsed
   document) → `BadgeCreditRule` match → `auto` tier: convalida recorded
   + evidence written (STX-08) + `credential.recognized` emitted; `propose`
   tier: one-click item in the recognition committee queue.
8. **Anti-gaming**: Tier-1 rate limits per identity (reuse whatever
   rate-limiting primitive the codebase already has for other
   identity-scoped endpoints — do not invent a bespoke limiter);
   authenticity score below a rule-pack-defined threshold forces Tier 2
   with an original-document requirement; repeated resubmission of
   documents flagged as altered raises the identity's scrutiny level
   (a flag consulted by future Tier-1 requests, not an automatic ban).
9. **Data protection**: `CreditPreEvaluation` and its documents are
   `career_processing`-consent-scoped (same twin consent flag STX-01/02
   already gate on); retention-limited if no enrollment follows within a
   rule-pack-parameterized window (default 12 months per Ch. 4.3 point 5)
   — a Celery sweep, not a manual process; erasable on request (wire
   into whatever erasure primitive exists today — if the K4 exit
   assessment's own "erasure e2e chain has no real caller" gap is still
   open, this sprint's sweep becomes that primitive's first real caller
   for pre-evaluation data specifically, honestly scoped to this
   aggregate only, not a claim to have closed the whole erasure gap).
10. **Light frontend**: extend WS02 (if built) or WS01's simulate-path
    surface with a Tier-1 result view (disposition table, confidence
    bands, non-binding marker, "request validation" action) — match
    whatever WS02 state STX-12/K3 actually left (the K3 exit report
    marked WS02 frontend deferred; if still absent, build the minimal
    Tier-1 result view as this sprint's own contribution rather than
    blocking on a WS02 rebuild that isn't this sprint's scope).

## Verifications
- **V1** rule-pack arithmetic golden cases: IT (fraction tolerance
  deficit ≤1/≤2 CFU, DM 931/2024 caps at 48/24 CFU, obsolescence window,
  year-placement thresholds) and US (minimum-grade exclusions, PLA cap
  at 60 credits, residency ≥12 credits/≥20%) — each a data-driven test
  reading the seeded rule-pack rows, not a hard-coded expectation.
- **V2** Tier-1 end-to-end on a fixture dossier completes and renders
  confidence bands + the non-binding marker within the 60s budget
  (measured, not assumed).
- **V3** estimate→validation→conversion chain: a Tier-1 estimate that
  proceeds to Tier-2 validation and then enrollment conversion leaves a
  resolvable evidence chain (STX-08) and records a new `EquivalenceRule`
  precedent from the committee's verdict.
- **V4** badge auto-convalida round-trip: a signed badge fixture
  triggers `auto`-tier convalida with zero manual steps end-to-end
  (evidence written, event emitted); a `propose`-tier badge rule lands
  in the committee queue instead.
- **V5** anti-gaming: Tier-1 rate limit fires on a fixture burst;
  an altered-document fixture is flagged and forces Tier-2.
- **V6** no hard-coded jurisdiction parameter outside the rule-pack rows
  — a grep gate (mirrors `check_gateway_only_egress.sh`'s pattern)
  scanning this sprint's own new files for suspicious literals (CFU
  caps, credit-hour minimums, residency thresholds) that should be rule-
  pack data instead.
- **V7** migration up/down/up clean (disposable Postgres, never the
  shared dev database) · `pytest -m phase1` stays green · no regression
  in STX-12/NEW-06/NEW-16/STX-13's own test suites (the four sprints
  this one extends).

## DoD
V1–V7 green · BOOK-14A Ch. 8 G-register marked G16 resolved · BOOK-14
Annex (recognition inputs) + BOOK-15 Annex (Committee `kind="recognition"`
usage) + BOOK-16 Annex (statement as document-credential family member)
+ BOOK-20 Ch. 6 NEW-17 card marked delivered · TRACEABILITY G16 row and
K4 phase table updated · design-review note in
`docs/sprint_decisions_*.md` (rule-pack schema + Tier-1/Tier-2 boundary
decisions) · K4 README's NEW-17 entry flipped from "concurrent track, do
not touch" to delivered, with a date · next: NEW-11's ESSE3 driver
becomes the real convalida-mirror consumer of `credential.recognized`;
a consortium-sharing mechanic for `EquivalenceRule` if/when a second
institution exists.
