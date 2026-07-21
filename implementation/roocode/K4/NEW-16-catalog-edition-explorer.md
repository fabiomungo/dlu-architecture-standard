# Sprint NEW-16 — Catalog Edition & Explorer (G15)
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-04 (RouteGraphVersion immutability precedent), academic_gps_service.compute_scenarios (existing, NOT modified), K4 (gate)

## Role
`backend-dev` + `frontend-dev` (BOOK-04 Ch. 3 §C3 CatalogEdition; BOOK-14
Ch. 9 `simulate_scenarios`; BOOK-16 §6.4a; BOOK-17 Ch. 3 Catalog Explorer
+ Ch. 4 FW1; BOOK-10A `dlu-catalog` MCP tool card).

## Context — read before coding
1. **BOOK-04 §C3 — `CatalogEdition` aggregate** (design doc, nothing
   built): "the legal/contractual catalog: versioned, published,
   immutable once effective; enrollment binds a cohort to an edition
   (regulation-year semantics, G7); the formal catalog document is a
   generated view over it." Aggregate members: `CourseCatalogItem` set +
   numbering system, credit rules, designations (e.g. G/W), prerequisites,
   per-course knowledge/competency contributions (`DEVELOPS`/`COVERS`
   declarations), recognition policies.
2. **BOOK-16 §6.4a — the Catalog Edition document**: "one aggregate,
   three renderings" — (a) the legal document (this section: generated,
   hash-stamped, optionally signed, every statement traces to catalog
   rows), (b) the student-facing explorer with what-if simulation
   (item 3 below), (c) the faculty authoring view (FW1, item 4 below).
   **Immutability contract, stated precisely:** once effective, an
   edition never mutates; errata are new SUB-editions with lineage;
   enrollments reference their edition immutably — that reference IS
   the contract.
3. **BOOK-14 Ch. 9 — `simulate_scenarios(hypothetical_fix, target) →
   list[PathScenario]` is a DISTINCT function from the already-
   implemented `compute_scenarios`, not a rename or extension of it.**
   `academic_gps_service.py`'s real `compute_scenarios`/
   `evaluate_current_path` are twin-bound, DB-persisting, authenticated
   operations for an EXISTING `StudentTwin`. `simulate_scenarios` must
   be: (a) driven by a `hypothetical_fix` (self-declared background, no
   real twin), (b) run against a PUBLISHED `CatalogEdition` (this
   sprint's own new aggregate), (c) pre-auth/anonymous-capable, (d)
   write ZERO DB rows and emit ZERO events, (e) rate-limited. Build it as
   a wrapper/adapter reusing the existing deterministic engine's
   internals (the Pareto engine in `route_graph_compiler.py`, the
   scoring logic `compute_scenarios` already calls) — do not duplicate
   that engine, and do not let it touch any twin-scoped table.
4. **BOOK-17 — Catalog Explorer (Ch. 3) is a pre-auth, cross-cutting
   surface** (not a numbered student workspace) — programs/courses/
   prerequisite chains/designations/knowledge-competency contributions/
   recognition policies, explorable, with what-if simulation
   (`simulate_scenarios`); a prospect declares background+goal and sees
   candidate paths BEFORE creating an account; saving a simulation flows
   into the Discovery dialogue (WS00, already real). The legal document
   (§6.4a) is downloadable from the explorer. **FW1 (Ch. 4) is NOT a new
   workspace — it is the ALREADY-EXISTING "Design Studio" (Builder/FEX
   wizard + Factory pipeline + 3-gate approval flow, `backend/api/
   routes/approval.py`, already live).** This sprint's contribution to
   FW1 is new AUTHORING SURFACES bolted onto that existing workspace
   (knowledge/competency contribution declarations, recognition-policy
   equivalency declarations) — not a new FW.
5. **`dlu-catalog` MCP tool does not exist as an MCP server anywhere** —
   confirmed by grep in both repos. BOOK-10A marks it 🔵 (planned, not
   built) with three base tools (`search_programs`, `get_offerings`,
   `get_regulation_year_rules`) that were NEVER built either, despite
   being tagged for an earlier phase (K3). BOOK-20's NEW-16 deliverable
   text ("`dlu-catalog` MCP tools extension") presumes a base server that
   doesn't exist — this sprint must build the BASE `dlu-catalog` MCP
   server (the three pre-existing-in-name-only tools) AND the two new
   ones (`get_edition`, `simulate_path`), not just "extend" something
   real. `services/dlu_badge_mcp/` (from an unrelated STX-13-adjacent
   effort) is the one real, working MCP-server pattern in this codebase
   to copy the FastMCP-style structure from.
6. **G7 "regulation-year binding" is `version-inert` in v1 — a real,
   already-documented limitation, not fixable as a side-effect of this
   sprint.** `academic_gps_service._resolve_regulation_year` (STX-07/
   NEW-04) already computes and TAGS a regulation-year value into
   `RouteGraphVersion.policy_version` (so a version CHANGE is visible in
   the fingerprint), but `program_courses` (the required-course closure
   the GPS reads) has NO link to `ProgramVersion` — every version
   currently shares the identical flat requirement set. A named,
   passing test (`test_regulation_year_tag_is_currently_inert_on_
   output`, from NEW-04's own decisions note) already proves this
   inertness is intentional, documented, and test-covered. **BOOK-20's
   V2 verify text ("plan constraints resolve against the pinned
   edition") must therefore be honestly scoped**: this sprint proves the
   pinned EDITION is cited/visible on every enrollment and every
   downstream scenario/simulation (the contract itself), NOT that
   constraint computation actually differs per edition — that would
   require solving the G7 inertness first, which is explicitly out of
   this sprint's scope (a future sprint's job if/when per-edition
   requirement differentiation is actually needed).
7. **Repo-verified existing state — read before writing any code:**
   - `Program`/`ProgramVersion`/`CourseCatalogItem`
     (`models_institution.py`) are the existing, MUTABLE catalog models —
     `ProgramVersion` even has a live `PATCH`/`DELETE` route
     (`catalog_pi1.py`) with **no immutability enforcement at all**, the
     opposite of `CatalogEdition`'s requirement. Do not retrofit
     immutability onto these existing, actively-used mutable models —
     build `CatalogEdition` as a NEW, separate aggregate that references/
     snapshots them (an edition is a versioned VIEW/snapshot over the
     mutable catalog primitives, not a new set of constraints bolted
     onto the mutable tables themselves) — confirm this exact modeling
     choice in the opus design-review pass (§8 below), since retrofitting
     vs. snapshotting is genuinely a hard-to-reverse call.
   - `RouteGraphVersion` (`models_student_experience.py`, NEW-04) is the
     EXACT, already-working "versioned, immutable-by-convention,
     additive-only, cache-keyed, never mutated" precedent to copy the
     pattern from: `route_graph_compiler.get_or_compile_version()` looks
     up a fresh existing row by a composite key; if none exists, `db.add()`s
     a brand-new row — confirmed by repo-wide grep that ZERO `UPDATE`
     statements exist against this table. `PathScenario.route_graph_
     version_id` is the "every downstream row cites the version it was
     computed against" pattern — `CatalogEdition`-bound scenarios/
     enrollments should cite their edition the same way.
   - `docs/DLU_COURSE_EXCHANGE_LOAD_SAVE_PLAN.md`'s `format_version`
     (a flat export-schema version string) is NOT a meaningful precedent
     for edition/lineage/hash-stamping — it's a file-format
     compatibility tag, unrelated to this sprint's aggregate-versioning
     need.
   - No hash-stamping/document-generation code exists for a legal catalog
     document — this sprint is the first caller (same greenfield
     situation NEW-08 is in for its own document generation; if NEW-08
     has already landed by the time this sprint runs, reuse its
     Jinja2/PDF-rendering choice rather than picking a second one).
8. **Design decision — CatalogEdition as a snapshot aggregate, not a
   retrofit (confirm in the opus design-review pass):** given the
   existing `Program`/`ProgramVersion`/`CourseCatalogItem` models are
   live, mutable, and actively CRUD'd via existing routes, the
   recommended shape is: `CatalogEdition` is a NEW platform-schema
   aggregate that, at "publish" time, SNAPSHOTS the then-current state
   of the relevant catalog rows (course list, credit rules, designations,
   prerequisites, contributions, recognition policies) into its own
   immutable structure (mirroring `RouteGraphVersion`'s own "compiled
   snapshot, never mutated" pattern) — rather than adding immutability
   constraints directly onto `Program`/`ProgramVersion`/
   `CourseCatalogItem`, which would break their existing mutable CRUD
   routes and every caller depending on them. An "erratum" is a NEW
   `CatalogEdition` row (a sub-edition) with a `supersedes_edition_id`/
   lineage pointer, never an UPDATE to a prior edition's snapshot.

## Deliverables
1. **`CatalogEdition` aggregate** (platform schema, GUID PK). Opus
   design-review verdict: APPROVE WITH CHANGES on this exact shape — a
   versioned, immutable-once-effective snapshot (per §8's design
   decision, matching `RouteGraphVersion`'s own proven header-row +
   JSON pattern, not a normalized-child refactor — the explorer browses
   one edition at a time, so wholesale JSON load is fine and premature
   child tables would add migration cost nobody needs yet) —
   `edition_code`, `effective_at`, `program_id` (soft-referenced),
   `snapshot_schema_version` (a versioned tag on the serialization
   format itself, so a future schema change doesn't corrupt old
   editions' hashes), `snapshot` JSON (the frozen course/credit/
   designation/prerequisite/contribution/recognition-policy set at
   publish time — **MUST be a key-sorted, canonical serialization**, not
   arbitrary JSON, since `content_hash` = sha256 over exactly that
   canonical form is what makes V3's byte-identity bar achievable),
   `supersedes_edition_id` (nullable, self-FK, the erratum lineage
   pointer), `content_hash`, `status` (`draft|effective|superseded`).
   Never mutated once `status='effective'` — publishing a correction
   creates a new row. **"Publish time" is pinned to a manual admin
   action for v1** (a `draft`→`effective` transition triggered by an
   explicit registrar/admin act) — term-rollover automation and any
   enrollment-triggered auto-publish are explicitly out of scope this
   sprint, named here so a sonnet-tier implementer doesn't have to
   guess what triggers a snapshot.
2. **Cohort binding**: enrollment (or whatever this codebase's actual
   enrollment record is — check `models_tenant.py`'s `TenantEnrollment`)
   gains a nullable `catalog_edition_id` — a SOFT reference (GUID, no
   cross-schema FK, mirroring `program_id`'s own soft-reference
   treatment above), since `TenantEnrollment` is tenant-schema/
   `BigInteger`-PK while `CatalogEdition` is platform-schema/GUID — pinned
   at enrollment time, never changed after.
3. **Legal catalog document generator**: renders a hash-stamped PDF (or
   the format NEW-08 already established, if it's landed) from a
   `CatalogEdition`'s own snapshot — reproducible: the same edition
   regenerates a byte-identical (or hash-identical) document every time
   (V3).
4. **`simulate_scenarios(hypothetical_fix, target, catalog_edition_id)`**:
   a NEW function (not a modification of `compute_scenarios`) that
   accepts a hypothetical background/goal instead of a real twin, runs
   the existing Pareto/routing engine against a specific `CatalogEdition`
   snapshot, returns scenario-shaped results marked `simulation=true`,
   writes NOTHING to any twin-scoped table, emits NO events, and is
   rate-limited (per-IP or per-session, since pre-auth) — reuse
   `route_graph_compiler.py`'s engine internals directly rather than
   reimplementing routing logic.
5. **Public Catalog Explorer** (frontend, pre-auth route): browses a
   published edition's programs/courses/prerequisite chains/
   designations/contributions/recognition policies; a what-if simulation
   flow (declare background + goal → `simulate_scenarios` → candidate
   paths with hedged/honest assumptions, matching this codebase's
   existing GPS-narration honesty conventions); "save this simulation"
   hands off into the Discovery dialogue (WS00) for an account-holding
   learner; the legal document is downloadable from here.
6. **FW1 authoring extension**: within the EXISTING Design Studio
   workspace (do not build a new FW), add authoring surfaces for
   per-course `DEVELOPS`/`COVERS` knowledge-competency contribution
   declarations and recognition-policy/equivalency declarations — these
   feed the NEXT `CatalogEdition` snapshot at its next publish, they
   never retroactively alter an already-effective edition.
7. **`dlu-catalog` MCP server** (new, `services/dlu_catalog_mcp/` or
   wherever this codebase's convention places it — copy `services/
   dlu_badge_mcp/`'s FastMCP structure): base tools `search_programs`,
   `get_offerings(term)`, `get_regulation_year_rules` (none of which
   exist today, despite being named in BOOK-10A as if planned/imminent —
   build all three for real) PLUS this sprint's own two new tools,
   `get_edition` and `simulate_path` (a thin wrapper over deliverable 4).
8. **`scripts/ci/check_catalog_sole_reader.sh`** (opus design-review
   addition — the concrete guardrail against the one real bug class this
   snapshot design admits: downstream code silently reading the LIVE
   mutable `Program`/`ProgramVersion`/`CourseCatalogItem` tables instead
   of a pinned edition's frozen `snapshot`). Mirrors the existing
   `check_evidence_sole_writer.sh` pattern (grep + allowlist) but
   inverted — a "sole-reader" gate: only the publish/snapshot-builder
   code path may import those three live models; any simulate/document-
   generation/explorer-path file that imports them fails CI. This is
   cheap (a grep script, same shape as three already-existing CI gates
   in this repo) and closes a real correctness gap a purely additive
   snapshot table cannot close by itself.

## Verifications
- **V1** effective-edition immutability: an attempted mutation of an
  `effective` `CatalogEdition` row fails (a service-layer guard, and/or a
  DB-level check — pick one, document which); an "erratum" correctly
  creates a NEW sub-edition row with `supersedes_edition_id` pointing at
  the original, never an UPDATE.
- **V2** enrollment pins its edition (a fixture enrollment's
  `catalog_edition_id` never changes after creation) and — honestly
  scoped per §6 — the pinned edition reference IS resolvable/visible on
  every downstream scenario/simulation citing it (NOT that requirement
  computation differs per edition, which G7's documented inertness makes
  out of reach this sprint).
- **V3** the generated legal document is reproducible from the edition's
  own `content_hash`/snapshot — regenerating from the same
  `CatalogEdition` row twice produces the same hash.
- **V4** an anonymous (pre-auth) simulation runs end-to-end and a
  post-test query confirms ZERO rows were written to any twin-scoped
  table and zero events were emitted for that session.
- **V5** simulation output is marked (`simulation=true` on every
  returned scenario) and a test confirms it is excluded from any
  events/advisor-queue path — a simulated scenario must never reach
  `move_proposal_service` or any twin's real recommendation slate.
- **V6** (this pack's own addition) `dlu-catalog` MCP server responds to
  all five tools against fixture data · `pytest -m phase1` stable ·
  migrations up/down/up clean on an isolated Postgres.
- **V7** (opus design-review addition) `check_catalog_sole_reader.sh`
  fails CI if any file outside the publish/snapshot-builder allowlist
  imports live `ProgramVersion`/`CourseCatalogItem` from a pinned-
  edition, simulate, or document-generation code path — a fixture
  violation (a deliberately-planted bad import) proves the gate
  actually catches the bug class, not just that the script runs.

## DoD
V1–V7 green · BOOK-04 §C3 (CatalogEdition row) marked implemented ·
BOOK-16 §6.4a and Annex A updated · BOOK-14 Ch. 9 (`simulate_scenarios`)
marked implemented, with the G7-inertness honesty note carried forward
explicitly (not silently resolved) · BOOK-17 Ch. 3/4 (explorer, FW1
extension) marked implemented · BOOK-10A `dlu-catalog` row updated from
🔵 to ✅ with the actual five tools listed · TRACEABILITY G15 row updated
(G7 row's own "version-inert" caveat referenced, not re-litigated) ·
decisions note recording: the snapshot-vs-retrofit modeling choice (§8),
the canonical-serialization/`snapshot_schema_version` choice and why it
matters for V3's hash-reproducibility bar, the "publish = manual admin
action" decision (and what's explicitly deferred: term-rollover
automation, enrollment-triggered publish), the `check_catalog_sole_
reader.sh` gate's allowlist, the rate-limiting mechanism chosen for
pre-auth simulation, and the explicit, carried-forward statement that
per-edition constraint DIFFERENTIATION (as opposed to citation/
visibility) remains future work pending a G7 de-inerting sprint.
