# K1 Kernel Foundation — Exit Report

**Phase:** K1 (BOOK-20 roadmap) · **Target repo:** `dlu_builder_tk`
**Executed:** 2026-07-14 → 2026-07-16 · **Sprints:** STX-01…05 (5/5 ✅)
**Execution order:** STX-01 → STX-03 (keystone) → STX-02 → STX-04 → STX-05
(pack dependency graph honored: 03 ran before 02, closing 02's outbox
coupling and the twin-sync bump hook in the same change set).

---

## 1. Exit gate assessment (pack README)

| Gate criterion | Status |
|----------------|--------|
| All sprint V-suites green | ✅ STX-01 V1–V6 · STX-02 V1–V6 · STX-03 V1–V7 · STX-04 V1–V6 · STX-05 V1–V7 |
| BOOK-20 §8.1 criterion 3 (mesh) | ✅ transactional outbox + Redis Streams + closed taxonomy live; idempotency/atomicity/trace/replay/lag verified (STX-03 V-suite) |
| Twin contract tests | ✅ `test_stx02_twin_context.py` — entitlement matrix table-test, consent degradation, cache-bust, snapshot immutability, adapter zero-regression |
| Competency contract tests | ✅ `test_stx04_competency_engine.py` — 8 golden confidence cases ≤1e-6, `verified` unreachable by formula, CASE idempotency, params immutability |
| Identity reconciliation report | ✅ `reports/stx01_identity_reconciliation.json` — 100% matched (2/2 seeded learners), 0 orphans, decision ADR-0014 Option A |

**Verdict: K1 exit gate PASSED. K2 prompts can be requested.**

---

## 2. Per-sprint delivery and verification outputs

### STX-01 — Twin Core Models + Identity Reconciliation (✅ 2026-07-14)

Delivered: `models_student_twin.py` (5 tenant tables, GUID PKs),
`models_competency_graph.py` (framework/StudentCompetency/append-only
EvidenceRecord + additive `platform.competencies` columns), migrations
`20260714_1000/1010`, `identity_map.py` (Option A: `user_guid` columns,
Celery backfill, dual-write in `mastery_tracking_service`), ADR-0014,
constitution §13.4 → decided.

Verification highlights: alembic up/down-2/up clean · backfill 100%
reconciled, 0 orphans · dual-write parallel-read parity · append-only
negative tests · V5 grep: mapping only in `identity_map` · 23 tests green.

### STX-02 — TwinContextService + /api/twin (✅ 2026-07-14, post STX-03)

Delivered: single door `twin_context_service.py` (purpose audit, BOOK-06
Ch. 6 entitlement matrix as data, consent gating w/ learner-self bypass,
version-keyed per-layer Redis cache, `bump_version(+_sync)`), immutable
`twin_snapshots` (migration `20260714_1200`) on lifecycle transitions,
`/api/twin` routes (tenant-scoped, NOT exempt), tutor adapter (zero
regression, 31/31 legacy tests), `twinAPI.js`, `consent.changed` producer.

Verification highlights: 9-agent entitlement table-test w/ audited denials ·
`ai_personalization=false` → L5/L6/L7 None + audit · cache bust on bump
(fake + live Redis, cached-read p95 < 300 ms) · staff read without purpose →
422, with purpose → audited · 23 + 54 (container) tests green.

### STX-03 — Event Mesh (keystone) (✅ 2026-07-14)

Delivered: `domain_events` outbox (migration `20260714_1100`), closed
taxonomy (41 types = constitution §7.3 + R1 + BOOK-04 Ch. 7) in
`event_taxonomy.py`, producer API `event_outbox.py` (OTel trace capture),
relay (2 s beat, ≥7-day XTRIM floor), consumer framework (5 groups,
exactly-once side effects, XAUTOCLAIM recovery, dead-letter, Prometheus
lag gauge + alert rules), twin-sync wired, producers: mastery.updated,
activity.recorded, course.* (governance workflow), EventService strangler
dual-publish. Design review: `docs/sprint_decisions_20260714_stx03.md`.

Verification highlights: rollback atomicity · duplicate + XCLAIM redelivery
→ side effect exactly once · unknown type dead-lettered loudly · producer/
consumer trace_id equality via span links (in-memory exporter) · XRANGE
replay + retention floor · lag 3→0 with gauge exported · 18 tests green.

### STX-04 — Competency Engine (✅ 2026-07-15)

Delivered: `competency_graph_service.py` (§5.3 deterministic confidence,
status machine with decay hysteresis → `expired` checkpoint, HITL-only
`verify()` per ADR-0012, `register_evidence` single writer), versioned
immutable `platform.competency_engine_params` seeded from BOOK-15 §4.1
(migration `20260715_1000`, + `framework_version` pinning per Review M1),
CASE 1.1 idempotent import + round-trip preview, daily decay beat,
`/api/competencies` routes, `competencyAPI.js`.

Verification highlights: 8 golden cases within 1e-6 (incl. one-half-life
decay, trust-class override, weighted triangulation) · `next_status` never
returns `verified` (grid property test); perfect evidence caps at
`mastered` · double-verify → 409 · CASE re-import: identical row counts,
uri preserved, version pinned "2.1" · every mutation asserted on the
outbox · params UPDATE/DELETE rejected, new version activates · 16 tests.

### STX-05 — KG v2.0 + Overlay + Ontology Registry (✅ 2026-07-16)

Delivered: idempotent `scripts/kg/v2_0_semantic_cleanup.cypher` +
`make kg-migrate` (A8 `NEEDS_ASSET`, A9 `ALIGNED_TO {strength}`,
alias window one minor release, v2.0 constraints, SchemaMeta stamp);
batched `kg-sync` overlay consumers (`kg_overlay_sync.py`: KNOWS/EVIDENCES,
DEFER-flush ≤100/pass, ack-after-flush); definition-tier Competency/
Framework sync (fire-and-forget preserved); **DLU-Core ontology registry**
(`architecture/ontology/dlu-core.yaml`) + `lint_ontology.py` in both
repos' CI; A1-S1 staging gate (`check_kg_staging_reads.sh`, legacy readers
frozen in allowlist); `frontier`/`gap` canonical queries;
`KNOWLEDGE_GRAPH_SCHEMA.md` → v2.0.

Verification highlights (live Neo4j + Redis): migration twice → identical
constraint (17) and per-type rel counts · alias parity old=new result sets ·
tenant fuzz ×10 random → empty · Neo4j down → 2xx-safe skip, reconciles on
restart · 250 events → ≤3 flushes, redelivery idempotent, failed flush
stays pending and retries · lint + gate negative tests · 11 tests green.

---

## 3. Regression evidence

- `pytest -m phase1`: **104 passed** after every sprint (stable baseline).
- Full unit suite (`-m "not integration and not slow"`): failure set
  identical to the pre-K1 baseline (16 failed in `tests/test_*` +
  18 errors + env-dependent subdirs), verified by stash-baseline
  comparison at STX-01 and re-checked per sprint. Two genuine regressions
  found and fixed during the work itself (fixture table for the outbox in
  `test_support.py`; OTel tracer-provider restore in a test fixture).
- Cumulative STX suite: **79 passed** (`test_stx01…05*`).

## 4. `git diff --stat` (implementation repo, pre-commit)

```
16 files changed, 465 insertions(+), 10 deletions(-)   (modified files)
+ 37 new files: 5 migrations, 12 backend modules, 2 API routes,
  2 frontend clients, 7 test files, KG scripts + CI gates + workflow,
  monitoring alert rules, constitution + K1 pack copies, decision note
```

Commit series (one per sprint): see `feat(das-stx0N)` commits on the
`das-k1-kernel-foundation` branch of `dlu_builder_tk`.

## 5. Register updates (this repo)

- **A-register:** A1-S1 ✅ (CI gate; S2–S4 remain per BOOK-13 Ch. 10) ·
  A2 ✅ (ADR-0014) · A6 ✅ · A8 ✅ · A9 ✅ — see TRACEABILITY.md.
- **Annexes:** BOOK-03 (mesh, tenancy identity, observability rows ✅) ·
  BOOK-04 (C4/model files row) · BOOK-05 (schema v2.0, CASE, registry) ·
  BOOK-06 (context service, L3, snapshots, anchor rows) · BOOK-13
  (engine v2.0, learner plane, sync, facade, A1-S1 rows).
- **Constitution** (`dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`):
  §4.3/§4.4/§5.3/§6/§7/§13.4 marked implemented with delivery notes.
- **ADR-0014** accepted (identity reconciliation Option A).

## 6. Residual debt / carried forward

| Item | Owner | When |
|------|-------|------|
| Alias hard-removal (`REQUIRES`, `ALIGNS_TO`, `MAPS_TO`) | KG schema v2.1 | next minor release |
| Legacy EventService retirement after dual-publish parity window | mesh | mechanical PR |
| A1 sunset S2–S4 (staging reader migration, removal) | BOOK-13 Ch. 10 | K2+ |
| A7 enrollment naming cleanup | K1 mechanical PR | pending |
| Evidence pipeline intake (`register_evidence` callers) | STX-08 | K3 |
| `UNKNOWN_TENANT` producers migrate to real tenant context | mesh | as auth propagation lands |
| Postgres-backed unit-test fixture drift (`tenants.metadata`) — pre-existing infra bug, suite runs on SQLite | test infra | independent fix |

## 7. Next

Request the **K2 Cognition pack** (STX-06 · NEW-01, 02 GA-gate, 03 —
BOOK-09/10/11/12/17). Blocking dependency honored: STX-03 outbox/consumers
are live for all kernel consumers.
