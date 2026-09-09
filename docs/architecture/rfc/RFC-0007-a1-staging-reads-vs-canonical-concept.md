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
> migrated. **Update (2026-09-08/09): the largest Category B item — `LearningState`
> re-keying plus the `ConceptPrerequisite.weight` column its own propagation formula
> needs — is now done**, across `ekg_propagation_service.py` and its three real
> callers (`ekg_student_workspace_service.py`, `ekg_learning_path_service.py`,
> `ekg_tutor_orchestrator_service.py`), `seed_ekg_demo.py` (dual-writing both identity
> conventions — see §2 Category D), a new migration, and 3 conformance suites
> rewritten onto `CanonicalConcept`/`ConceptOccurrence`/`ConceptPrerequisite`
> fixtures — all re-verified against real Postgres. Two files originally scoped
> into that same item, `ekg_student_model_service.py`/`ekg_faculty_lens_service.py`,
> stayed deferred at that point, for a **sharper, independently-discovered reason**:
> their concept *list* query had its own live-route regression risk unrelated to
> mastery-keying — a live, mounted manual "add a concept node" route created rows
> with no matching `ConceptOccurrence`. **Update (2026-09-09): that route is now
> fixed** (dual-writes a `ConceptOccurrence` too, mirroring `course_factory_
> worker.py`'s own pattern), which closes the last blocker — **both deferred
> functions are now migrated too**, re-verified end-to-end against real Postgres
> (a node added through the fixed route is immediately visible, with real mastery,
> in both the student and faculty views) plus 2 rewritten conformance suites.
> **Update (2026-09-09): the GraphRAG item is also done — and turned into a real
> security fix, not just an architecture cleanup.** `ekg_graphrag_service.py` itself
> needed no change (its own tenant-safe path already avoids the legacy facade — see
> §2 Category B's entry below for why). But tracing the facade's *other* real
> callers (the RFC's own open question) found `kg_query_service.py`'s `course_id`-
> only Cypher queries (8 methods, not just `get_graphrag_context`) had **zero
> tenant scoping at all**, and were reachable via 3 live, mounted routes (`rag.py`,
> `curriculum_map.py`, `knowledge_graph.py`) with no course-ownership check of their
> own — a confirmed, live, exploitable cross-tenant data leak, not a theoretical
> gap. Fixed: `tenant_id` is now a required argument on every `course_id`-scoped
> `KGQueryService` method, matched in Neo4j against the same property the real
> writers already set; the 3 live routes gained real ownership/tenant checks; a 4th
> file (`knowledge_graph_pi1.py`, confirmed NEVER mounted in `main.py` — dead code)
> got the same fix for consistency. Live-verified against real Neo4j: a wrong-
> tenant query now returns zero nodes where it previously returned the real data.
> Of the original 10 real readers, every one is now resolved. This RFC proposes:
> retire `seed_ekg_demo.py`'s dual-write once its own historical-data caveat is
> confirmed clear (§2 Category D), and recognize the 3 Category C files as
> already-correct bridge/transition code the allowlist should say so about
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
reading, to have a real blocking dependency ADR-0024 doesn't cover — both were
reclassified here, alongside the two already identified this way. **Update
(2026-09-08/09): all of Category B is now done except GraphRAG tenant-scoping** —
`LearningState` re-keying + `ConceptPrerequisite.weight` landed first (2026-09-08),
then the manual-node-route gap that had newly deferred the last 2 files was closed
and both migrated for real (2026-09-09) — see their own entries below.

- **DONE — `ekg_propagation_service.py`'s prerequisite-weight formula.** A new
  migration (`20261202_0900_concept_prerequisite_weight.py`) adds `ConceptPrerequisite.
  weight` (`Float`, nullable, no default — mirrors `KnowledgeGraphEdge.weight`'s own
  `default=1.0` via the same `weight or 1.0` fallback already used at read time, now
  reused unchanged). `resolve_concept_prerequisites_sync`/`resolve_concept_dependents_
  sync`/`propagate_concept_sync` were rewritten to query `ConceptPrerequisite`
  directly (global, canonical-concept-keyed — no `course_id` parameter anymore,
  since a `PREREQUISITE_OF` edge between two canonical concepts isn't course-scoped
  the way a `KnowledgeGraphEdge` was); `resolve_course_id_for_concept_node` (single-
  course lookup) was replaced by `resolve_occurrence_course_ids_sync` (a canonical
  concept can have many `ConceptOccurrence` rows, so "the" owning course no longer
  exists as a concept).
- **DONE — `LearningState` re-keying, for the 3 real propagation consumers.**
  Tracing `LearningState.target_id` for `target_type="concept"` confirmed (as
  originally found) that `seed_ekg_demo.py` was the only real writer, keyed by
  `str(KnowledgeGraphNode.id)`. Rather than a hard cutover, `seed_ekg_demo.py` now
  **dual-writes**: one `LearningState` row per concept under the old
  `KnowledgeGraphNode.id` convention (kept for the 2 still-deferred functions below)
  and one under the new `CanonicalConcept.id` convention (for everything already
  migrated) — the same fact under two identity schemes during the transition, not
  two different facts. `ekg_student_workspace_service.py::_load_weak_prerequisites`,
  `ekg_learning_path_service.py::build_learning_path_sync`, and `ekg_tutor_
  orchestrator_service.py::build_learning_diagnosis_view` were all rewritten to
  filter `LearningState.target_id` on UUID-shape (a `CanonicalConcept.id`) instead of
  digit-shape (a `KnowledgeGraphNode.id`), call the new propagation-service
  signatures, and (the tutor orchestrator) resolve prerequisite-blocker labels via
  `CanonicalConcept.pref_label` instead of `KnowledgeGraphNode.label`. `Misconception`/
  `LearningGoal`/`LearningIntervention`/`TutorTurn.grounding_refs` moved to the new
  convention only (confirmed, by direct inspection, that neither deferred function
  reads any of them — no dual-write needed there). Re-verified end-to-end against
  real Postgres (a canonical-concept prerequisite chain correctly caps mastery
  through the full workspace/learning-path/tutor-diagnosis stack) and via 3 rewritten
  conformance suites (`test_ekg_w2_04_hierarchical_propagation.py`, `test_ekg_w2_06_
  learning_path.py`, `test_ekg_w3_11_tutor_student_surface.py` — all passing).
- **DONE (2026-09-09) — `backend/services/ekg_student_model_service.py`**
  (`build_course_knowledge_overview`, EKG-W3-12) and **`backend/services/ekg_
  faculty_lens_service.py`** (`build_cohort_concept_mastery`, EKG-W3-13). The
  `LearningState`-keying blocker that originally deferred them was resolved by the
  dual-write above — but implementing that migration surfaced a SEPARATE,
  independent blocker: both functions sourced their concept *list* from
  `KnowledgeGraph`/`KnowledgeGraphNode`, not just the mastery join. Tracing every
  real writer of `KnowledgeGraphNode` found `lesson_concept_tagging_service.py`
  (Category C, live) is called exclusively from `course_factory_worker.py`, which
  *does* dual-write a matching `ConceptOccurrence` for every tagged lesson — so
  Course-Factory-generated courses were always safe. But `backend/api/routes/
  knowledge_graph.py`'s `POST /{course_id}/nodes` route (live, mounted) let a user
  manually add a `KnowledgeGraphNode` with no corresponding `ConceptOccurrence` —
  the exact gap `ccv2_backfill_canonical_concepts.py`'s own docstring already named
  as its backfill target. Migrating these 2 functions' concept-list source to
  `ConceptOccurrence` before fixing that would have silently dropped any course's
  manually-added concepts from the Knowledge Explorer / cohort mastery view — a real
  regression, caught before writing code (not shipped).
  **Fix (2026-09-09):** `KnowledgeGraphService.add_knowledge_graph_node` (the manual
  route's own service method) now dual-writes a `CanonicalConcept`/`ConceptOccurrence`
  for every concept-typed node it creates, in the SAME transaction, mirroring
  `course_factory_worker.py`'s own pattern — closing the gap going forward for both
  live writers, not just one. Checked the dev database for pre-existing
  `KnowledgeGraphNode` rows with no matching occurrence (the historical-debt case
  `ccv2_backfill_canonical_concepts.py --apply` exists for): zero rows found in this
  environment, so no backfill was needed here — **a real deployment DOES need to run
  that backfill once before/alongside this fix**, to catch any pre-existing manually-
  added concepts in an environment with real history (see Open Questions). With the
  write-path gap closed, both functions were migrated onto `ConceptOccurrence`/
  `CanonicalConcept` for their concept list (mirroring `ekg_lens_service.py`'s own
  Category A shape, with `.distinct()` added since a concept can now have multiple
  `ConceptOccurrence` rows per course — one per lesson — where a `KnowledgeGraphNode`
  never could). Re-verified against real Postgres: a concept added through the fixed
  route is immediately visible, with real overlaid mastery, in both `build_course_
  knowledge_overview` and `build_cohort_concept_mastery`; plus 2 rewritten
  conformance suites (`test_ekg_w3_12_knowledge_explorer.py`, `test_ekg_w3_13_
  faculty_outcome_health.py`).
- **DONE (2026-09-09) — `backend/services/ekg_graphrag_service.py`** documents, in
  its own module docstring, *why* it doesn't call `kg_query_service.get_graphrag_
  context`: that facade method *"runs against the legacy KG and filters by
  `course_id` only, never `tenantId` (a real tenant-isolation gap disclosed during
  this sprint's own investigation)"*. Confirmed this file itself needed no change —
  its own `entity_link`/`bounded_subgraph` already avoid the legacy facade via a
  tenant-safe path (`named_query_templates.bounded_neighborhood` against Neo4j,
  keyed by `KnowledgeGraphNode.id` — the ONLY identity scheme Neo4j's `Concept`
  nodes actually have projected today; confirmed `CanonicalConcept`/
  `ConceptOccurrence` creation events are emitted but have ZERO Neo4j-projection
  consumers, so migrating this file's own identity scheme would silently zero out
  every graph fact — a landmine caught before writing code, matching this RFC's
  own recurring pattern). Neo4j's async-projection lag is already handled: `bounded_
  subgraph` degrades to "no facts" + a logged warning per-entity, not a raised
  error, matching every prior Wave sprint's own "partially-real chain" disclosure —
  no separate staleness contract needed beyond what's already there.

  **What DID need fixing — the RFC's own flagged open question, now answered**:
  tracing `kg_query_service.get_graphrag_context`'s OTHER real callers found a
  confirmed, live, exploitable cross-tenant data leak, not just the one flagged
  method. All 8 `course_id`-scoped `KGQueryService` methods (`get_full_graph`,
  `get_concepts`, `get_concept_detail`, `find_path`, `get_graph_stats`, `get_
  visualize_data`, `get_graph_context_for_rag`, `get_graphrag_context`) filtered
  Neo4j `:Course`/`:Concept` nodes by `course_id` alone — a plain, globally
  auto-incrementing Postgres integer with no tenant namespacing — with NO
  `tenant_id` check at all, even though the underlying nodes already carry that
  property (set by the real writers, `graph_sync_service_pi1.py`/`kg_build_
  service.py`/`kg_overlay_sync.py`). Three LIVE, mounted routes called into this
  with no course-ownership check of their own: `rag.py`'s `query_rag`/`get_
  multilingual_context` (`request.course_id` from the request body, unchecked),
  `curriculum_map.py`'s `get_curriculum_map` (`tenant_id` from the URL path,
  unchecked against the caller's own tenant), and `knowledge_graph.py`'s `GET
  /{course_id}` (no auth dependency at all). A 4th file, `knowledge_graph_pi1.py`
  (7 more routes, same gap, several with hand-rolled raw Cypher), turned out to be
  dead code — confirmed never mounted in `backend/api/main.py` — fixed anyway for
  consistency, since it duplicates `knowledge_graph.py`'s live endpoint shapes under
  the same URL prefix.

  **Fix**: `tenant_id` is now a required argument on every one of the 8 methods,
  matched directly in each Cypher query's `Course`/`Concept` node pattern; the 3
  live routes gained real ownership/tenant checks before ever reaching Neo4j; all
  8 call sites across 5 other files (`ekg_legacy_kg_drift_report.py`, `diagnostic_
  service.py`, `program_kg_map_service.py`, `kg_export_service.py`, `rag_service.py`)
  updated to pass it through from an already-available, already-trusted tenant_id
  (never client-supplied). Live-verified against real Neo4j (not mocked): querying
  a real seeded course with the correct tenant_id returns real data; the identical
  query with a different tenant_id returns zero nodes — the actual vulnerability,
  now closed; calling any method without `tenant_id` now raises `TypeError` rather
  than silently defaulting to unscoped. Full existing test suite (126 tests across
  11 files, unit + live-Neo4j integration) re-verified passing, including through
  the real HTTP routes via ASGI transport.

**Proposal:** everything in this category is now done. Remaining BOOK-13 backlog:
run `ccv2_backfill_canonical_concepts.py --apply` once against any real deployment
with pre-existing manually-added `KnowledgeGraphNode` rows (none found in this dev
environment, so not exercised here), to close the historical half of the manual-
node-route gap the earlier fix only closed going forward; and, once that's
confirmed done everywhere real data exists, re-check whether `seed_ekg_demo.py`'s
`KnowledgeGraph`/`KnowledgeGraphNode`/old-convention `LearningState` writes can
retire — NOT a given: `project_to_neo4j` feeds the SAME `node_by_label` ids into
Neo4j, which the Knowledge Explorer's drill-down graph view (`/api/ekg-lens/xro/
local-graph`, per `test_ekg_w3_12_knowledge_explorer.py`'s own docstring) reads —
removing the old write path without checking that consumer first would be exactly
the kind of unverified cutover this RFC has repeatedly already caught and reversed
course on before shipping.

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

### Category D — known, disclosed leak, now a deliberate dual-write bridge

- **`backend/scripts/seed_ekg_demo.py`** is already named in ADR-0024 itself as a
  confirmed source of un-migrated `KnowledgeGraphNode` rows. **Update (2026-09-08):**
  rather than a full cutover, the script now writes CanonicalConcept/ConceptOccurrence/
  ConceptPrerequisite rows via a new `seed_canonical_concepts` function (idempotent,
  re-verified) ALONGSIDE its original `KnowledgeGraph`/`KnowledgeGraphNode`/
  `KnowledgeGraphEdge` writes — a deliberate transition bridge, not a fix left half
  done: the old convention is still needed by the 2 still-deferred Category B
  functions above, so removing it now would break them. `LearningState` is
  dual-written under both identity conventions for the same reason; `Misconception`/
  `LearningGoal`/`LearningIntervention`/`TutorTurn.grounding_refs` moved to the new
  convention only (nothing deferred reads them). Still an open leak in the narrow
  sense that it keeps creating fresh `KnowledgeGraphNode` rows on every re-run — but
  that half is now paired with an equally fresh `CanonicalConcept`/`ConceptOccurrence`
  row every time, closing ADR-0024's actual concern (silent, unresolved drift).
  **Update (2026-09-09):** the manual-node-route gap that gated fully retiring the
  old half is now closed — but retiring is still not a given (see §3 item 4): the
  old `KnowledgeGraphNode` ids this script creates also feed the Neo4j projection
  the Knowledge Explorer's drill-down graph view reads, an independent consumer
  not yet checked.

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
4. **Category B is fully done.** `LearningState` re-keying + `ConceptPrerequisite.
   weight` (2026-09-08), then the manual-node-route gap that had newly deferred
   `ekg_student_model_service.py`/`ekg_faculty_lens_service.py` (2026-09-09) — both
   now migrated, re-verified against real Postgres. The GraphRAG item (2026-09-09)
   needed no change to `ekg_graphrag_service.py` itself, but surfaced and closed a
   real, live, cross-tenant data-leak vulnerability in `kg_query_service.py` and 3
   routes that called it with no tenant scoping — see §2's own entry for the full
   account. No BOOK-13 backlog remains for this category.
5. **Category D (`seed_ekg_demo.py`)** dual-writes both identity conventions
   (2026-09-08) rather than calling `canonical_concept_service` exclusively. With
   the manual-node-route gap now closed (2026-09-09), nothing in this codebase reads
   the old convention's `LearningState` rows by key anymore — but the old
   `KnowledgeGraph`/`KnowledgeGraphNode` writes themselves aren't necessarily
   retireable yet (they also feed a Neo4j drill-down consumer, unchecked) — tracked
   as its own follow-up, not assumed safe.
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
> specific gaps in the `CanonicalConcept`/`kg_query_service` surface, tracked as S2
> backlog, not exceptions; 1 (`seed_ekg_demo.py`) is a known leak (ADR-0024 already
> named it) that keeps creating new un-migrated rows on every re-run.
>
> **Addendum 2 — `LearningState` re-keying and `ConceptPrerequisite.weight` land
> (2026-09-08/09).** Of the 4 Category B gaps above, 2 underlying pieces of work are
> now done: `ekg_propagation_service.py` (and its 3 real callers — the student
> workspace projection, the learning path service, the tutor orchestrator) reads
> `ConceptPrerequisite`/its new `weight` column instead of `KnowledgeGraphEdge`, keyed
> by `CanonicalConcept.id` instead of `KnowledgeGraphNode.id`; `seed_ekg_demo.py`
> (the leak named above) now dual-writes both identity conventions rather than only
> the old one, closing the silent-drift concern even though the old convention isn't
> retired yet. Re-verified against real Postgres, including 3 rewritten conformance
> suites. The remaining 2 files originally expected to migrate alongside this
> (`ekg_student_model_service.py`/`ekg_faculty_lens_service.py`) stay deferred — the
> blocker is no longer `LearningState`'s identity (resolved above) but a separately-
> discovered gap: their concept list still sources from `KnowledgeGraphNode`, and a
> live, mounted "manually add a concept node" route creates rows with no matching
> `ConceptOccurrence`, which would silently drop such courses' concepts from view if
> migrated today. Tenant-scoped GraphRAG remains untouched, independent, open backlog.
>
> **Addendum 3 — Category B closes except GraphRAG (2026-09-09).**
> `KnowledgeGraphService.add_knowledge_graph_node` (the manual node route's own
> service method) now dual-writes a `CanonicalConcept`/`ConceptOccurrence` for every
> concept-typed node it creates, mirroring `course_factory_worker.py`'s own pattern —
> closing the gap Addendum 2 named, going forward. Zero pre-existing un-occurrenced
> `KnowledgeGraphNode` rows were found in the dev database (no backfill needed there);
> a real deployment with production history should still run `ccv2_backfill_
> canonical_concepts.py --apply` once to close the historical half. With that gap
> closed, `ekg_student_model_service.build_course_knowledge_overview` and `ekg_
> faculty_lens_service.build_cohort_concept_mastery` are now migrated too, re-verified
> end-to-end (a concept added through the fixed route is immediately visible, with
> real mastery, in both views) plus 2 rewritten conformance suites. Of the original
> 10 real readers, only `ekg_graphrag_service.py`'s tenant-scoped GraphRAG gap remains
> open — everything else this RFC found is resolved. Retiring `seed_ekg_demo.py`'s
> old-convention writes entirely is a separate, not-yet-verified follow-up: they also
> feed the Neo4j projection the Knowledge Explorer's drill-down graph view reads.
>
> **Addendum 4 — GraphRAG lands, and closes a real cross-tenant vulnerability
> (2026-09-09).** `ekg_graphrag_service.py` needed no change — its own `entity_link`/
> `bounded_subgraph` already avoid `kg_query_service.get_graphrag_context` via a
> tenant-safe Neo4j path; migrating its identity scheme off `KnowledgeGraphNode.id`
> was checked and correctly ruled out (Neo4j has zero `CanonicalConcept`-keyed nodes
> projected — confirmed no consumer exists for the events that would create them).
> But tracing that facade's OTHER real callers — this RFC's own flagged open
> question — found the actual, live exposure: all 8 `course_id`-scoped
> `KGQueryService` methods had no tenant scoping at all, reachable via 3 live,
> mounted routes (`rag.py`, `curriculum_map.py`, `knowledge_graph.py`) with no
> course-ownership check of their own. Fixed: `tenant_id` required on all 8 methods,
> matched in Neo4j against the property their real writers already set; the 3 routes
> gained real ownership checks; a 4th file with the same gap on 7 more routes
> (`knowledge_graph_pi1.py`) turned out to be unmounted dead code, fixed anyway for
> consistency. Live-verified against real Neo4j: the same query returns real data
> for the correct tenant and zero nodes for any other. Every one of the original 10
> real readers is now resolved — nothing remains open from this RFC.

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
   service.py`) looked migratable at a glance but weren't yet, on two SEPARATE
   occasions — first a `LearningState`-keying risk (silently blanking the mastery
   overlay), then, after that was fixed, a concept-list-source risk (silently
   dropping manually-added concepts) — both caught by reading the actual write paths
   before changing code, not assumed from the RFC's own first-pass categorization.
   Both are migrated now that both real blockers are actually closed (2026-09-09).
3. **Do nothing until a full Neo4j-native replacement exists for every one of these
   use cases.** Rejected — `ekg_lens_service.py`'s fix already existed and was cheap
   (confirmed by actually doing it); deferring it alongside the genuinely harder
   Category B items would have conflated a one-file query swap with real facade/
   mastery-engine engineering work.

## 5. Open questions

- ~~Scoping the `LearningState` re-keying: does it need a one-time backfill...~~
  **Resolved (2026-09-08):** no backfill — the only real writer (`seed_ekg_demo.py`)
  now dual-writes both conventions going forward, so no historical rows needed
  translating.
- ~~Should `ConceptPrerequisite.weight` default to the same value
  `KnowledgeGraphEdge.weight`...~~ **Resolved:** the column is nullable with no
  column-level default; `resolve_concept_prerequisites_sync`'s own `row.weight or
  1.0` read-time fallback (unchanged from the old code) means an un-weighted row
  behaves identically to `KnowledgeGraphEdge.weight`'s old `default=1.0` without
  needing a matching column default.
- ~~New question, discovered while implementing the above: should `backend/api/
  routes/knowledge_graph.py`'s `POST /{course_id}/nodes` route be fixed...~~
  **Resolved (2026-09-09):** yes, done — see Addendum 3. Open sub-question: does a
  real deployment (as opposed to this empty dev database) have pre-existing
  manually-added `KnowledgeGraphNode` rows that need `ccv2_backfill_canonical_
  concepts.py --apply` run once to catch up? Not checked here — no access to that
  environment's data from this pass.
- New question, discovered while implementing the above: does anything besides
  `project_to_neo4j`'s Neo4j projection still need `seed_ekg_demo.py`'s (or any
  other writer's) `KnowledgeGraph`/`KnowledgeGraphNode` rows now that both real
  Postgres-side readers (`ekg_student_model_service.py`/`ekg_faculty_lens_
  service.py`) are migrated off them? If not, the old write path could retire
  entirely rather than staying a permanent dual-write bridge — not scoped or
  investigated as part of this pass.
- ~~Does `kg_query_service.get_graphrag_context`'s tenant-isolation gap have any
  other callers today...~~ **Resolved (2026-09-09):** yes — see Addendum 4. All 8
  `course_id`-scoped methods had the gap, reachable via 3 live routes; fixed.
- New question, discovered while implementing the above: `knowledge_graph_pi1.py`'s
  `find_assessments_without_outcomes` route needed `:Assessment` nodes to carry a
  `course_id`/`tenant_id` property to close safely — neither is ever set by the only
  real writer (`graph_sync_service_pi1.py`, confirmed by inspection). Fixed the
  route's ACCESS gate (now requires and verifies course ownership) but the
  underlying query still can't be scoped by course or tenant at all — a real,
  pre-existing data-model gap this pass found but didn't fix (would mean also
  changing that writer), disclosed in the route's own docstring. Worth a dedicated
  follow-up if this route (or its unmounted router) ever becomes load-bearing.
- Who owns scheduling the Category B/D work — same team that owns
  `canonical_concept_service.py`/`ekg_mastery_service.py` (CCV2/EKG-W2 tracks), or
  whoever picks up BOOK-13 S2 next?
