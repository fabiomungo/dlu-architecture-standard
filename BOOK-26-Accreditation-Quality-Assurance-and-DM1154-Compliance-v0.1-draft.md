# BOOK-26 — Accreditation, Quality Assurance & DM 1154/2021 Compliance
### DAS v0.1-draft · Layer: Governance / Institution · Status: IMPLEMENTED (AVA-01…AVA-12, `dlu_builder_tk`, 2026-08-03→2026-08-05 — G22 FULLY CLOSED)

> ✅ **IMPLEMENTED:** all 12 sprints below (AVA-01 through AVA-12) are
> real, committed, and verified against a migrated Postgres — 19 new
> `platform`-schema tables, 5 new services, 8 new API route files, 4
> new Design-System frontend pages, one Celery-beat alert engine, and
> a closed judgment→outcome loop. Closes **G22** (no ministerial
> periodic-accreditation domain — DM 1154/2021 — existed anywhere in
> the platform; BOOK-08 Ch. 6.3's G8 and BOOK-19 Ch. 5.1's G14 each
> covered one narrow adjacent slice — ANS/SUA-CdS completeness
> monitoring and the DE/DI telematic ledger respectively — neither
> touched faculty-requirement math, the Art. 3/4 accreditation
> lifecycle, the Allegato E indicator catalog, the external Auditor/
> CEV persona, or the Allegato C judgment workflow). Every disclosed
> gap below is a genuine, verified absence of real data — never a
> fabricated join or a silently-assumed default; see each section's
> own inline correction.

> Adds the **eleventh and twelfth personas — Auditor MUR/ANVUR and CEV Expert**
> (external, read-only-except-one-documented-exception) — plus extends four
> existing internal roles (PQA/NUV/Coordinatore CdS/Direzione) onto the
> nearest matching `UserRole` entries, since none of those four has a
> dedicated role string yet (disclosed, same v1 posture as every other
> not-yet-built persona role in this program). Grounded directly in
> **Decreto Ministeriale n. 1154 del 14/10/2021** (periodic accreditation
> of Italian university sites and programs) via `docs/AVA_DM1154_2021_
> REQUIREMENTS.md`, a product-design summary of the decree, not the full
> 26-page legal text — every figure this book states as "exact" is
> explicitly cited to that summary, and every figure the summary didn't
> enumerate is a disclosed placeholder, never invented. ER target domain:
> **T14**. Functionality area: **26**. Sprints: **AVA-01…AVA-12**.

---

## 1. Purpose and scope

An Italian university's periodic accreditation — sites re-verified at least
every 5 years, programs every 3 — depends on proving four things continuously,
not just at inspection time: adequate teaching staff against Allegato A/D
minimums, a healthy Allegato E indicator trend, complete and timely SUA-CdS/
SMA/Riesame ciclico documentation, and a defensible Allegato C judgment record
that a CEV visit can actually inspect. Before this book, DLU had no way to
compute any of the four — Dtot/Ttot had no formula anywhere in the codebase,
`accreditation_records` didn't exist, indicator values had no catalog, and the
external Auditor/CEV personas had no access model at all.

Out of scope, disclosed rather than silently narrowed: AI drafting of Riesame
text (task 4 of AVA-12 was conditional — "if added" — and nothing needed it
this program), a real outbound-to-ANVUR/CINECA submission driver (Track B,
same posture BOOK-08's G8 already established for ANS), and reconciling
`BACKLOG_TARGET.xlsx`'s own pre-existing SPRINT-08…22 status-column staleness
(a 3×-already-disclosed gap predating this program entirely — see
`TRACEABILITY.md` §3, SPRINT-07 commit `00a3f15`).

## 2. Domain model (aggregates, T14)

| Aggregate | Root | Key invariants |
|---|---|---|
| AccreditationRegistry | `accreditation_bodies` + `accreditation_records` + `accreditation_reviews` | **R26.1** a record's `outcome_band`/`duration_years`/`status`/`expires_at` are ALWAYS the direct output of `compute_site_outcome` (Art. 3 ladder) — never hand-set |
| FacultyRequirementRulePack | `faculty_requirement_rule_packs` + `student_numerosity_bands` | governed, versioned, institution-scoped-with-global-fallback config (same shape as `ItemCalibrationParams`, BOOK-11) — a recalibration is a new version row, never a rewrite |
| FacultyRequirementEvaluation | `faculty_requirement_evaluations` | append-only cache of a real Dtot/Ttot computation; **R26.2** `w=0` unless a real `num_students`/`max_size` pair says otherwise — never a fabricated scaling factor |
| IndicatorCatalog | `ava_indicators` + `ava_indicator_values` | catalog is editable governance metadata; VALUES are append-only, immutable (before_update/before_delete reject unconditionally) — a recompute always inserts, never overwrites |
| AQDocumentTracking | `sua_cds_records` + `sma_records` + `ciclic_review_records` + `quality_improvement_actions` | completeness computed on READ from `required_fields`/`filled_fields`, never cached/stored — cannot silently drift from the data it describes |
| AuditorAccessGrant | `auditor_access_grants` | time-bound (`valid_from`/`valid_to`), scope JSON (`{sites, programs}`, exact-ID-list only, never a wildcard); **R26.3** an out-of-scope or expired grant read is a structural 403, not a service-layer courtesy check |
| EvidenceRegistry | `ava_dashboard_snapshots` + `accreditation_evidence` | snapshots are FULLY immutable from creation (no `updated_at` column exists at all — signing must be decided at capture time); evidence links a document/snapshot to an indicator and/or a real, FK-enforced attention point |
| AlertEngine | `ava_alerts` | one OPEN alert per (tenant, code, subject) — a still-triggered condition updates severity in place without re-notifying every beat tick; a cleared condition auto-resolves |
| QualityJudgment | `quality_attention_points` + `quality_judgments` | **R26.4** `band` deliberately reuses `AccreditationRecord.outcome_band`'s own vocabulary — aggregating a record's judgments into an outcome is a direct count, never a remapping table |

## 3. Faculty requirement engine (Allegati A & D)

Dtot/Ttot per Allegato A minimums (course type × delivery mode matrix — Laurea
9/≥5 tenured, LM 6/≥4, LMCU-5y 15/≥8, LMCU-6y 18/≥10, exact figures from the
requirements doc §1) scaled by Allegato D enrollment pressure: `W = 0` if
`students ≤ max_size` else `students/max_size - 1`; `Dtot = Dr·(1+W)`,
`Ttot = Tr·(1+0.75·W)`. Tenure is INFERRED from `FacultyProfile.rank`
(`associate_professor`/`full_professor` = tenured) — no literal tenure flag
exists anywhere in this schema, disclosed as a simplification, not asserted as
ministerial fact. `tutors`/`additional_specialists` for distance/health-
professions delivery are seeded as documented PLACEHOLDERS pending verification
against the full decree PDF — the requirements-doc summary doesn't enumerate
them, and inventing a number would misrepresent it as normed.

> ✅ **IMPLEMENTED (AVA-02/AVA-03):** `count_available_faculty` joins the REAL
> curriculum (`ProgramCourse`→`TeachingSection`→`FacultyAssignment`→
> `FacultyProfile`) — no synthetic headcount. `num_students`/`max_size` are
> explicit caller-supplied parameters, not derived, because `Enrollment.
> program_id` is `Integer` while `platform.programs.id` is `GUID` with no DB
> FK at all — a genuine, pre-existing, still-open schema break (not
> introduced by this program) that makes a real per-program enrollment count
> structurally impossible today without a caller supplying it.

## 4. Accreditation lifecycle (Art. 3–4)

`AccreditationRecord` lifecycle: draft→active→(expired|revoked|suppressed),
transitions constrained to an explicit allowed-set. `compute_site_outcome`
(pure): the suppression check (`pct_not_satisfactory ≥ 50%`) is evaluated
FIRST and short-circuits everything else; then ≥75% fully-satisfactory → 5y
no mid-term; ≥50% → 5y with mid-term; else → conditional, 1–2y. Art. 4
auto-decadence (`check_decadence`, pure): missing activation, 2-year
suspension, 30 November faculty-verification failure, >2% new-course
achievement-plan cap, `ISEF > 1` for state universities — the LAST one a
disclosed, deliberate reading of the requirements doc's own explicit framing
("ISEF > 1 (statali)") over the sprint prompt's literal, ambiguous-without-
context "ISEF ≤ 1" wording.

> ✅ **IMPLEMENTED (AVA-04):** every decadence fact
> (`missing_activation`/`suspended_years`/etc.) is an explicit caller-
> supplied parameter — none has a real data source anywhere in this schema
> (course-activation history isn't tracked; ISEF has no financial-
> sustainability table). The ONE real, wired fact is faculty verification,
> which reuses AVA-03's own `FacultyRequirementEvaluation.status` directly.

## 5. Allegato E indicator catalog & computation

23 indicators seeded across ambiti A–E, matching the requirements doc's own
§5 table exactly (not the full ministerial annex — a disclosed representative
subset). Of the 6 automatable D-domain indicators the plan named, a grounded
audit found only **two** genuinely computable from real data:

- **AVA-D4** (% ore docenza da docenti t.i.) — real: confirmed
  `TeachingRegisterSession` hours (actually delivered, not merely scheduled)
  attributed to each section's primary instructor, tenure via the same
  rank-inference as §3.
- **AVA-D2** (% CFU al I anno) — the denominator is real and GOVERNED
  (`RecognitionRulePack "rulepack-it-cfu"`'s `credits_per_year`, BOOK-14A —
  reused, not a third hardcoded `60`); the numerator (credits actually
  earned) has no reliable query path in this schema and is an explicit
  caller-supplied figure.

The other four (**D1** laureati in corso, **D3** prosecuzione II anno, **D5**
CFU estero, **D8** docenti su SSD) are NOT computable today — not query bugs,
genuine schema/infra gaps: D1/D3 are blocked by `Enrollment.program_id` being
`Integer` against a `GUID` `programs.id` with no FK at all (§3's same break);
D5's `backend/domains/mobility/` has the right-shaped fields but is
unmigrated (no Alembic migration ever creates its tables) and unwired
(nothing outside its own package imports it); D8 has no SSD
(settore-scientifico-disciplinare) column anywhere on `FacultyProfile`/
`ProgramCourse`. Each raises a typed `AvaIndicatorInsufficientDataError`
naming the exact gap, kept structurally distinct from a second
`AvaIndicatorExternalSourceError` (AlmaLaurea's D6/D7, VQR's E1, the campus-mq
B4) — a schema bug must never be misreported as "not our data to have."

> ✅ **IMPLEMENTED (AVA-05/AVA-06):** append-only `ava_indicator_values`
> (immutable — `before_update`/`before_delete` reject unconditionally); the
> Celery worker is genuinely `AsyncSession`-in-`asyncio.run()` (the dominant,
> ~20-file convention in this codebase, `kpi_publisher_worker.py`'s own
> shape) rather than the sprint prompt's literal "sync session" phrasing —
> `get_sync_db()` isn't even a real context manager here.

## 6. SUA-CdS / SMA / Riesame ciclico tracking (Allegato A/a, Art. 5)

Completeness is computed on READ (`compute_completeness(required_fields,
filled_fields)`, pure) — never stored, so it can never drift from the data
it describes. `DEFAULT_REQUIRED_FIELDS` is a small, disclosed-representative
subset of real SUA-CdS "quadro" headings (A1–A4, A4a–C1), not the full
ANVUR-portal form; any institution can supply its own list at record-creation
time. Compliance-deadline registration encodes the REAL Italian
academic-calendar convention: 30 November faculty verification falls in the
FIRST calendar year of an a.a. label, the 15 April SUA-CdS deadline in the
SECOND — not an arbitrary date choice.

## 7. Auditor / CEV persona, scoped access & audit trail

Two new external, read-only-by-default roles (`auditor_mur`, `auditor_anvur`,
`cev_expert` — `UserRole`) with time-bound, exact-scope (`{sites, programs}`)
access grants. Two composable dependencies apply across every AVA route:
`require_scoped_ava_read` (GETs — non-auditors pass through unaffected; an
auditor needs an active grant covering the requested subject, then the read
is logged via the REAL `AuditService.log_action` and watermarked) and
`reject_auditor_write` (every mutation, including POSTs that persist
nothing — a disclosed, conservative "no write-shaped action" policy, not an
allowlist of "safe" POSTs).

> ✅ **CORRECTED (AVA-10/AVA-12):** the requirements doc's own persona table
> (§2, P-B) states the CEV expert's entire job IS "compilazione griglia
> punti di attenzione con fasce di giudizio" — a real write, unlike Auditor
> MUR/ANVUR's genuinely read-only P-A profile. AVA-08's first-pass blanket
> "auditors never write" was an overgeneralization, corrected once AVA-10's
> own CEV Fascicolo page needed exactly this capability: a narrow, separately
> tested `require_cev_or_staff_for_outcome` allows ONLY `cev_expert` through
> for outcome-application and judgment-recording — `auditor_mur`/
> `auditor_anvur` remain blocked at both, with no equivalent carve-out.

## 8. Immutable evidence registry

`AvaDashboardSnapshot` — hash-stamped (sha256 of sort-keys JSON, the same
convention `CatalogEdition`/`academic_gps_service`/`teaching_register_
service` already use, not `release_hash.py`, which is agent-config-shaped)
— is FULLY immutable from creation, stricter than `CatalogEdition`'s own
constrained-transition shape: no `updated_at` column exists at all. Signing
is decided at capture time (`sign=True`) or not at all — an unsigned snapshot
is never signed after the fact, you capture a new one. `sign_snapshot_
payload` checks `QesSettings.configured` first and raises honestly rather
than attempting a real network call to an unreachable TSP (no live QES
provider exists in any DLU environment — same posture the ESSE3 driver
already established).

## 9. Alert / early-warning engine (§7 catalog)

All 10 catalog codes (AL-DOC-01/02, AL-DEAD-01/02, AL-SUA-01, AL-DECAY-01,
AL-KPI-01/02, AL-AQ-01, AL-COND-01) as pure `check_al_*` functions (facts in,
alert-or-`None` out — the same shape `check_decadence` already established),
each with a sync sweep gathering real facts and persisting via
`get_or_create_alert` (one open alert per subject; a still-triggered
condition updates in place, never re-notifies every beat tick).
AL-DECAY-01/AL-COND-01 are real, fully tested functions NOT wired into the
automatic sweep — no query in this schema can honestly supply their inputs
today (the same D1/D3/D5/D8 and achievement-plan gaps as §4/§5). Recipient
roles map onto the nearest existing `UserRole` (dean~Coordinatore CdS,
provost~PQA/direzione, admin~leadership) — disclosed, since no dedicated role
exists for any of those four personas yet.

> ✅ **IMPLEMENTED (AVA-11):** genuinely sync `Session` throughout
> (`sync_session_factory`, psycopg2) — the one AVA sprint whose own
> verification bar explicitly checked for it. "Digest" batches every alert
> newly fired in one sweep run into a single combined notification per
> recipient — a real, tested interpretation, not an integration with
> `NotificationFrequency.DAILY/WEEKLY`, which is declared on the model but
> has no batching implementation anywhere in this codebase (confirmed via
> grep before claiming otherwise).

## 10. Attention points, judgments & the closed loop (Allegato C)

15 Allegato C attention points seeded across ambiti A–E (disclosed
representative subset). `QualityJudgment.band` deliberately reuses
`AccreditationRecord.outcome_band`'s own vocabulary, so
`aggregate_judgment_distribution` (pure) turning a record's judgments into
`compute_site_outcome`'s two inputs is a direct count, never a remapping
table — `recompute_outcome_from_judgments` hands that real distribution
straight to the ALREADY-real `apply_site_outcome` (§4), duplicating no
outcome logic. `get_attention_point_traceability` is backed by a migration
that retroactively adds the REAL foreign key `accreditation_evidence.
attention_point_id` always needed (§8's own table existed before this
table did — the FK is added the moment both sides exist, not left soft).
Closed-improvement-action efficacy (§6's own lifecycle) feeds indicator
**AVA-C4** ("Efficacia azioni post-SMA," §5's own catalog) via the real
`ava_indicator_values` store — disclosed as tenant-wide, since
`quality_improvement_actions` carries no subject scoping of its own.

## 11. Frontend dashboards (Design System only)

Four pages under `frontend/src/pages/ava/`, all pure `components/ds/*` (no
antd, matching `ExecutiveDashboard.js`'s own cleanest-precedent template, not
the mixed `RegistrarDesk.js` shape): **AuditorDashboard** (portfolio status/
expiry, faculty semaphore, an indicator KPI, evidence, dated snapshots —
strictly read-only), **QualityAssuranceDashboard** (PQA/NUV: attention-point
ambito structure, SUA-CdS/SMA completeness, audit calendar, tenant-wide
improvement actions), **CourseAccreditationPanel** (Coordinatore: faculty
semaphore, SUA completeness, program indicators), **CevFascicolo** (attention
points + evidence + 4-band judgment entry + a REAL server-computed
outcome/duration via §10's own endpoint).

> ✅ **VERIFIED LIVE (AVA-10):** a real browser walkthrough (Playwright,
> against a live scratch backend + dev server, two seeded users — admin and
> `auditor_mur`) — not just typechecking — caught and fixed two real bugs a
> unit-test pass would have missed: `attach_watermark` returned a DIFFERENT
> response shape (bare array vs. `{items, _watermark}`) depending on the
> caller's role on the SAME endpoint; the indicator-value endpoint required
> a raw GUID no frontend caller would ever hold. Also confirmed, live, that
> `auditor_mur` correctly receives a 403 attempting to apply an outcome
> (§7's `cev_expert`-only carve-out) — the role split proven end-to-end, not
> only asserted by a mocked test.

## 12. Events (A6-closed)

`AvaRequirementEvaluated` (AVA-03), `AvaAuditorRead` (AVA-08, audit-service
action, not the closed Event Mesh taxonomy — an access-log entry, not a
domain event), `AvaAlertFired` (AVA-11, fired only when a NEW alert opens,
never on every beat tick a condition remains true).

## 13. Conformance checks

- C26.1 Faculty semaphore: a real curriculum with 5 available/9 required
  faculty and 500/270 enrollment → `AL-DOC-01` (red) + `AL-DOC-02` (yellow)
  both fire; a later, compliant evaluation resolves both without re-firing.
- C26.2 Art. 3 consistency: a judgment distribution aggregated to 75%
  fully-satisfactory and `compute_site_outcome` called directly on that same
  percentage agree on outcome band and duration — proven both via 27 pure
  tests and a live DB round-trip (AVA-11/AVA-12).
- C26.3 Immutability: an `ava_dashboard_snapshots` row rejects both UPDATE
  and DELETE unconditionally; `ava_indicator_values` likewise.
- C26.4 Scoped access: an auditor with an active grant reads an in-scope
  subject (logged, watermarked) and is refused an out-of-scope one (403, no
  audit-log write on the rejected attempt) — proven live against a real
  `audit_logs` row count, not asserted.
- C26.5 Traceability: an attention point with no linked evidence reports
  `has_evidence=False`; after linking a real `AccreditationEvidence` row, the
  SAME query reports `has_evidence=True` — the FK from §10 makes this a
  structural guarantee, not a convention.

> ✅ **ALL FIVE VERIFIED** — 27+7 pure unit tests (`tests/test_ava_11_alert_
> service.py`, `tests/test_ava_12_quality_judgments.py`) + direct
> asyncio/sync verification scripts against a real migrated Postgres for
> every DB-touching path across all 12 sprints (the established pattern
> this whole program used throughout — the shared `db_session` pytest
> fixture has a known, pre-existing, non-AVA-specific hang, reproduced and
> disclosed rather than silently worked around) + one live Playwright
> browser walkthrough (§11).

## Annex A — Turnkey mapping

| Element | Exists today | Target | ✅ Delivered (AVA-01…12) |
|---|---|---|---|
| Faculty/enrollment data | `FacultyProfile`, `FacultyAssignment`, `TeachingSection`, `Enrollment` | Dtot/Ttot inputs, indicator D-domain numerators | Faculty joins real (§3); `Enrollment.program_id` Integer/GUID break makes enrollment-by-program structurally impossible — caller-supplied throughout, never guessed |
| Governed config | `ItemCalibrationParams` (BOOK-11), `RecognitionRulePack` (BOOK-14A) | Allegato A/D rule packs, indicator-C threshold packs | `FacultyRequirementRulePack`/`StudentNumerosityBand` (own governed tables, same shape); AVA-05's indicator thresholds deliberately left `NULL` — DM 1154 fixes no universal numeric threshold for most indicators |
| Notification/audit | `AuditService.log_action`, `notification_service.create_notification` | Auditor access logging, alert digests | Both reused as-is, zero new logging infrastructure invented |
| RBAC | `UserRole` enum, `User.roles` JSON array | Auditor/CEV/PQA/NUV/Coordinatore personas | 3 new role strings (`auditor_mur`/`auditor_anvur`/`cev_expert`); PQA/NUV/Coordinatore/direzione mapped onto `dean`/`provost`/`admin` — disclosed, no dedicated role built |
| Mobility domain | `backend/domains/mobility/` | AVA-D5 CFU-estero numerator | Confirmed unmigrated + unwired dead code — NOT reused as a real data source, disclosed as `AvaIndicatorInsufficientDataError` |
| New tables | — | T14: ~19 tables | 19 delivered (see §2 aggregate list + `ER_MAP_TARGET.md` §T14) |
| Sprints | — | **AVA-01…AVA-12** | DONE, 2026-08-03→2026-08-05 |
| Register | — | add **G22** (no periodic-accreditation domain) to TRACEABILITY | done — G22 closed |
