# RFC-0007 — A1 Staging-Table Reads: EKG v1.1 Reality vs. the BOOK-13 Sunset Plan

Status: **Proposed** · Author: architecture review, 2026-09-08
Owner Books: **04** (Academic Domain Model, Ch. 9 anomaly A1 / Ch. 10 Rule 7) · **13** (Academic Knowledge Network, Ch. 10 A1 Sunset Plan)
Affected registers: A1 sunset plan phase S1; `scripts/ci/check_kg_staging_reads.{sh,py}` allowlist (`dlu_builder_tk`)
Supersedes: nothing · Superseded by: nothing · Companion: ADR-0022 (Postgres interim source of truth), ADR-0024 (`CanonicalConcept` is the identity authority)

> **Verdict up front.** The A1 sunset plan's S1 phase assumed "zero product-feature
> reads" of the PG `KnowledgeGraph`/`KnowledgeGraphNode`/`KnowledgeGraphEdge` staging
> tables was already true and CI-enforced. It was neither: the enforcement script
> (`check_kg_staging_reads.sh`) has been broken since it shipped — a plain-text `grep`
> that matched inside docstrings/comments, reporting up to 30 "violations" when only
> ~12 files ever actually imported the staging models. That noise made the gate
> useless for its one job. Fixed to an AST-based check (this RFC's companion change,
> already merged in `dlu_builder_tk`), it now accurately reports **10 real readers**.
> None of the 10 look careless — every one has a specific, documented reason. Three
> independently complained about the exact cross-course identity gap ADR-0024 already
> solved five weeks ago; **one of the three (`ekg_lens_service.py`) has now been
> migrated and re-verified (2026-09-08, 20/20 tests passing)** — the other two turned
> out, on closer implementation reading, to have a real blocking dependency ADR-0024
> doesn't cover yet (see §2 Category B) and are reclassified there rather than
> migrated. This RFC proposes: track the 2 remaining Category B gaps as BOOK-13
> backlog, close the 1 remaining Category D leak, and recognize the 3 Category C
> files as already-correct bridge/transition code the allowlist should say so about
> explicitly, not silently re-flag forever.

---

## 1. Context

BOOK-04 Ch. 9 declares anomaly A1 ("dual knowledge-graph storage"): Neo4j is
authoritative for traversal/semantics, the PG `knowledge_graphs`/
`knowledge_graph_nodes`/`knowledge_graph_edges` tables are extraction-staging
build artifacts, and Ch. 10 Rule 7 says the anomaly "MUST NOT grow: no new
writers/readers on deprecated populations." BOOK-13 Ch. 10's S1 phase operationalizes
this: *"staging demoted to extraction-only; no new readers — enforced at review."*
Exit criterion: *"zero product-feature reads (grep-audit clean)."* BOOK-13's own
Annex A lists this gate as **"delivered STX-05"** (2026-07-16).

Investigating an unrelated CI failure (2026-09-08, `dlu_builder_tk`) found the gate
had never actually verified that exit criterion. `check_kg_staging_reads.sh` used
`grep -rlnE 'KnowledgeGraphNode|KnowledgeGraphEdge|KnowledgeGraph\b' backend
--include="*.py"`, which matches inside Python comments and docstrings exactly as
readily as inside a real `from ... import` statement. A live run against the current
`backend/` tree returned **30 files**. Manual, file-by-file inspection found:

- **~13 were pure prose** — docstrings explaining the sunset plan, or referencing the
  legacy classes by name while describing a *different*, newer system. Zero code
  reference.
- **4 were test files** (`backend/tests/test_civ_03_04_*.py`,
  `test_ccv2_03_lesson_concept_tagging.py`, `test_ccv2_06_course_factory_ekg_
  producers.py`, `test_ccv2_07_backfill_canonical_concepts.py`) — real imports, but the
  gate's own header comment already promised a "tests" allowlist category that the
  actual `ALLOWLIST` array never implemented.
- **2 were sunset/migration tooling** (`ekg_legacy_kg_drift_report.py`,
  `ccv2_backfill_canonical_concepts.py`) — scripts whose entire purpose is comparing
  or migrating the old tables, the same "promotion pipeline" category the allowlist
  already carves out for `kg_build_service`/`kg_nlp_extractor`.
- **10 were real, current imports of the staging classes from live product/worker/
  script code.** These are this RFC's actual subject.

The gate has been rewritten as an AST-based check (`scripts/ci/check_kg_staging_
reads.py`, only matches a real `ImportFrom` naming one of the three staging classes)
with the test-directory and 2-script allowlist additions above already applied —
that part is mechanical and not in question here. What remains is a real decision
about the 10 genuine readers, which is what BOOK-13's own text asks for: *"If this
is the promotion pipeline, amend BOOK-13 Ch. 10 first (RFC)."*

Critically, **BOOK-04/BOOK-13's own text (addenda dated 2026-08-08/09) predates
ADR-0024** (accepted 2026-08-13, "`CanonicalConcept` is the identity authority for
the EKG `Concept` node type, replacing course-scoped `KnowledgeGraphNode` going
forward"). Re-reading the 10 files against ADR-0024 — not just against the masterbook
text — changes the picture substantially: several of them are not disputing the
sunset plan at all, they're citing a real gap ADR-0024 already closed.

---

## 2. The 10 files, re-triaged against ADR-0024

### Category A — migrated: the fix it was asking for already existed

**`backend/services/ekg_lens_service.py`** (`build_program_concept_coverage`) said,
in its own docstring: *"each course's own `KnowledgeGraph` carries its OWN
locally-scoped `KnowledgeGraphNode` integer ids — there is no shared concept id
across two different courses' graphs anywhere in this codebase."* — the exact
sentence ADR-0024 was written to make false. This function has no downstream
dependency on the legacy identity (it doesn't join to any table keyed by
`KnowledgeGraphNode.id`), so it migrated cleanly onto `CanonicalConcept`/
`ConceptOccurrence`: "overlap" is now real shared canonical identity, not
case/whitespace-normalized label-text matching. **Done 2026-09-08** — its 5 existing
tests (`tests/conformance/test_ekg_w6_07_dean_console.py::TestProgramConceptCoverage`)
were rewritten to build real `ConceptOccurrence`/`CanonicalConcept` fixtures instead
of `KnowledgeGraphNode` ones (the old fixture needed a real `Course`/`User` row for
`KnowledgeGraph`'s FK; `ConceptOccurrence.course_id` has none, so the new fixture is
simpler, not just different) — 20/20 tests in that file pass, and the file no longer
appears in `check_kg_staging_reads.py`'s output.

### Category B — real gaps in the *new* system, not oversight

Two files originally proposed for Category A turned out, on closer implementation
reading, to have a real blocking dependency ADR-0024 doesn't cover — both are
reclassified here, alongside the two already identified this way:

- **`backend/services/ekg_student_model_service.py`** (`build_course_knowledge_
  overview`, EKG-W3-12) and **`backend/services/ekg_faculty_lens_service.py`**
  (`build_cohort_concept_mastery`, EKG-W3-13, which explicitly cites the file above
  as its shared precedent) both join their concept list to `LearningState` for
  mastery/confidence. Tracing `LearningState.target_id` for `target_type="concept"`
  to its one real writer (`ekg_mastery_service.py::recompute_sync`) and its one real
  caller passing that target type (`seed_ekg_demo.py`, `target_id = str(KnowledgeGraphNode.id)`
  via a label→node lookup) confirms mastery data for concepts is genuinely keyed by
  `KnowledgeGraphNode.id` today, not `CanonicalConcept.id`. Swapping either
  function's concept *source* to `ConceptOccurrence` without also re-keying
  `LearningState` would silently return `mastery: None`/`average_mastery: None` for
  every concept — a real regression disclosed here rather than shipped. These two
  need `LearningState` re-keyed onto `CanonicalConcept.id` (or an explicit
  `KnowledgeGraphNode.id → CanonicalConcept.id` mapping surfaced somewhere
  queryable) before they can migrate — materially bigger than the label-text-only
  swap `ekg_lens_service.py` needed, and gated on Category D's fix below (today,
  `seed_ekg_demo.py` is the *only* real producer of concept-mastery data, and it
  would need to write the new key too).
- **`backend/services/ekg_propagation_service.py`** needs the raw per-edge
  **weight** on a `PREREQUISITE_OF` relationship to compute its mastery-propagation
  formula (`R(target) = Π_i (epsilon + (1-epsilon)·M_i)^(w_i / Σw)`) — its own
  docstring calls `KnowledgeGraphEdge` *"the ONLY level a hard-prerequisite cap is
  structurally possible at all in this codebase."* Confirmed live: ADR-0024's
  `ConceptPrerequisite` (`backend/database/models_canonical_concepts.py`) has no
  weight column today — `scope`, `status`, `from_canonical_id`, `to_canonical_id`
  only. This file cannot migrate until that column exists.
- **`backend/services/ekg_graphrag_service.py`** documents, in its own module
  docstring, *why* it doesn't call `kg_query_service.get_graphrag_context`: that
  facade method *"runs against the legacy KG and filters by `course_id` only, never
  `tenantId` (a real tenant-isolation gap disclosed during this sprint's own
  investigation)"*, plus Neo4j projection is event-driven/async, so a
  just-created concept has no graph counterpart yet at read time. Both are real,
  already-disclosed gaps in the sanctioned facade, not a reason to keep reading
  staging tables forever.

**`backend/services/ekg_tutor_orchestrator_service.py`**'s one direct read
(`select(KnowledgeGraphNode.id, KnowledgeGraphNode.label).where(...id.in_(...))`,
a batch label lookup for ids it receives from elsewhere) is downstream of whatever
`ekg_propagation_service` resolves to — it moves when that does, and/or needs a
small batch-lookup addition to `kg_query_service`.

**Proposal:** track as real BOOK-13 backlog, not an exception to wave through:
(1) re-key `LearningState`'s concept identity onto `CanonicalConcept.id` (the
larger item — affects `ekg_student_model_service.py`, `ekg_faculty_lens_service.py`,
and `seed_ekg_demo.py`'s writer together, not independently); (2) add a `weight`
column to `ConceptPrerequisite`; (3) add tenant scoping to `kg_query_service.
get_graphrag_context` (or a new tenant-safe variant); (4) decide whether GraphRAG
can tolerate Neo4j's async projection lag or needs a documented staleness contract.

### Category C — already correct, not a violation in spirit

- **`backend/services/lesson_concept_tagging_service.py`** writes fresh
  `KnowledgeGraphNode`/`KnowledgeGraphEdge` rows via the existing
  `KnowledgeGraphService.add_knowledge_graph_node` — this is BOOK-13 Ch. 4's own
  sanctioned source **"③ NLP extraction → PG staging."** It is a *writer* using the
  canonical write path for that source, not a feature reading deprecated data.
- **`backend/workers/course_factory_worker.py`** reads a `KnowledgeGraphNode` by id
  (the row the file above just wrote) specifically to call `canonical_concept_
  service.find_or_create_concept_by_uri`/`register_occurrence` on it — this *is* the
  promotion-door bridge ADR-0024 itself describes, already correctly implemented.
- **`backend/services/ekg_vector_ingestion_service.py`** deliberately embeds *both*
  populations (a `KnowledgeGraphNode`-keyed function and a separate
  `CanonicalConcept`-keyed function, side by side) — exactly ADR-0024's own stated
  transition consequence: *"two parallel concept representations now coexist... until
  the CCV2-07 backfill... fully closes the gap."*

**Proposal:** allowlist these three explicitly, with the reasoning above inline —
not as "SUNSET DEBT (frozen)" (that framing implies dead code awaiting deletion) but
as a new, named category: **"A1 promotion-door / transition bridge — expected to
shrink automatically as the CCV2-07 backfill and Category B migrations land, not
frozen."**

### Category D — known, disclosed, still-open leak

- **`backend/scripts/seed_ekg_demo.py`** is already named in ADR-0024 itself as a
  confirmed source of un-migrated `KnowledgeGraphNode` rows. Unlike the backfill's
  one-time historical debt, this script *keeps creating new instances of the same
  gap* every time it's re-run (it is not covered by the CCV2-07 backfill, which
  fixes existing rows, not future ones). It should either call
  `canonical_concept_service.find_or_create_concept_by_uri` directly instead of
  constructing `KnowledgeGraphNode` itself, or be explicitly re-confirmed as
  intentionally out of scope (it is demo-recording tooling, not product code) and
  allowlisted alongside migrations/tests.

---

## 3. Decision (proposed)

1. **BOOK-13 Ch. 10 gains a dated addendum** (text below) recording that S1's
   "zero reads" exit criterion was never actually verified due to the broken gate,
   that it is now accurately measured, and disposing of each real reader per the
   categories above.
2. **`check_kg_staging_reads.py`'s `ALLOWLIST`** gains the 3 Category C files under
   the new "transition bridge" comment, distinct from the existing frozen "SUNSET
   DEBT (v1.0)" pair.
3. **Category A migration is done** (`ekg_lens_service.py`, 2026-09-08, 20/20 tests
   passing) — no further action.
4. **Category B gaps (4 files; 3 underlying pieces of work: `LearningState`
   re-keying, `ConceptPrerequisite.weight`, tenant-scoped GraphRAG facade)** are
   added to BOOK-13's own backlog (Annex A / Ch. 10 S2 tracking), not silently
   absorbed into the allowlist as if permanent. The `LearningState` re-keying is the
   largest of the three — it touches the mastery engine's own identity convention,
   not just a display query, and should be scoped as its own task rather than bundled
   with the other two.
5. **Category D (`seed_ekg_demo.py`)** gets a follow-up task to call
   `canonical_concept_service` directly, closing the one remaining *ongoing* leak
   (as opposed to Category A/C's one-time historical debt) — and is a prerequisite
   for the `LearningState` re-keying above, since it is currently the only real
   writer of concept-mastery data.
6. Anomaly A1 is **not** re-opened as "growing indefinitely" — every one of the 10
   files has a specific, time-bound disposition above; none is a blanket, unscoped
   exception.

### Proposed BOOK-13 Ch. 10 addendum text

> **Addendum — A1 gate accuracy correction and disposition (2026-09-08).** The S1
> exit criterion ("zero product-feature reads, grep-audit clean") was never actually
> verified: the enforcement script matched inside comments/docstrings, making a real
> signal indistinguishable from ~18 false positives. Rewritten as an AST-based check
> (`check_kg_staging_reads.py`) — see RFC-0007 for the full re-triage. Of 10 confirmed
> real readers: 1 (`ekg_lens_service.py`) has migrated onto the already-accepted
> `CanonicalConcept` identity layer (ADR-0024) and is no longer a staging reader; 3
> are correct promotion-door/transition-bridge code, allowlisted under that name,
> expected to shrink as the CCV2-07 backfill and further migrations land; 4 name real,
> specific gaps in the `CanonicalConcept`/`kg_query_service` surface (`LearningState`'s
> concept identity is still `KnowledgeGraphNode.id`-keyed, blocking 2 of the 4;
> prerequisite edge weight; tenant-scoped GraphRAG), tracked as S2 backlog, not
> exceptions; 1 (`seed_ekg_demo.py`) is a known, still-open leak (ADR-0024 already
> named it) that should stop creating new un-migrated rows — and is itself a
> prerequisite for closing the `LearningState` gap, since it is currently the only
> real writer of concept-mastery data.

---

## 4. Alternatives considered

1. **Leave the gate grep-based, add all 10 to the allowlist wholesale.** Rejected —
   this is exactly the "silent, unscoped growth" Ch. 10 Rule 7 forbids, and would
   have buried the 1 real, cheap migration (Category A, since done) and the 4 real
   remaining product gaps (Category B) as if they were permanent, instead of
   tracking them.
2. **Treat all 10 as violations to fix immediately, uniformly.** Rejected — at least
   3 (Category C) are already-correct bridge code; forcing them to stop importing
   the staging classes would mean breaking the promotion pipeline itself, not fixing
   a bug. Two more (Category B's `ekg_student_model_service.py`/`ekg_faculty_lens_
   service.py`) looked migratable at a glance but aren't yet, without risking a real
   regression (silently blanking the mastery overlay) — this was caught by reading
   the actual `LearningState` write path before changing code, not assumed from the
   RFC's own first-pass categorization.
3. **Do nothing until a full Neo4j-native replacement exists for every one of these
   use cases.** Rejected — `ekg_lens_service.py`'s fix already existed and was cheap
   (confirmed by actually doing it); deferring it alongside the genuinely harder
   Category B items would have conflated a one-file query swap with real facade/
   mastery-engine engineering work.

## 5. Open questions

- Scoping the `LearningState` re-keying: does it need a one-time backfill mapping
  existing `KnowledgeGraphNode.id`-keyed rows to a resolved `CanonicalConcept.id`
  (mirroring CCV2-07's own concept backfill), or can it start clean given the only
  current writer is demo-seed data with no real user history to preserve?
- Should `ConceptPrerequisite.weight` default to the same value
  `KnowledgeGraphEdge.weight` currently uses for un-weighted edges, or does this need
  a real re-derivation pass once `ekg_propagation_service` migrates?
- Does `kg_query_service.get_graphrag_context`'s tenant-isolation gap have any other
  callers today that are silently exposed to the same cross-tenant leak
  `ekg_graphrag_service.py` deliberately routed around? (Worth a dedicated grep pass,
  out of scope for this RFC.)
- Who owns scheduling the Category B/D work — same team that owns
  `canonical_concept_service.py`/`ekg_mastery_service.py` (CCV2/EKG-W2 tracks), or
  whoever picks up BOOK-13 S2 next?
