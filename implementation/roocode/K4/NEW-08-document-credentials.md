# Sprint NEW-08 — Document Credentials (G9/G10/G11)
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-07 (GPS path-health), STX-13 (credential engine precedent — NOT extended), K4 (gate)

## Role
`backend-dev` + `frontend-dev` (BOOK-16 Ch. 6.2/6.3/6.4; BOOK-17 IW2;
BOOK-18 Ch. 3/6 driver contracts; BOOK-10A `generate-diploma-supplement`
skill).

## Context — read before coding
1. BOOK-16 Ch. 6 ("Traditional Artifacts as Views") is the operative
   spec, and it is thin — ~30 lines of prose across three subsections,
   no field-level schema, no ELM mapping table:
   - **6.2 Self-certifications and official certificates (G9):**
     self-certification (autocertificazione, DPR 445/2000 style) is
     "fully in scope, native" — DLU generates the document; legal
     standing derives from the learner's OWN declaration, no
     institutional attestation needed. Official certificates (bollo,
     PagoPA) are "content native; stamp duty, payment and signature/seal
     are driver acts" (BOOK-18) — the same content-vs-legal-act split
     (G3 doctrine) already used elsewhere in this system.
   - **6.3 Diploma Supplement (G10):** composed from programme
     description (catalog) + outcomes (P-CUR) + individual results
     (mirror + evidence) + a competency annex (L3, framework-aligned) —
     "DLU MUST generate the DS as a first-class document credential
     (IT/EN), ELM-encoded for Europass."
   - **6.4 Degree application & clearance (G11):** clearance recasts
     *domanda di conseguimento titolo* as "a checklist the GPS already
     knows" — flips when path-health shows all requirements green (exams
     verbalized, thesis deposited, fees settled, surveys done). Learner
     applies when ready; registrar confirms; the physical parchment
     (pergamena) stays institution-side, DLU only tracks request state.
2. **ELM (European Learning Model) has no schema anywhere in the
   Masterbook** — every mention ("ELM-encoded for Europass") is a
   passing reference, confirmed by repo-wide grep across every BOOK-XX
   file. BOOK-20's own V1 verify criterion ("DS validates against ELM
   schema") presupposes a schema that does not exist. This sprint must
   define a minimal, honestly-scoped ELM-shaped JSON schema (the real
   ELM standard's core fields — learner identity, awarding body,
   qualification, learning outcomes, results — not full ELM
   conformance) and validate against THAT, documenting explicitly that
   full Europass ELM interop certification is out of scope.
3. **PagoPA/bollo is a driver-boundary stub, not a real integration**
   (BOOK-18 Ch. 3 driver table): "document issuance blocks on unpaid
   bollo, visibly" is the contract; the real PagoPA adapter is assigned
   to **NEW-12 (Phase K5)**, not this sprint — BOOK-20's NEW-12 entry is
   itself only a one-line stub with no `Deliver:` bullet yet. This
   sprint builds a **local stub** (a driver-shaped interface that always
   reports "unpaid," so the certificate-issuance flow can be proven to
   block visibly) — never a real payment integration. No PagoPA code
   exists anywhere in either repo today.
4. **Repo-verified existing state — read before writing any code:**
   - **Nothing exists for this domain today** — confirmed absent by
     exhaustive grep: `diploma_supplement`, `self_certification`,
     `autocertificazione`, `transcript_generator`, `ELM` (standalone),
     `clearance_checklist`, `PagoPA`, `bollo` all return zero hits in
     `backend/`.
   - **STX-13's credential machinery is a DIFFERENT, DISTINCT concept —
     do not extend or confuse it.** `credential_service.py`/
     `credential_issuance_service.py`/`IssuedCredential` (STX-13) are
     signed OB 3.0/VC-EDU badges — a JSON Verifiable Credential family.
     Document credentials (DS, self-cert, transcript) are **rendered
     PDF documents** — a completely different artifact type, output
     format, and audience. Note the naming collision risk:
     `credential_issuance_service.py`'s `HITL_TYPES = ("certificate",
     "degree")` refers to the STX-13 signed-badge reserved tier, NOT a
     PDF "certificate" in this sprint's sense — pick unambiguous names
     (e.g. `document_credential_service.py`, `DocumentCredential` model)
     that cannot be confused with STX-13's `IssuedCredential`.
   - **PDF/document-generation libraries are already pinned in
     `requirements.txt`** (`weasyprint`, `reportlab`, `python-docx`,
     `Jinja2`, `xlsxwriter`) but **used nowhere in `backend/`** —
     confirmed by grep, zero import sites. This sprint is the first real
     caller; no in-repo pattern exists to copy for HTML/Jinja2→PDF
     rendering — build it fresh, greenfield, documented as such (not a
     silent gap if the first attempt needs iteration).
   - **`academic_gps_service.py`'s `PathHealth`** (already implemented,
     STX-07) computes real, reusable clearance-checklist inputs:
     `requirement_status` (`{completed, required, percent}`) and
     `pending_verbalization` (course IDs whose completion rests on
     `assessment.completed` but not yet the legal `grade.synced` act —
     directly maps to "exams verbalized"). **What it does NOT compute,
     and what does not exist anywhere else in this codebase: thesis
     deposit (NEW-06/Thesis+Committee is confirmed NOT built — no
     `Thesis`/`Committee` model anywhere), survey completion (no
     `Survey` model anywhere), or PagoPA/bollo-specific fee settlement**
     (a generic Stripe-oriented `FinancialHold` exists in
     `backend/domains/payments/models.py`, unrelated to bollo).
   - **IW2 ("Registrar Desk")** is where the clearance queue this sprint
     produces will eventually be READ (BOOK-17 Ch. 5) — but IW2's own
     UI is explicitly assigned to **NEW-09/10, not this sprint**. This
     sprint builds the queue's DATA MODEL + application-flow backend
     only; a minimal read route is fine, a full IW2 console is not this
     sprint's job.
   - **No durable, long-lived staff-approval-queue table exists** to
     model the clearance-application queue on. `move_proposal_service.py`
     is Redis-backed with per-class TTLs (max 7 days) — explicitly the
     WRONG persistence shape for a clearance application that may sit
     open for months. This sprint needs a real DB table, not a reuse of
     the ephemeral HITL store.
5. **Design decision — clearance-checklist honest scope (opus design-
   review verdict: APPROVE WITH CHANGES; do not silently claim full
   BOOK-16 Ch. 6.4 coverage):** BOOK-16's literal clearance criteria are
   "exams verbalized, thesis deposited, fees settled, surveys done."
   `requirement_status`/`pending_verbalization` (GPS path-health) back
   the first dimension for real. **A fourth per-criterion state,
   `waived`, is required alongside `green | not_yet_available | red`** —
   registrar/admin-set, reason-required, audit-logged — marking a
   criterion that genuinely does not apply at an institution/programme
   (no thesis requirement, fees handled off-platform) as distinct from
   one this codebase simply can't source yet. **Clearance is reachable
   iff every criterion is in `{green, waived}`** — `not_yet_available`
   and `red` both block. Without `waived`, this feature can never
   complete a full user journey for ANY institution, which is a worse
   dishonesty than the one this design avoids. **`fees_settled` is NOT
   fully unbacked** — `backend/domains/payments/models.py`'s
   `FinancialHold` already has `blocks_credentials` (default `True`) and
   a `user_has_active_hold()`-style check; resolve `fees_settled` →
   `red` when an active credential-blocking hold exists, `green`
   otherwise — only the bollo/stamp-duty-specific PagoPA act stays
   stubbed (deliverable #7). Only `thesis_deposited` (NEW-06, landing in
   parallel — check `alembic history`/git log before assuming it's still
   absent by the time this sprint runs) and `surveys_done` (no model
   exists anywhere) stay `not_yet_available` in v1. **Every criterion
   MUST be resolved LIVE on read via a per-criterion source resolver
   (thesis/survey → `not_yet_available`; fees → `FinancialHold`;
   requirement/verbalization → `PathHealth`), never frozen at
   application-filing time** — a clearance application can sit open for
   months, and a thesis deposited or a hold released after filing must
   be reflected without re-filing. `source_snapshot` (deliverable #2)
   records the resolved values only at the moment of registrar
   confirmation, not at filing. This makes a future NEW-06 integration a
   resolver swap, not a schema migration. The fixed BOOK-16 criterion
   *vocabulary* (four named criteria) is kept as-is — inventing a
   per-institution configurable criterion set now would be premature
   over-engineering (YAGNI) — but criterion `type` is stored as a
   validated string, not a DB-level CHECK-constrained enum, so a fifth
   criterion is additive later without a migration.

## Deliverables
1. **ELM-lite schema**: a documented, versioned JSON schema (module
   constant, e.g. `ELM_LITE_SCHEMA_VERSION = "v1"`) covering the core
   fields a Diploma Supplement needs — learner identity, awarding
   institution, qualification/programme, learning outcomes (from P-CUR/
   L3), individual results — explicitly NOT a full ELM/Europass
   conformance claim (documented as a bounded subset in the model/
   service docstring).
2. **Document credential model(s)** (new file, e.g.
   `models_document_credentials.py` or an addition to `models_student_
   experience.py` matching this codebase's existing schema-placement
   convention — check first): `document_credential_templates` (or
   inline per-type logic, your call, documented) covering the three
   types (`self_certification`, `diploma_supplement`, `transcript`);
   `issued_document_credentials` (tenant schema, GUID PK — `document_
   type`, `rendered_pdf` reference or storage key, `content_hash`,
   `source_snapshot` JSON capturing exactly which evidence/mirror rows
   fed each field, `issued_at`, `revoked_at`). Every field on the
   rendered document MUST trace to a `source_snapshot` entry (V2's own
   bar) — no field may be typed in free-hand.
3. **Self-certification generator** (act-tier, learner-triggered):
   composes from the learner's own declared/persisted state; no
   institutional attestation; PDF rendered via Jinja2 template →
   WeasyPrint (or the team's chosen library from the already-pinned set —
   document the choice).
4. **Diploma Supplement generator**: composes from catalog + P-CUR
   outcomes + mirror/evidence results + the L3 competency annex,
   ELM-lite-encoded; validated against the ELM-lite schema before
   rendering (V1).
5. **Transcript/ECTS view**: a generated, hash-stamped view over mirror
   grades + the competency annex (constitution §14's existing evidence-
   timeline API is a candidate data source — reuse, don't re-derive).
6. **Clearance checklist + application flow + queue**: a new durable
   table (NOT `move_proposal_service`) holding per-twin clearance
   applications, each criterion (`requirement_completion`,
   `verbalization`, `thesis_deposited`, `fees_settled`, `surveys_done`)
   individually stateful (`green | not_yet_available | red | waived`),
   resolved LIVE on read via a per-criterion source resolver (never
   frozen at filing) — `requirement_completion`/`verbalization` from
   `academic_gps_service.PathHealth`, `fees_settled` from
   `FinancialHold.blocks_credentials`/an active-hold check, `thesis_
   deposited`/`surveys_done` honestly `not_yet_available` until their
   backing models exist (per §5 above; check whether NEW-06 has landed
   before assuming thesis stays unbacked). A learner-facing "apply for
   clearance" action files an application row only when every criterion
   is in `{green, waived}`; registrar confirmation (including any
   `waived` override, reason-required, audited) is a separate act on the
   same row (no auto-confirm). `source_snapshot` records the resolved
   criterion values only at confirmation time. A minimal read route for
   this queue (list applications for a tenant, staff-role gated) — NOT a
   full IW2 console (NEW-09/10's job).
7. **PagoPA driver stub**: a local, honestly-named stub
   (`backend/drivers/pagopa_stub.py` or similar) implementing the
   BOOK-18 driver contract's shape minimally — always reports "unpaid" —
   so bollo-required document issuance can be proven to block visibly
   (V4). Never a real payment integration; documented as a stub, with
   the real adapter's home (NEW-12/K5) named explicitly.
8. **WS07 extension or a minimal new surface** for the learner to
   request/download self-certifications and view their clearance
   checklist — check whether extending STX-13's `CredentialWallet.js`
   (already WS07, already a "your documents" surface) is more honest
   than a brand-new page, given document credentials and signed VCs are
   different artifact types sharing a workspace theme; document whichever
   choice is made and why.

## Verifications
- **V1** DS validates against the ELM-lite schema (this sprint's own
  documented subset — not full Europass ELM conformance, named as such).
- **V2** every rendered document field traces to a `source_snapshot`
  entry citing a real evidence/mirror/catalog row — a fixture test
  confirms no field is present in the rendered output without a
  corresponding snapshot entry.
- **V3** clearance flips exactly when every criterion is in
  `{green, waived}` in a fixture — a negative test confirms clearance
  does NOT flip while any criterion sits at `not_yet_available` or
  `red`, and a separate positive test confirms a registrar-set `waived`
  criterion does NOT block clearance (proving `waived` and `not_yet_
  available` are genuinely distinct, not the same state under two
  names).
- **V4** a bollo-required document (official certificate) visibly blocks
  issuance while the PagoPA stub reports "unpaid" — a fixture test
  confirms the block is visible to the caller (a clear status/reason),
  never a silent 500 or a silently-issued document.
- **V5** (this pack's own addition, matching every prior K4 sprint
  pairing a functional check with regression discipline) `pytest -m
  phase1` stable · migrations up/down/up clean on an isolated Postgres ·
  no confusion between this sprint's `DocumentCredential`-family models
  and STX-13's `IssuedCredential` (a naming/import grep check).

## DoD
V1–V5 green · BOOK-16 Annex A (G9/G10/G11 rows) updated from ⚪/🔵 to ✅
with the actual scope delivered (ELM-lite, not full ELM; PagoPA stub, not
real adapter; clearance reachable via `{green, waived}` per criterion —
thesis/surveys stay `not_yet_available` pending NEW-06/a survey model,
fees resolve from real `FinancialHold` data) · constitution
`STUDENT_EXPERIENCE_ARCHITECTURE.md` gets a new section for this feature
(currently has zero mentions of NEW-08/IW2/clearance/DS — confirmed by
grep) · TRACEABILITY G9/G10/G11 rows updated · decisions note recording:
the ELM-lite field subset chosen, the PDF-rendering library choice and
why, the clearance-checklist honest-scope decision (the `waived` vs.
`not_yet_available` distinction, the `FinancialHold`-backed
`fees_settled` resolver, and the live-on-read per-criterion resolver
design so NEW-06/a future survey model are resolver swaps, not schema
migrations), and the PagoPA stub's exact contract shape (so NEW-12/K5 has
a real interface to replace, not a guess).
